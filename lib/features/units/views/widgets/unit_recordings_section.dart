import 'package:emam_admin_web_app/core/constants/app_constants.dart';
import 'package:emam_admin_web_app/core/utils/formatters.dart';
import 'package:emam_admin_web_app/core/widgets/inline_retry_error.dart';
import 'package:emam_admin_web_app/core/widgets/pill_action_button.dart';
import 'package:emam_admin_web_app/core/widgets/section_empty_message.dart';
import 'package:emam_admin_web_app/features/content/views/widgets/content_section_card.dart';
import 'package:emam_admin_web_app/features/units/models/device_unit.dart';
import 'package:emam_admin_web_app/features/units/models/unit_recording.dart';
import 'package:emam_admin_web_app/features/units/provider/unit_recordings_provider.dart';
import 'package:emam_admin_web_app/features/units/provider/units_provider.dart';
import 'package:emam_admin_web_app/features/units/provider/units_repository_provider.dart';
import 'package:emam_admin_web_app/features/units/utils/browser_files.dart';
import 'package:emam_admin_web_app/features/units/utils/unit_display.dart';
import 'package:emam_admin_web_app/features/units/views/widgets/unit_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class UnitRecordingsSection extends ConsumerWidget {
  const UnitRecordingsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recordingsAsync = ref.watch(unitRecordingsProvider);
    final units = ref.watch(unitsProvider).value?.units ?? const [];
    final data = recordingsAsync.value;
    final free = data?.diskFreeGb;
    final count = data?.recordings.length;
    return ContentSectionCard(
      title: 'Recordings',
      subtitle: data == null
          ? 'Khutbah sessions units recorded and uploaded'
          : [
              count == 1 ? '1 recording' : '$count recordings',
              if (free != null)
                '${free.toStringAsFixed(1)} GB free on the server',
            ].join(' · '),
      icon: Icons.mic_rounded,
      child: recordingsAsync.when(
        skipLoadingOnReload: true,
        loading: () => const SectionLoadingIndicator(),
        error: (error, _) => InlineRetryError(
          message: unitErrorMessage(error),
          onRetry: () => ref.invalidate(unitRecordingsProvider),
        ),
        data: (data) => data.recordings.isEmpty
            ? const SectionEmptyMessage(
                'No recordings yet. Use "Record Khutbah sessions" on a unit '
                'to record its next sessions.',
                icon: Icons.mic_none_rounded,
              )
            : Column(
                children: [
                  for (final recording in data.recordings)
                    _RecordingRow(
                      recording: recording,
                      unitName: _unitName(recording.installId, units),
                    ),
                ],
              ),
      ),
    );
  }

  static String _unitName(String installId, List<DeviceUnit> units) {
    for (final unit in units) {
      if (unit.installId == installId) return unit.displayName;
    }
    return 'Unit ${shortId(installId)}';
  }
}

class _RecordingRow extends ConsumerStatefulWidget {
  const _RecordingRow({required this.recording, required this.unitName});

  final UnitRecording recording;
  final String unitName;

  @override
  ConsumerState<_RecordingRow> createState() => _RecordingRowState();
}

class _RecordingRowState extends ConsumerState<_RecordingRow> {
  double? _progress;
  bool _deleting = false;

  bool get _busy => _progress != null || _deleting;

  String get _downloadName {
    final unit = widget.unitName.replaceAll(RegExp(r'[^A-Za-z0-9_.-]+'), '-');
    return '$unit-${widget.recording.name}';
  }

  Future<void> _download() async {
    setState(() => _progress = 0);
    try {
      final bytes = await ref
          .read(unitsRepositoryProvider)
          .downloadRecording(
            widget.recording.installId,
            widget.recording.name,
            onProgress: (received, total) {
              if (mounted && total > 0) {
                setState(() => _progress = received / total);
              }
            },
          );
      saveBytes(bytes, _downloadName, 'audio/wav');
    } catch (error) {
      if (mounted) showUnitToast(context, unitErrorMessage(error), error: true);
    }
    if (mounted) setState(() => _progress = null);
  }

  Future<void> _delete() async {
    final confirmed = await confirmUnitAction(
      context,
      title: 'Delete this recording?',
      body:
          '${widget.recording.name} from ${widget.unitName} is deleted from '
          'the server. This can\'t be undone.',
      action: 'Delete recording',
      icon: Icons.delete_outline_rounded,
      color: AppConstants.danger,
    );
    if (!confirmed || !mounted) return;
    setState(() => _deleting = true);
    try {
      await ref.read(unitRecordingsProvider.notifier).delete(widget.recording);
      if (mounted) showUnitToast(context, 'Recording deleted.');
    } catch (error) {
      if (mounted) showUnitToast(context, unitErrorMessage(error), error: true);
    }
    if (mounted) setState(() => _deleting = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final recording = widget.recording;
    final progress = _progress;
    final meta = [
      formatFileSize(recording.size),
      if (recording.modified != null)
        formatAdminDate(recording.modified, includeTime: true),
    ];
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppConstants.space12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppConstants.dividerColor)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppConstants.primary.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.graphic_eq_rounded,
                  size: 18,
                  color: AppConstants.primary,
                ),
              ),
              const SizedBox(width: AppConstants.space12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.unitName, style: theme.textTheme.titleSmall),
                    const SizedBox(height: 2),
                    Text(recording.name, style: theme.textTheme.bodyMedium),
                    const SizedBox(height: 2),
                    Text(
                      meta.join(' · '),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppConstants.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppConstants.space8),
              UnitBadge(
                label: recording.complete ? 'Complete' : 'Still uploading',
                color: recording.complete
                    ? AppConstants.success
                    : AppConstants.warning,
              ),
            ],
          ),
          if (recording.complete) ...[
            const SizedBox(height: AppConstants.space8),
            Padding(
              padding: const EdgeInsets.only(left: 46),
              child: Wrap(
                spacing: AppConstants.space8,
                runSpacing: AppConstants.space8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  PillActionButton(
                    icon: Icons.download_rounded,
                    label: progress == null
                        ? 'Download'
                        : 'Downloading ${(progress * 100).round()}%',
                    color: AppConstants.primary,
                    onPressed: _busy ? null : _download,
                  ),
                  PillActionButton(
                    icon: Icons.delete_outline_rounded,
                    label: 'Delete',
                    color: AppConstants.danger,
                    onPressed: _busy ? null : _delete,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
