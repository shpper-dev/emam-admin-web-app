import 'package:dio/dio.dart';
import 'package:emam_admin_web_app/core/constants/app_constants.dart';
import 'package:emam_admin_web_app/core/network/api_error.dart';
import 'package:emam_admin_web_app/core/widgets/inline_retry_error.dart';
import 'package:emam_admin_web_app/core/widgets/skeleton.dart';
import 'package:emam_admin_web_app/features/cms/models/ramadan_settings.dart';
import 'package:emam_admin_web_app/features/cms/models/staff_session.dart';
import 'package:emam_admin_web_app/features/cms/provider/cms_provider.dart';
import 'package:emam_admin_web_app/features/cms/provider/cms_repository_provider.dart';
import 'package:emam_admin_web_app/features/cms/views/widgets/cms_common.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class RamadanTab extends ConsumerWidget {
  const RamadanTab({super.key, required this.staff});
  final StaffSession staff;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref
        .watch(ramadanSettingsProvider)
        .when(
          loading: () => const SkeletonList(rows: 4),
          error: (e, _) => InlineRetryError(
            message: e is DioException
                ? parseApiError(e)
                : 'Could not load settings.',
            onRetry: () => ref.invalidate(ramadanSettingsProvider),
          ),
          data: (s) => _RamadanForm(settings: s, editable: staff.canEdit),
        );
  }
}

class _RamadanForm extends ConsumerStatefulWidget {
  const _RamadanForm({required this.settings, required this.editable});
  final RamadanSettings settings;
  final bool editable;

  @override
  ConsumerState<_RamadanForm> createState() => _RamadanFormState();
}

class _RamadanFormState extends ConsumerState<_RamadanForm> {
  late bool _enabled = widget.settings.enabled;
  late final _year = TextEditingController(
    text: widget.settings.hijriYear?.toString() ?? '',
  );
  late final _title = TextEditingController(text: widget.settings.bannerTitle);
  late final _body = TextEditingController(text: widget.settings.bannerBody);
  late final _slugs = TextEditingController(
    text: widget.settings.featuredSlugs.join(', '),
  );
  late final Map<String, bool> _modules = {...widget.settings.modules};
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _year.dispose();
    _title.dispose();
    _body.dispose();
    _slugs.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    final year = int.tryParse(_year.text.trim());
    if (year == null || year < 1400 || year > 1600) {
      return setState(() => _error = 'Enter a valid Hijri year, e.g. 1447.');
    }
    final slugs = [
      for (final s in _slugs.text.split(','))
        if (s.trim().isNotEmpty) s.trim(),
    ];
    if (slugs.any((s) => !CmsLimits.slug.hasMatch(s)) || slugs.length > 20) {
      return setState(() => _error = 'Featured slugs: up to 20 valid slugs.');
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    final ok = await cmsRun(
      context,
      () => ref.read(cmsRepositoryProvider).patchRamadan({
        'enabled': _enabled,
        'hijri_year': year,
        'home_banner_title': _title.text.trim(),
        'home_banner_body': _body.text.trim(),
        'featured_article_slugs': slugs,
        'modules': _modules,
      }),
      success: 'Ramadan settings saved.',
    );
    if (!mounted) return;
    setState(() => _saving = false);
    if (ok) ref.invalidate(ramadanSettingsProvider);
  }

  @override
  Widget build(BuildContext context) {
    final on = widget.editable && !_saving;
    return Container(
      padding: const EdgeInsets.all(AppConstants.space16),
      decoration: BoxDecoration(
        color: AppConstants.surfaceColor,
        borderRadius: BorderRadius.circular(AppConstants.radiusMd),
        border: Border.all(color: AppConstants.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Ramadan mode enabled'),
            value: _enabled,
            onChanged: on ? (v) => setState(() => _enabled = v) : null,
          ),
          const SizedBox(height: AppConstants.space8),
          cmsField(_year, 'Hijri year', maxLength: 4, enabled: on),
          cmsField(
            _title,
            'Home banner title',
            maxLength: CmsLimits.titleMax,
            enabled: on,
          ),
          cmsField(
            _body,
            'Home banner body',
            maxLength: CmsLimits.summaryMax,
            maxLines: 3,
            enabled: on,
          ),
          cmsField(
            _slugs,
            'Featured article slugs (comma separated)',
            enabled: on,
          ),
          for (final e in _modules.entries)
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              title: Text(e.key.replaceAll('_', ' ')),
              value: e.value,
              onChanged: on ? (v) => setState(() => _modules[e.key] = v) : null,
            ),
          if (_error != null) ...[
            const SizedBox(height: AppConstants.space8),
            Text(_error!, style: const TextStyle(color: AppConstants.danger)),
          ],
          if (widget.editable) ...[
            const SizedBox(height: AppConstants.space16),
            FilledButton(
              onPressed: _saving ? null : _save,
              style: FilledButton.styleFrom(
                backgroundColor: AppConstants.primary,
                foregroundColor: AppConstants.black,
              ),
              child: Text(_saving ? 'Saving…' : 'Save settings'),
            ),
          ] else
            const Padding(
              padding: EdgeInsets.only(top: AppConstants.space8),
              child: Text(
                'Read only: editors and admins can change these.',
                style: TextStyle(color: AppConstants.textMuted),
              ),
            ),
        ],
      ),
    );
  }
}
