import 'package:emam_admin_web_app/core/constants/app_constants.dart';
import 'package:emam_admin_web_app/core/widgets/inline_retry_error.dart';
import 'package:emam_admin_web_app/features/content/views/widgets/content_section_card.dart';
import 'package:emam_admin_web_app/features/units/models/device_unit.dart';
import 'package:emam_admin_web_app/features/units/models/unit_settings.dart';
import 'package:emam_admin_web_app/features/units/provider/fleet_settings_provider.dart';
import 'package:emam_admin_web_app/features/units/provider/units_provider.dart';
import 'package:emam_admin_web_app/features/units/utils/unit_display.dart';
import 'package:emam_admin_web_app/features/units/views/widgets/unit_settings_form.dart';
import 'package:emam_admin_web_app/features/units/views/widgets/unit_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// An edit in the unit's form; [inherit] means "use the fleet setting".
class _Draft {
  const _Draft({required this.inherit, required this.value});

  final bool inherit;
  final Object? value;
}

class UnitSettingsCard extends ConsumerStatefulWidget {
  const UnitSettingsCard({super.key, required this.unit});

  final DeviceUnit unit;

  @override
  ConsumerState<UnitSettingsCard> createState() => _UnitSettingsCardState();
}

class _UnitSettingsCardState extends ConsumerState<UnitSettingsCard> {
  final _drafts = <String, _Draft>{};
  bool _saving = false;

  _Draft _current(UnitSettingSpec spec, FleetSettings fleet) {
    final draft = _drafts[spec.key];
    if (draft != null) return draft;
    final own = widget.unit.settings[spec.key];
    return own == null
        ? _Draft(inherit: true, value: fleet.fleetValue(spec.key))
        : _Draft(inherit: false, value: own);
  }

  /// Only what differs from the unit's saved settings; null removes one.
  Map<String, Object?> get _changes => {
    for (final MapEntry(:key, value: draft) in _drafts.entries)
      if ((draft.inherit ? null : draft.value) != widget.unit.settings[key])
        key: draft.inherit ? null : draft.value,
  };

  bool _valid(FleetSettings fleet) => _drafts.entries.every(
    (entry) =>
        entry.value.inherit ||
        (fleet.spec(entry.key)?.accepts(entry.value.value) ?? false),
  );

  Future<void> _save(FleetSettings fleet) async {
    final changes = _changes;
    if (changes.isEmpty) return;
    setState(() => _saving = true);
    try {
      await ref
          .read(unitsProvider.notifier)
          .updateSettings(widget.unit.installId, changes);
      if (!mounted) return;
      setState(() {
        _drafts.clear();
        _saving = false;
      });
      showUnitToast(
        context,
        'Settings saved. ${widget.unit.displayName} picks them up at its '
        'next check-in (${checkInHint(checkInMinutes(widget.unit, fleet))}).',
        duration: const Duration(seconds: 6),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      showUnitToast(context, unitErrorMessage(error), error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final fleetAsync = ref.watch(fleetSettingsProvider);
    return ContentSectionCard(
      title: 'Settings for this unit',
      subtitle:
          'A value here overrides the fleet setting for this unit only. '
          'Tick "Use fleet setting" to follow the fleet again.',
      icon: Icons.tune_rounded,
      child: fleetAsync.when(
        skipLoadingOnReload: true,
        loading: () => const SectionLoadingIndicator(),
        error: (error, _) => InlineRetryError(
          message: unitErrorMessage(error),
          onRetry: () => ref.invalidate(fleetSettingsProvider),
        ),
        data: (fleet) => _form(fleet),
      ),
    );
  }

  Widget _form(FleetSettings fleet) {
    final specs = fleet.editable;
    if (specs.isEmpty) {
      return const Text(
        'The server lists no settings.',
        style: TextStyle(color: AppConstants.textMuted),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final spec in specs) _row(spec, fleet),
        const SizedBox(height: AppConstants.space12),
        SettingsFormActions(
          changed: _changes.isNotEmpty,
          valid: _valid(fleet),
          saving: _saving,
          onSave: () => _save(fleet),
          onDiscard: () => setState(_drafts.clear),
        ),
      ],
    );
  }

  Widget _row(UnitSettingSpec spec, FleetSettings fleet) {
    final current = _current(spec, fleet);
    final fleetValue = fleet.fleetValue(spec.key);
    return SettingRow(
      spec: spec,
      control: SettingControl(
        spec: spec,
        value: current.inherit ? fleetValue : current.value,
        enabled: !current.inherit && !_saving,
        onChanged: (value) => setState(
          () => _drafts[spec.key] = _Draft(inherit: false, value: value),
        ),
      ),
      trailing: UseFleetSettingBox(
        checked: current.inherit,
        fleetValue: settingValueLabel(spec, fleetValue),
        enabled: !_saving,
        onChanged: (inherit) => setState(
          () => _drafts[spec.key] = _Draft(
            inherit: inherit,
            value: inherit
                ? fleetValue
                : widget.unit.settings[spec.key] ?? fleetValue,
          ),
        ),
      ),
    );
  }
}
