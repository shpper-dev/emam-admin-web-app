import 'package:emam_admin_web_app/core/constants/app_constants.dart';
import 'package:emam_admin_web_app/features/units/models/unit_settings.dart';
import 'package:emam_admin_web_app/features/units/utils/unit_display.dart';
import 'package:emam_admin_web_app/features/units/views/widgets/unit_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// The input for one schema setting: a dropdown, a switch or a number field.
class SettingControl extends StatelessWidget {
  const SettingControl({
    super.key,
    required this.spec,
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  final UnitSettingSpec spec;
  final Object? value;
  final bool enabled;
  final ValueChanged<Object?> onChanged;

  @override
  Widget build(BuildContext context) {
    switch (spec.type) {
      case UnitSettingType.choice:
        final current = value is String && spec.choices.contains(value)
            ? value as String
            : null;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: AppConstants.inputFillColor,
            borderRadius: BorderRadius.circular(AppConstants.radiusMd),
            border: Border.all(
              color: enabled
                  ? AppConstants.borderColorStrong
                  : AppConstants.borderColor,
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: current,
              isExpanded: true,
              dropdownColor: AppConstants.surfaceElevated,
              borderRadius: BorderRadius.circular(AppConstants.radiusMd),
              disabledHint: current == null ? null : Text(choiceLabel(current)),
              items: [
                for (final choice in spec.choices)
                  DropdownMenuItem(
                    value: choice,
                    child: Text(choiceLabel(choice)),
                  ),
              ],
              onChanged: enabled
                  ? (choice) {
                      if (choice != null) onChanged(choice);
                    }
                  : null,
            ),
          ),
        );
      case UnitSettingType.boolean:
        return Align(
          alignment: Alignment.centerLeft,
          child: Switch(
            value: value == true,
            onChanged: enabled ? onChanged : null,
          ),
        );
      case UnitSettingType.integer:
        return _NumberField(
          spec: spec,
          value: value is int ? value as int : null,
          enabled: enabled,
          onChanged: onChanged,
        );
      case UnitSettingType.unknown:
        return Text(value?.toString() ?? 'Not set');
    }
  }
}

class _NumberField extends StatefulWidget {
  const _NumberField({
    required this.spec,
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  final UnitSettingSpec spec;
  final int? value;
  final bool enabled;
  final ValueChanged<Object?> onChanged;

  @override
  State<_NumberField> createState() => _NumberFieldState();
}

class _NumberFieldState extends State<_NumberField> {
  late final _controller = TextEditingController(
    text: widget.value?.toString() ?? '',
  );

  @override
  void didUpdateWidget(_NumberField oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Follow changes from outside (a reset or "use fleet setting"), but not
    // the half-typed number this field reported itself.
    final typed = int.tryParse(_controller.text);
    if (widget.value != null && widget.value != typed) {
      _controller.text = widget.value.toString();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final spec = widget.spec;
    final typed = int.tryParse(_controller.text);
    final range = spec.min != null && spec.max != null
        ? '${spec.min} to ${spec.max}'
        : null;
    final invalid = widget.enabled && !spec.accepts(typed);
    return TextField(
      controller: _controller,
      enabled: widget.enabled,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      style: const TextStyle(color: AppConstants.textPrimary),
      cursorColor: AppConstants.primary,
      decoration: unitInputDecoration(
        'Value',
        error: invalid ? 'Enter ${range ?? 'a valid number'}' : null,
        helper: invalid || range == null ? null : range,
      ),
      onChanged: (text) => widget.onChanged(int.tryParse(text)),
    );
  }
}

/// A labelled setting with its help text, used by the fleet and unit forms.
class SettingRow extends StatelessWidget {
  const SettingRow({
    super.key,
    required this.spec,
    required this.control,
    this.note,
    this.trailing,
  });

  final UnitSettingSpec spec;
  final Widget control;
  final String? note;

  /// Sits next to the control, e.g. the "Use fleet setting" box.
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppConstants.space12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(spec.label, style: theme.textTheme.titleSmall),
          if (spec.help.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              spec.help,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppConstants.textMuted,
              ),
            ),
          ],
          if (note != null) ...[
            const SizedBox(height: 4),
            Text(
              note!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppConstants.textFaint,
              ),
            ),
          ],
          const SizedBox(height: AppConstants.space12),
          Wrap(
            spacing: AppConstants.space16,
            runSpacing: AppConstants.space8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(width: 240, child: control),
              ?trailing,
            ],
          ),
        ],
      ),
    );
  }
}

/// "Use fleet setting" for one unit's form: ticked means no value of its own.
class UseFleetSettingBox extends StatelessWidget {
  const UseFleetSettingBox({
    super.key,
    required this.checked,
    required this.fleetValue,
    required this.enabled,
    required this.onChanged,
  });

  final bool checked;
  final String fleetValue;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppConstants.radiusSm),
      onTap: enabled ? () => onChanged(!checked) : null,
      child: Padding(
        padding: const EdgeInsets.only(right: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Checkbox(
              value: checked,
              onChanged: enabled ? (value) => onChanged(value ?? false) : null,
            ),
            Flexible(
              child: Text(
                'Use fleet setting ($fleetValue)',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppConstants.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Save and discard buttons under a settings form.
class SettingsFormActions extends StatelessWidget {
  const SettingsFormActions({
    super.key,
    required this.changed,
    required this.valid,
    required this.saving,
    required this.onSave,
    required this.onDiscard,
    this.saveLabel = 'Save settings',
  });

  final bool changed;
  final bool valid;
  final bool saving;
  final VoidCallback onSave;
  final VoidCallback onDiscard;
  final String saveLabel;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppConstants.space12,
      runSpacing: AppConstants.space12,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        FilledButton.icon(
          onPressed: changed && valid && !saving ? onSave : null,
          icon: saving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.save_rounded, size: 18),
          label: Text(saveLabel),
          style: FilledButton.styleFrom(
            backgroundColor: AppConstants.primary,
            foregroundColor: AppConstants.black,
          ),
        ),
        if (changed)
          TextButton(
            onPressed: saving ? null : onDiscard,
            child: const Text('Discard changes'),
          ),
        if (changed && !valid)
          Text(
            'Fix the values marked in red first.',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppConstants.danger),
          ),
      ],
    );
  }
}
