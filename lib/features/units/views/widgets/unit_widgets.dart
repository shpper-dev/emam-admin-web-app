import 'dart:math' as math;

import 'package:dio/dio.dart';
import 'package:emam_admin_web_app/core/constants/app_constants.dart';
import 'package:emam_admin_web_app/core/network/api_error.dart';
import 'package:emam_admin_web_app/core/widgets/admin_alert_dialog.dart';
import 'package:emam_admin_web_app/core/widgets/dialog_submit_button.dart';
import 'package:emam_admin_web_app/core/widgets/status_badge.dart';
import 'package:emam_admin_web_app/features/units/utils/unit_display.dart';
import 'package:flutter/material.dart';

String unitErrorMessage(Object error) => error is DioException
    ? parseApiError(error)
    : 'Something went wrong. Please try again.';

void showUnitToast(
  BuildContext context,
  String message, {
  bool error = false,
  Duration duration = const Duration(seconds: 4),
}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message),
        duration: duration,
        backgroundColor: error ? AppConstants.danger : null,
      ),
    );
}

Future<bool> confirmUnitAction(
  BuildContext context, {
  required String title,
  required String body,
  required String action,
  required IconData icon,
  Color color = AppConstants.warning,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AdminAlertDialog(
      title: title,
      icon: icon,
      accentColor: color,
      contentWidth: 420,
      content: Text(
        body,
        style: Theme.of(
          dialogContext,
        ).textTheme.bodyMedium?.copyWith(color: AppConstants.textSecondary),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text('Cancel'),
        ),
        DialogSubmitButton(
          label: action,
          color: color,
          enabled: true,
          isSubmitting: false,
          onPressed: () => Navigator.of(dialogContext).pop(true),
        ),
      ],
    ),
  );
  return confirmed == true;
}

/// Same look as the moderation dialogs' reason field.
InputDecoration unitInputDecoration(
  String label, {
  String? hint,
  String? helper,
  String? error,
  Widget? suffix,
}) {
  OutlineInputBorder border(Color color, [double width = 1]) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppConstants.radiusMd),
        borderSide: BorderSide(color: color, width: width),
      );
  return InputDecoration(
    labelText: label,
    hintText: hint,
    helperText: helper,
    helperMaxLines: 3,
    errorText: error,
    suffixIcon: suffix,
    labelStyle: const TextStyle(color: AppConstants.textSecondary),
    filled: true,
    fillColor: AppConstants.inputFillColor,
    border: border(AppConstants.borderColorStrong),
    enabledBorder: border(AppConstants.borderColorStrong),
    disabledBorder: border(AppConstants.borderColor),
    focusedBorder: border(AppConstants.primary, 1.5),
  );
}

/// [StatusBadge]'s look, but a long label is cut short instead of
/// overflowing a narrow screen.
class UnitBadge extends StatelessWidget {
  const UnitBadge({super.key, required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AppConstants.radiusPill),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class UnitFlagBadge extends StatelessWidget {
  const UnitFlagBadge({super.key, required this.flag});

  final UnitFlag flag;

  @override
  Widget build(BuildContext context) {
    final tooltip =
        flag.tooltip ?? (flag.label.length > 24 ? flag.label : null);
    final badge = UnitBadge(label: flag.label, color: flag.color);
    return tooltip == null ? badge : Tooltip(message: tooltip, child: badge);
  }
}

class UnitMetaItem extends StatelessWidget {
  const UnitMetaItem({
    super.key,
    required this.icon,
    required this.text,
    this.color = AppConstants.textFaint,
  });

  final IconData icon;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppConstants.textSecondary),
          ),
        ),
      ],
    );
  }
}

/// Lays [children] out in as many equal columns as fit [minTileWidth].
class UnitDetailGrid extends StatelessWidget {
  const UnitDetailGrid({
    super.key,
    required this.children,
    this.minTileWidth = 180,
  });

  final List<Widget> children;
  final double minTileWidth;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 12.0;
        final columns = math.max(
          1,
          ((constraints.maxWidth + spacing) / (minTileWidth + spacing)).floor(),
        );
        final tileWidth =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final child in children)
              SizedBox(width: tileWidth, child: child),
          ],
        );
      },
    );
  }
}

class UnitGroupLabel extends StatelessWidget {
  const UnitGroupLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
        color: AppConstants.textSecondary,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.1,
      ),
    );
  }
}

/// A tinted note inside a card, e.g. a warning that codes are shown once.
class UnitNotice extends StatelessWidget {
  const UnitNotice({
    super.key,
    required this.text,
    this.icon = Icons.info_outline_rounded,
    this.color = AppConstants.info,
  });

  final String text;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppConstants.radiusSm),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppConstants.textPrimary.withValues(alpha: 0.9),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
