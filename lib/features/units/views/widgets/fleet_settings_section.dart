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

class FleetSettingsSection extends ConsumerStatefulWidget {
  const FleetSettingsSection({super.key});

  @override
  ConsumerState<FleetSettingsSection> createState() =>
      _FleetSettingsSectionState();
}

class _FleetSettingsSectionState extends ConsumerState<FleetSettingsSection> {
  final _drafts = <String, Object?>{};
  bool _saving = false;

  Map<String, Object?> _changes(FleetSettings fleet) => {
    for (final MapEntry(:key, :value) in _drafts.entries)
      if (value != fleet.fleetValue(key)) key: value,
  };

  bool _valid(FleetSettings fleet) => _drafts.entries.every(
    (entry) => fleet.spec(entry.key)?.accepts(entry.value) ?? false,
  );

  Future<void> _save(FleetSettings fleet) async {
    final changes = _changes(fleet);
    if (changes.isEmpty) return;
    setState(() => _saving = true);
    try {
      await ref.read(fleetSettingsProvider.notifier).save(changes);
      if (!mounted) return;
      setState(() {
        _drafts.clear();
        _saving = false;
      });
      showUnitToast(
        context,
        'Fleet settings saved. Units pick them up at their next check-in.',
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
    final units = ref.watch(unitsProvider).value?.units;
    return ContentSectionCard(
      title: 'Fleet settings',
      subtitle:
          'These apply to every unit. A unit\'s own setting, set on its page, '
          'overrides the fleet one.',
      icon: Icons.tune_rounded,
      child: fleetAsync.when(
        skipLoadingOnReload: true,
        loading: () => const SectionLoadingIndicator(),
        error: (error, _) => InlineRetryError(
          message: unitErrorMessage(error),
          onRetry: () => ref.invalidate(fleetSettingsProvider),
        ),
        data: (fleet) => _form(fleet, units),
      ),
    );
  }

  Widget _form(FleetSettings fleet, List<DeviceUnit>? units) {
    final specs = fleet.editable;
    if (specs.isEmpty) {
      return const Text(
        'The server lists no settings.',
        style: TextStyle(color: AppConstants.textMuted),
      );
    }
    final changes = _changes(fleet);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final spec in specs)
          SettingRow(
            spec: spec,
            note: _note(spec, units),
            control: SettingControl(
              spec: spec,
              value: _drafts.containsKey(spec.key)
                  ? _drafts[spec.key]
                  : fleet.fleetValue(spec.key),
              enabled: !_saving,
              onChanged: (value) => setState(() => _drafts[spec.key] = value),
            ),
          ),
        const SizedBox(height: AppConstants.space12),
        SettingsFormActions(
          changed: changes.isNotEmpty,
          valid: _valid(fleet),
          saving: _saving,
          saveLabel: 'Save fleet settings',
          onSave: () => _save(fleet),
          onDiscard: () => setState(_drafts.clear),
        ),
      ],
    );
  }

  static String _note(UnitSettingSpec spec, List<DeviceUnit>? units) {
    final defaultText =
        'Built-in default: ${settingValueLabel(spec, spec.defaultValue)}.';
    if (units == null) return defaultText;
    final overrides = units
        .where((unit) => unit.settings[spec.key] != null)
        .length;
    if (overrides == 0) return defaultText;
    return overrides == 1
        ? '$defaultText 1 unit has its own value.'
        : '$defaultText $overrides units have their own value.';
  }
}
