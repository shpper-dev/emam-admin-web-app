import 'package:emam_admin_web_app/core/constants/app_constants.dart';
import 'package:emam_admin_web_app/core/utils/formatters.dart';
import 'package:emam_admin_web_app/core/widgets/admin_alert_dialog.dart';
import 'package:emam_admin_web_app/core/widgets/dialog_error_text.dart';
import 'package:emam_admin_web_app/core/widgets/dialog_submit_button.dart';
import 'package:emam_admin_web_app/core/widgets/inline_retry_error.dart';
import 'package:emam_admin_web_app/core/widgets/pill_action_button.dart';
import 'package:emam_admin_web_app/core/widgets/section_empty_message.dart';
import 'package:emam_admin_web_app/features/content/views/widgets/content_section_card.dart';
import 'package:emam_admin_web_app/features/units/models/device_unit.dart';
import 'package:emam_admin_web_app/features/units/models/unit_release.dart';
import 'package:emam_admin_web_app/features/units/provider/unit_releases_provider.dart';
import 'package:emam_admin_web_app/features/units/provider/units_provider.dart';
import 'package:emam_admin_web_app/features/units/repository/units_repository.dart';
import 'package:emam_admin_web_app/features/units/utils/browser_files.dart';
import 'package:emam_admin_web_app/features/units/utils/unit_display.dart';
import 'package:emam_admin_web_app/features/units/views/widgets/unit_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class UnitReleasesSection extends StatelessWidget {
  const UnitReleasesSection({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _UploadCard(),
        SizedBox(height: AppConstants.space16),
        _ReleasesCard(),
      ],
    );
  }
}

class _UploadCard extends ConsumerStatefulWidget {
  const _UploadCard();

  @override
  ConsumerState<_UploadCard> createState() => _UploadCardState();
}

class _UploadCardState extends ConsumerState<_UploadCard> {
  // The server's limit.
  static const _maxBytes = 60 * 1024 * 1024;

  final _notes = TextEditingController();
  PickedFile? _file;
  bool _uploading = false;
  double? _progress;
  String? _error;

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  Future<void> _choose() async {
    final PickedFile? file;
    try {
      file = await pickFile(accept: '.apk,${UnitsRepository.apkContentType}');
    } catch (_) {
      if (mounted) setState(() => _error = 'Could not read that file.');
      return;
    }
    if (file == null || !mounted) return;
    final error = !file.name.toLowerCase().endsWith('.apk')
        ? 'Choose an .apk file.'
        : file.bytes.length > _maxBytes
        ? 'This APK is ${formatFileSize(file.bytes.length)}; the server takes '
              'up to 60 MB.'
        : null;
    setState(() {
      _error = error;
      _file = error == null ? file : null;
    });
  }

