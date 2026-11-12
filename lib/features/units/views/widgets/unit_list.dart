import 'package:emam_admin_web_app/core/constants/app_constants.dart';
import 'package:emam_admin_web_app/core/widgets/inline_retry_error.dart';
import 'package:emam_admin_web_app/core/widgets/pill_action_button.dart';
import 'package:emam_admin_web_app/core/widgets/section_empty_message.dart';
import 'package:emam_admin_web_app/features/content/views/widgets/content_section_card.dart';
import 'package:emam_admin_web_app/features/units/models/device_unit.dart';
import 'package:emam_admin_web_app/features/units/provider/units_provider.dart';
import 'package:emam_admin_web_app/features/units/utils/unit_display.dart';
import 'package:emam_admin_web_app/features/units/views/widgets/unit_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class UnitsListSection extends ConsumerWidget {
  const UnitsListSection({
    super.key,
    required this.selectedId,
    required this.onSelect,
  });

  final String? selectedId;
  final ValueChanged<DeviceUnit> onSelect;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref
        .watch(unitsProvider)
        .when(
          skipLoadingOnReload: true,
          loading: () => const ContentSectionCard(
            title: 'Units',
            subtitle: 'Loading units…',
            icon: Icons.phone_android_rounded,
            child: SectionLoadingIndicator(),
          ),
          error: (error, _) => ContentSectionCard(
            title: 'Units',
            subtitle: 'Could not load the units',
            icon: Icons.phone_android_rounded,
            accentColor: AppConstants.danger,
            child: InlineRetryError(
              message: unitErrorMessage(error),
              onRetry: () => ref.invalidate(unitsProvider),
            ),
          ),
          data: (snapshot) => _UnitsList(
            snapshot: snapshot,
            selectedId: selectedId,
            onSelect: onSelect,
          ),
        );
  }
}

class _UnitsList extends ConsumerWidget {
  const _UnitsList({
    required this.snapshot,
    required this.selectedId,
    required this.onSelect,
  });

  final UnitsSnapshot snapshot;
  final String? selectedId;
  final ValueChanged<DeviceUnit> onSelect;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final units = snapshot.units;
    final online = units.where((unit) => unit.isOnline(now)).length;
    final refreshError = snapshot.refreshError;

    if (units.isEmpty) {
      return ContentSectionCard(
        title: 'Units',
        subtitle: 'No units yet',
        icon: Icons.phone_android_rounded,
        child: Column(
          children: [
            const SectionEmptyMessage(
              'No unit has been activated yet. Create activation codes, then '
              'enter one on a unit during its first-run setup.',
              icon: Icons.phone_android_rounded,
            ),
            PillActionButton(
              icon: Icons.key_rounded,
              label: 'Create activation codes',
              color: AppConstants.primary,
              onPressed: () => ref
                  .read(unitsTabProvider.notifier)
                  .select(UnitsTab.activationCodes),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              '${units.length == 1 ? '1 unit' : '${units.length} units'} · '
              '$online online',
              style: theme.textTheme.titleSmall,
            ),
            Text(
              'Updated ${clockTime(snapshot.fetchedAt)}. Refreshes every '
              '${UnitsNotifier.refreshEvery.inSeconds} seconds.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppConstants.textMuted,
              ),
            ),
          ],
        ),
        if (refreshError != null) ...[
          const SizedBox(height: AppConstants.space8),
          UnitNotice(
            text:
                'Could not refresh, so this is the list from '
                '${clockTime(snapshot.fetchedAt)}. $refreshError',
            icon: Icons.cloud_off_rounded,
            color: AppConstants.warning,
          ),
        ],
        const SizedBox(height: AppConstants.space12),
        for (final unit in units) ...[
          UnitCard(
            unit: unit,
            now: now,
            selected: unit.installId == selectedId,
            onTap: () => onSelect(unit),
          ),
          const SizedBox(height: AppConstants.space12),
        ],
      ],
    );
  }
}

class UnitCard extends StatelessWidget {
  const UnitCard({
    super.key,
    required this.unit,
    required this.now,
    required this.selected,
    required this.onTap,
  });

  final DeviceUnit unit;
  final DateTime now;
  final bool selected;
  final VoidCallback onTap;

  static IconData _batteryIcon(DeviceUnit unit) {
    final level = unit.battery;
    if (level == null) return Icons.battery_unknown_rounded;
    if (unit.charging) return Icons.battery_charging_full_rounded;
    return level < 20 ? Icons.battery_alert_rounded : Icons.battery_std_rounded;
  }

  static IconData _wifiIcon(DeviceUnit unit) {
    if (unit.wifiOn == false || unit.wifiSsid == null) {
      return Icons.wifi_off_rounded;
    }
    final bars = unit.wifiBars ?? kUnitWifiMaxBars;
    if (bars >= 3) return Icons.wifi_rounded;
    return bars == 2 ? Icons.wifi_2_bar_rounded : Icons.wifi_1_bar_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final online = unit.isOnline(now);
    final flags = unitFlags(unit);
    final battery = unit.battery;
    final language = unit.language;
    final details = [
      if (unit.serial != null) 'Serial ${unit.serial}',
      if (unit.model != null) unit.model!,
      if (unit.appVersion != null) 'App ${unit.appVersion}',
    ];

    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppConstants.radiusMd),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppConstants.radiusMd),
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.all(AppConstants.space16),
            decoration: BoxDecoration(
              color: selected
                  ? AppConstants.primary.withValues(alpha: 0.06)
                  : AppConstants.surfaceColor,
              borderRadius: BorderRadius.circular(AppConstants.radiusMd),
              border: Border.all(
                color: selected
                    ? AppConstants.primary.withValues(alpha: 0.6)
                    : AppConstants.borderColor,
                width: selected ? 1.4 : 1,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color:
                        (online ? AppConstants.success : AppConstants.primary)
                            .withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppConstants.radiusMd),
                  ),
                  child: Icon(
                    Icons.phone_android_rounded,
                    size: 22,
                    color: online ? AppConstants.success : AppConstants.primary,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 10,
                        runSpacing: 6,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            unit.displayName,
                            style: theme.textTheme.titleMedium,
                          ),
                          UnitBadge(
                            label: presenceLabel(unit, now),
                            color: online
                                ? AppConstants.success
                                : AppConstants.textMuted,
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        details.isEmpty
                            ? 'No details reported yet'
                            : details.join(' · '),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppConstants.textMuted,
                        ),
                      ),
                      const SizedBox(height: AppConstants.space12),
                      Wrap(
                        spacing: 18,
                        runSpacing: 6,
                        children: [
                          UnitMetaItem(
                            icon: _batteryIcon(unit),
                            text: batterySummary(unit),
                            color: battery != null && battery < 20
                                ? AppConstants.danger
                                : AppConstants.textFaint,
                          ),
                          UnitMetaItem(
                            icon: _wifiIcon(unit),
                            text: wifiSummary(unit),
                          ),
                          if (language != null)
                            UnitMetaItem(
                              icon: Icons.translate_rounded,
                              text: languageName(language),
                            ),
                        ],
                      ),
                      if (flags.isNotEmpty) ...[
                        const SizedBox(height: AppConstants.space12),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            for (final flag in flags) UnitFlagBadge(flag: flag),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: AppConstants.space8),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppConstants.textFaint,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
