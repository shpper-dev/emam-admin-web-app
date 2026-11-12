import 'package:emam_admin_web_app/core/constants/app_constants.dart';
import 'package:emam_admin_web_app/core/router/route_paths.dart';
import 'package:emam_admin_web_app/core/widgets/filter_pill.dart';
import 'package:emam_admin_web_app/core/widgets/pill_action_button.dart';
import 'package:emam_admin_web_app/core/widgets/segmented_control.dart';
import 'package:emam_admin_web_app/features/content/views/widgets/content_section_card.dart';
import 'package:emam_admin_web_app/features/units/provider/fleet_settings_provider.dart';
import 'package:emam_admin_web_app/features/units/provider/unit_detail_providers.dart';
import 'package:emam_admin_web_app/features/units/provider/unit_recordings_provider.dart';
import 'package:emam_admin_web_app/features/units/provider/unit_releases_provider.dart';
import 'package:emam_admin_web_app/features/units/provider/units_provider.dart';
import 'package:emam_admin_web_app/features/units/views/widgets/activation_codes_section.dart';
import 'package:emam_admin_web_app/features/units/views/widgets/fleet_settings_section.dart';
import 'package:emam_admin_web_app/features/units/views/widgets/unit_detail_panel.dart';
import 'package:emam_admin_web_app/features/units/views/widgets/unit_list.dart';
import 'package:emam_admin_web_app/features/units/views/widgets/unit_recordings_section.dart';
import 'package:emam_admin_web_app/features/units/views/widgets/unit_releases_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class UnitsView extends ConsumerWidget {
  const UnitsView({super.key});

  /// From this content width the unit opens beside the list, not on its own
  /// page.
  static const sidePanelBreakpoint = 1000.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tab = ref.watch(unitsTabProvider);
    // Watched here so the list stays loaded, and polled, on every tab.
    ref.watch(unitsProvider);

    return LayoutBuilder(
      builder: (context, constraints) {
        final pad = contentHorizontalPadding(constraints.maxWidth);
        final header = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _UnitsHeader(),
            const SizedBox(height: AppConstants.space20),
            _UnitsTabs(selected: tab, wide: constraints.maxWidth >= 860),
          ],
        );

        if (tab == UnitsTab.units &&
            constraints.maxWidth >= sidePanelBreakpoint) {
          return Padding(
            padding: EdgeInsets.fromLTRB(pad, 24, pad, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                header,
                const SizedBox(height: AppConstants.space20),
                const Expanded(child: _UnitsWithSidePanel()),
              ],
            ),
          );
        }

        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(pad, 24, pad, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              header,
              const SizedBox(height: AppConstants.space20),
              switch (tab) {
                UnitsTab.units => UnitsListSection(
                  selectedId: null,
                  onSelect: (unit) =>
                      context.go(RoutePaths.unit(unit.installId)),
                ),
                UnitsTab.fleetSettings => const FleetSettingsSection(),
                UnitsTab.updates => const UnitReleasesSection(),
                UnitsTab.recordings => const UnitRecordingsSection(),
                UnitsTab.activationCodes => const ActivationCodesSection(),
              },
            ],
          ),
        );
      },
    );
  }
}

class _UnitsHeader extends ConsumerWidget {
  const _UnitsHeader();

  void _refresh(WidgetRef ref) {
    ref.read(unitsProvider.notifier).refresh();
    switch (ref.read(unitsTabProvider)) {
      case UnitsTab.units:
        // Invalidating does nothing when the unit's panel isn't open.
        final selected = ref.read(selectedUnitIdProvider);
        if (selected != null) {
          ref.invalidate(unitCommandsProvider(selected));
          ref.invalidate(unitCrashReportsProvider(selected));
        }
      case UnitsTab.fleetSettings:
        ref.invalidate(fleetSettingsProvider);
      case UnitsTab.updates:
        ref.read(unitReleasesProvider.notifier).refresh();
      case UnitsTab.recordings:
        ref.read(unitRecordingsProvider.notifier).refresh();
      case UnitsTab.activationCodes:
        break;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Units',
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: AppConstants.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'E-mam handheld units: how each one is doing, its settings '
                'and commands, app updates, recordings and activation codes.',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: AppConstants.textSecondary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppConstants.space16),
        PillActionButton(
          icon: Icons.refresh_rounded,
          label: 'Refresh',
          color: AppConstants.primary,
          onPressed: () => _refresh(ref),
        ),
      ],
    );
  }
}

class _UnitsTabs extends ConsumerWidget {
  const _UnitsTabs({required this.selected, required this.wide});

  final UnitsTab selected;
  final bool wide;

  static String label(UnitsTab tab) => switch (tab) {
    UnitsTab.units => 'Units',
    UnitsTab.fleetSettings => 'Fleet settings',
    UnitsTab.updates => 'Updates',
    UnitsTab.recordings => 'Recordings',
    UnitsTab.activationCodes => 'Activation codes',
  };

  static IconData icon(UnitsTab tab) => switch (tab) {
    UnitsTab.units => Icons.phone_android_rounded,
    UnitsTab.fleetSettings => Icons.tune_rounded,
    UnitsTab.updates => Icons.system_update_rounded,
    UnitsTab.recordings => Icons.mic_rounded,
    UnitsTab.activationCodes => Icons.key_rounded,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(unitsProvider).value?.units.length;
    final select = ref.read(unitsTabProvider.notifier).select;

    if (!wide) {
      return Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final tab in UnitsTab.values)
            FilterPill(
              label: tab == UnitsTab.units && count != null
                  ? '${label(tab)} ($count)'
                  : label(tab),
              selected: tab == selected,
              onTap: () => select(tab),
            ),
        ],
      );
    }
    return SegmentedControl<UnitsTab>(
      selected: selected,
      onChanged: select,
      options: [
        for (final tab in UnitsTab.values)
          SegmentOption(
            value: tab,
            label: label(tab),
            icon: icon(tab),
            count: tab == UnitsTab.units ? count?.toString() : null,
          ),
      ],
    );
  }
}

class _UnitsWithSidePanel extends ConsumerWidget {
  const _UnitsWithSidePanel();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedId = ref.watch(selectedUnitIdProvider);
    final select = ref.read(selectedUnitIdProvider.notifier).select;
    return LayoutBuilder(
      builder: (context, constraints) {
        final panelWidth = (constraints.maxWidth * 0.5).clamp(440.0, 640.0);
        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 32),
                child: UnitsListSection(
                  selectedId: selectedId,
                  onSelect: (unit) => select(unit.installId),
                ),
              ),
            ),
            if (selectedId != null) ...[
              const SizedBox(width: AppConstants.space20),
              SizedBox(
                width: panelWidth,
                child: SingleChildScrollView(
                  key: ValueKey(selectedId),
                  padding: const EdgeInsets.only(bottom: 32),
                  child: UnitDetailPanel(
                    key: ValueKey('panel-$selectedId'),
                    installId: selectedId,
                    onClose: () => select(null),
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}
