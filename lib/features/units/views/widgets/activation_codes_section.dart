import 'package:emam_admin_web_app/core/constants/app_constants.dart';
import 'package:emam_admin_web_app/core/widgets/dialog_error_text.dart';
import 'package:emam_admin_web_app/core/widgets/pill_action_button.dart';
import 'package:emam_admin_web_app/features/content/views/widgets/content_section_card.dart';
import 'package:emam_admin_web_app/features/units/provider/activation_codes_provider.dart';
import 'package:emam_admin_web_app/features/units/views/widgets/unit_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ActivationCodesSection extends ConsumerWidget {
  const ActivationCodesSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final issued = ref.watch(activationCodesProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (issued != null) ...[
          _IssuedCodesCard(issued: issued),
          const SizedBox(height: AppConstants.space16),
        ],
        const _CreateCodesCard(),
      ],
    );
  }
}

class _CreateCodesCard extends ConsumerStatefulWidget {
  const _CreateCodesCard();

  @override
  ConsumerState<_CreateCodesCard> createState() => _CreateCodesCardState();
}

class _CreateCodesCardState extends ConsumerState<_CreateCodesCard> {
  final _count = TextEditingController(text: '1');
  final _label = TextEditingController();
  bool _creating = false;
  String? _error;

  int? get _countValue {
    final value = int.tryParse(_count.text);
    return value != null && value >= 1 && value <= 50 ? value : null;
  }

  @override
  void dispose() {
    _count.dispose();
    _label.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    final count = _countValue;
    if (count == null || _creating) return;
    setState(() {
      _creating = true;
      _error = null;
    });
    try {
      await ref
          .read(activationCodesProvider.notifier)
          .create(count: count, label: _label.text);
      if (!mounted) return;
      setState(() {
        _creating = false;
        _count.text = '1';
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _creating = false;
        _error = unitErrorMessage(error);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final countInvalid = _count.text.isNotEmpty && _countValue == null;
    final countField = TextField(
      controller: _count,
      enabled: !_creating,
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(2),
      ],
      style: const TextStyle(color: AppConstants.textPrimary),
      cursorColor: AppConstants.primary,
      decoration: unitInputDecoration(
        'Number of codes',
        helper: countInvalid ? null : '1 to 50',
        error: countInvalid ? 'Enter 1 to 50' : null,
      ),
      onChanged: (_) => setState(() {}),
    );
    final labelField = TextField(
      controller: _label,
      enabled: !_creating,
      maxLength: 80,
      style: const TextStyle(color: AppConstants.textPrimary),
      cursorColor: AppConstants.primary,
      decoration: unitInputDecoration(
        'Label (optional)',
        hint: 'e.g. JWD batch 2',
        helper: 'Saved with each unit activated by one of these codes.',
      ),
      onSubmitted: (_) => _create(),
    );

    return ContentSectionCard(
      title: 'Create activation codes',
      subtitle:
          'Each code activates one unit, once. Enter it on the unit during '
          'its first-run setup.',
      icon: Icons.key_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 480) {
                return Column(
                  children: [
                    countField,
                    const SizedBox(height: AppConstants.space16),
                    labelField,
                  ],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(width: 180, child: countField),
                  const SizedBox(width: AppConstants.space16),
                  Expanded(child: labelField),
                ],
              );
            },
          ),
          if (_error != null) ...[
            const SizedBox(height: AppConstants.space8),
            DialogErrorText(_error!),
          ],
          const SizedBox(height: AppConstants.space16),
          FilledButton.icon(
            onPressed: _countValue != null && !_creating ? _create : null,
            icon: _creating
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.add_rounded, size: 18),
            label: Text(
              _countValue == null || _countValue == 1
                  ? 'Create code'
                  : 'Create $_countValue codes',
            ),
            style: FilledButton.styleFrom(
              backgroundColor: AppConstants.primary,
              foregroundColor: AppConstants.black,
            ),
          ),
        ],
      ),
    );
  }
}

class _IssuedCodesCard extends ConsumerWidget {
  const _IssuedCodesCard({required this.issued});

  final IssuedCodes issued;

  void _copy(BuildContext context, String text, String done) {
    Clipboard.setData(ClipboardData(text: text));
    showUnitToast(context, done);
  }

  Future<void> _hide(BuildContext context, WidgetRef ref) async {
    final confirmed = await confirmUnitAction(
      context,
      title: 'Hide these codes?',
      body:
          'They can\'t be shown again, here or anywhere else. Make sure you '
          'have copied them.',
      action: 'Hide codes',
      icon: Icons.visibility_off_rounded,
    );
    if (confirmed && context.mounted) {
      ref.read(activationCodesProvider.notifier).dismiss();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final codes = issued.codes;
    final count = codes.length == 1
        ? '1 new code'
        : '${codes.length} new codes';
    return ContentSectionCard(
      title: 'New activation codes',
      subtitle: issued.label.isEmpty
          ? count
          : '$count, labelled "${issued.label}"',
      icon: Icons.key_rounded,
      accentColor: AppConstants.warning,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const UnitNotice(
            text:
                'Copy these codes now. They are shown only once and will not '
                'be shown again.',
            icon: Icons.warning_amber_rounded,
            color: AppConstants.warning,
          ),
          const SizedBox(height: AppConstants.space12),
          for (final code in codes)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  Expanded(
                    child: SelectableText(
                      code,
                      style: theme.textTheme.titleMedium?.copyWith(
                        letterSpacing: 1.2,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Copy $code',
                    onPressed: () => _copy(context, code, 'Code copied.'),
                    icon: const Icon(Icons.copy_rounded, size: 18),
                  ),
                ],
              ),
            ),
          const SizedBox(height: AppConstants.space12),
          Wrap(
            spacing: AppConstants.space8,
            runSpacing: AppConstants.space8,
            children: [
              if (codes.length > 1)
                PillActionButton(
                  icon: Icons.copy_all_rounded,
                  label: 'Copy all codes',
                  color: AppConstants.primary,
                  onPressed: () => _copy(
                    context,
                    codes.join('\n'),
                    'All ${codes.length} codes copied.',
                  ),
                ),
              PillActionButton(
                icon: Icons.visibility_off_rounded,
                label: 'Hide codes',
                color: AppConstants.textSecondary,
                onPressed: () => _hide(context, ref),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