  Future<void> _upload() async {
    final file = _file;
    if (file == null) return;
    setState(() {
      _uploading = true;
      _progress = 0;
      _error = null;
    });
    try {
      final release = await ref
          .read(unitReleasesProvider.notifier)
          .upload(
            file.bytes,
            notes: _notes.text,
            onProgress: (sent, total) {
              if (mounted && total > 0) {
                setState(() => _progress = sent / total);
              }
            },
          );
      if (!mounted) return;
      setState(() {
        _file = null;
        _notes.clear();
        _uploading = false;
        _progress = null;
      });
      showUnitToast(
        context,
        'Version ${release.versionName} (${release.versionCode}) uploaded. '
        'Units get it once you publish it.',
      );
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _uploading = false;
        _progress = null;
        _error = unitErrorMessage(error);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final file = _file;
    final progress = _progress;
    return ContentSectionCard(
      title: 'Upload an update',
      subtitle:
          'A signed release APK of the E-mam unit app. The server reads its '
          'version from the file.',
      icon: Icons.upload_file_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: AppConstants.space12,
            runSpacing: AppConstants.space8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              PillActionButton(
                icon: Icons.folder_open_rounded,
                label: file == null ? 'Choose APK file' : 'Choose another file',
                color: AppConstants.primary,
                onPressed: _uploading ? null : _choose,
              ),
              Text(
                file == null
                    ? 'No file chosen'
                    : '${file.name} · ${formatFileSize(file.bytes.length)}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: file == null
                      ? AppConstants.textMuted
                      : AppConstants.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.space16),
          TextField(
            controller: _notes,
            enabled: !_uploading,
            maxLines: 3,
            maxLength: 500,
            style: const TextStyle(color: AppConstants.textPrimary),
            cursorColor: AppConstants.primary,
            decoration: unitInputDecoration(
              'Release notes (optional)',
              hint: 'What changed in this version',
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: AppConstants.space8),
            DialogErrorText(_error!),
          ],
          if (_uploading) ...[
            const SizedBox(height: AppConstants.space12),
            LinearProgressIndicator(
              value: progress == null || progress >= 1 ? null : progress,
            ),
            const SizedBox(height: AppConstants.space8),
            Text(
              progress == null || progress >= 1
                  ? 'Checking the APK on the server…'
                  : 'Uploading ${(progress * 100).round()}%',
              style: theme.textTheme.bodySmall,
            ),
          ],
          const SizedBox(height: AppConstants.space16),
          FilledButton.icon(
            onPressed: file != null && !_uploading ? _upload : null,
            icon: const Icon(Icons.cloud_upload_rounded, size: 18),
            label: const Text('Upload APK'),
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

class _ReleasesCard extends ConsumerWidget {
  const _ReleasesCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final units = ref.watch(unitsProvider).value?.units ?? const [];
    return ContentSectionCard(
      title: 'Releases',
      subtitle:
          'Newest version first. Units on an older version install a '
          'published update between sessions.',
      icon: Icons.system_update_rounded,
      child: ref
          .watch(unitReleasesProvider)
          .when(
            skipLoadingOnReload: true,
            loading: () => const SectionLoadingIndicator(),
            error: (error, _) => InlineRetryError(
              message: unitErrorMessage(error),
              onRetry: () => ref.invalidate(unitReleasesProvider),
            ),
            data: (releases) => releases.isEmpty
                ? const SectionEmptyMessage(
                    'No updates uploaded yet.',
                    icon: Icons.system_update_rounded,
                  )
                : Column(
                    children: [
                      for (final release in releases)
                        _ReleaseTile(release: release, units: units),
                    ],
                  ),
          ),
    );
  }
}

class _ReleaseTile extends ConsumerStatefulWidget {
  const _ReleaseTile({required this.release, required this.units});

  final UnitRelease release;
  final List<DeviceUnit> units;

  @override
  ConsumerState<_ReleaseTile> createState() => _ReleaseTileState();
}

class _ReleaseTileState extends ConsumerState<_ReleaseTile> {
  bool _busy = false;

  UnitRelease get _release => widget.release;

  String get _version => 'version ${_release.versionName}';

  Future<void> _run(
    Future<void> Function(UnitReleasesNotifier notifier) action,
    String done,
  ) async {
    setState(() => _busy = true);
    try {
      await action(ref.read(unitReleasesProvider.notifier));
      if (mounted) showUnitToast(context, done);
    } catch (error) {
      if (mounted) showUnitToast(context, unitErrorMessage(error), error: true);
    }
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _publishToAll() async {
    final confirmed = await confirmUnitAction(
      context,
      title: 'Publish $_version to all units?',
      body:
          'Every unit on an older version installs it between sessions, '
          'after its next check-in. Units with automatic updates off wait '
          'for "Check for update".',
      action: 'Publish to all units',
      icon: Icons.public_rounded,
      color: AppConstants.success,
    );
    if (!confirmed || !mounted) return;
    await _run(
      (notifier) => notifier.publish(_release.versionCode),
      'Published $_version to all units.',
    );
  }

  Future<void> _publishToSelected() async {
    final ids = await showDialog<List<String>>(
      context: context,
      builder: (_) => _PublishToUnitsDialog(
        version: _release.versionName,
        units: widget.units,
        initial: _release.targetsAll ? const [] : _release.targetUnits,
      ),
    );
    if (ids == null || ids.isEmpty || !mounted) return;
    await _run(
      (notifier) => notifier.publish(_release.versionCode, unitIds: ids),
      'Published $_version to '
      '${ids.length == 1 ? '1 unit' : '${ids.length} units'}.',
    );
  }

  Future<void> _unpublish() => _run(
    (notifier) => notifier.unpublish(_release.versionCode),
    'Unpublished $_version. Units that haven\'t installed it won\'t get it.',
  );

  Future<void> _delete() async {
    final confirmed = await confirmUnitAction(
      context,
      title: 'Delete $_version?',
      body:
          'The APK is removed from the server. This can\'t be undone, but you '
          'can upload the file again.',
      action: 'Delete version',
      icon: Icons.delete_outline_rounded,
      color: AppConstants.danger,
    );
    if (!confirmed || !mounted) return;
    await _run(
      (notifier) => notifier.delete(_release.versionCode),
      'Deleted $_version.',
    );
  }

  String _targetText() {
    if (_release.targetsAll) return 'All units';
    final names = [
      for (final id in _release.targetUnits)
        _unitName(id, widget.units) ?? shortId(id),
    ];
    return names.join(', ');
  }

  static String? _unitName(String id, List<DeviceUnit> units) {
    for (final unit in units) {
      if (unit.installId == id) return unit.displayName;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final release = _release;
    final now = DateTime.now();
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: AppConstants.textMuted,
    );
    final status = !release.published
        ? ('Not published', AppConstants.textMuted)
        : release.targetsAll
        ? ('Published to all units', AppConstants.success)
        : (
            release.targetUnits.length == 1
                ? 'Published to 1 unit'
                : 'Published to ${release.targetUnits.length} units',
            AppConstants.info,
          );
    final meta = [
      formatFileSize(release.size),
      if (release.uploadedAt != null)
        'uploaded ${relativeTime(release.uploadedAt!, now)}'
            '${release.uploadedBy == null ? '' : ' by ${release.uploadedBy}'}',
      if (release.published && release.publishedAt != null)
        'published ${relativeTime(release.publishedAt!, now)}',
    ];
    final canPublish = release.filePresent && !_busy;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppConstants.space16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppConstants.dividerColor)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                'Version ${release.versionName}',
                style: theme.textTheme.titleMedium,
              ),
              Text('code ${release.versionCode}', style: muted),
              UnitBadge(label: status.$1, color: status.$2),
              if (!release.filePresent)
                const UnitBadge(
                  label: 'APK file missing',
                  color: AppConstants.danger,
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(meta.join(' · '), style: muted),
          if (release.sha256.isNotEmpty)
            Tooltip(
              message: 'Copy the full SHA-256',
              child: TextButton.icon(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: release.sha256));
                  showUnitToast(context, 'SHA-256 copied.');
                },
                style: TextButton.styleFrom(
                  foregroundColor: AppConstants.textMuted,
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(0, 32),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                icon: const Icon(Icons.copy_rounded, size: 14),
                label: Text(
                  'SHA-256 ${release.sha256.length > 16 ? '${release.sha256.substring(0, 16)}…' : release.sha256}',
                  style: muted,
                ),
              ),
            ),
          if (release.published && !release.targetsAll) ...[
            const SizedBox(height: 6),
            Text('Units: ${_targetText()}', style: theme.textTheme.bodySmall),
          ],
          if (release.notes.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(release.notes, style: theme.textTheme.bodyMedium),
          ],
          if (!release.filePresent) ...[
            const SizedBox(height: 8),
            const UnitNotice(
              text:
                  'The APK file is missing on the server, so this version '
                  'can\'t be published. Delete it and upload the file again.',
              icon: Icons.error_outline_rounded,
              color: AppConstants.danger,
            ),
          ],
          const SizedBox(height: AppConstants.space12),
          Wrap(
            spacing: AppConstants.space8,
            runSpacing: AppConstants.space8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (!(release.published && release.targetsAll))
                PillActionButton(
                  icon: Icons.public_rounded,
                  label: 'Publish to all units',
                  color: AppConstants.success,
                  onPressed: canPublish ? _publishToAll : null,
                ),
              PillActionButton(
                icon: Icons.checklist_rounded,
                label: 'Publish to selected units',
                color: AppConstants.info,
                onPressed: canPublish && widget.units.isNotEmpty
                    ? _publishToSelected
                    : null,
              ),
              if (release.published)
                PillActionButton(
                  icon: Icons.unpublished_rounded,
                  label: 'Unpublish',
                  color: AppConstants.warning,
                  onPressed: _busy ? null : _unpublish,
                )
              else
                PillActionButton(
                  icon: Icons.delete_outline_rounded,
                  label: 'Delete',
                  color: AppConstants.danger,
                  onPressed: _busy ? null : _delete,
                ),
              if (_busy)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PublishToUnitsDialog extends StatefulWidget {
  const _PublishToUnitsDialog({
    required this.version,
    required this.units,
    required this.initial,
  });

  final String version;
  final List<DeviceUnit> units;
  final List<String> initial;

  @override
  State<_PublishToUnitsDialog> createState() => _PublishToUnitsDialogState();
}

class _PublishToUnitsDialogState extends State<_PublishToUnitsDialog> {
  late final Set<String> _selected = {
    for (final id in widget.initial)
      if (widget.units.any((unit) => unit.installId == id)) id,
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final allSelected = _selected.length == widget.units.length;
    final count = _selected.length;
    return AdminAlertDialog(
      title: 'Publish version ${widget.version} to selected units',
      icon: Icons.checklist_rounded,
      accentColor: AppConstants.info,
      contentWidth: 460,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Only the units you tick get this version, for example a test '
            'group before everyone. Publishing again replaces the list.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppConstants.textSecondary,
            ),
          ),
          const SizedBox(height: AppConstants.space8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => setState(() {
                if (allSelected) {
                  _selected.clear();
                } else {
                  _selected.addAll(widget.units.map((unit) => unit.installId));
                }
              }),
              child: Text(allSelected ? 'Clear all' : 'Select all'),
            ),
          ),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 360),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  for (final unit in widget.units)
                    CheckboxListTile(
                      value: _selected.contains(unit.installId),
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                      title: Text(
                        unit.displayName,
                        style: theme.textTheme.bodyLarge,
                      ),
                      subtitle: Text(
                        [
                          presenceLabel(unit, now),
                          if (unit.appVersion != null) 'App ${unit.appVersion}',
                        ].join(' · '),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppConstants.textMuted,
                        ),
                      ),
                      onChanged: (checked) => setState(() {
                        if (checked == true) {
                          _selected.add(unit.installId);
                        } else {
                          _selected.remove(unit.installId);
                        }
                      }),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        DialogSubmitButton(
          label: count == 1 ? 'Publish to 1 unit' : 'Publish to $count units',
          color: AppConstants.info,
          enabled: count > 0,
          isSubmitting: false,
          onPressed: () => Navigator.of(context).pop([
            for (final unit in widget.units)
              if (_selected.contains(unit.installId)) unit.installId,
          ]),
        ),
      ],
    );
  }
}
