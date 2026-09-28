import 'package:dio/dio.dart';
import 'package:emam_admin_web_app/core/constants/api_constants.dart';
import 'package:emam_admin_web_app/core/constants/app_constants.dart';
import 'package:emam_admin_web_app/core/network/api_error.dart';
import 'package:emam_admin_web_app/core/widgets/admin_alert_dialog.dart';
import 'package:emam_admin_web_app/core/widgets/inline_retry_error.dart';
import 'package:emam_admin_web_app/core/widgets/pill_action_button.dart';
import 'package:emam_admin_web_app/core/widgets/status_badge.dart';
import 'package:emam_admin_web_app/features/content/views/widgets/content_section_card.dart';
import 'package:emam_admin_web_app/features/voice_server/models/voice_server_status.dart';
import 'package:emam_admin_web_app/features/voice_server/provider/voice_server_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

class VoiceServerView extends ConsumerWidget {
  const VoiceServerView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final status = ref.watch(voiceServerProvider);
    return LayoutBuilder(
      builder: (context, constraints) {
        final horizontalPadding = contentHorizontalPadding(
          constraints.maxWidth,
        );
        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            24,
            horizontalPadding,
            32,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Voice Demo',
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: AppConstants.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Turn the GPU voice server on for a demo or a test, and off '
                'when you are done. It only costs money while it is on.',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: AppConstants.textSecondary,
                ),
              ),
              const SizedBox(height: 24),
              status.when(
                data: (value) => _VoiceServerCard(status: value),
                loading: () => const Padding(
                  padding: EdgeInsets.all(AppConstants.space40),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (error, _) => InlineRetryError(
                  message: error is DioException
                      ? parseApiError(error)
                      : error.toString(),
                  onRetry: () => ref.invalidate(voiceServerProvider),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _VoiceServerCard extends ConsumerStatefulWidget {
  const _VoiceServerCard({required this.status});

  final VoiceServerStatus status;

  @override
  ConsumerState<_VoiceServerCard> createState() => _VoiceServerCardState();
}

class _VoiceServerCardState extends ConsumerState<_VoiceServerCard> {
  bool _busy = false;

  Future<void> _run(Future<String?> Function() action) async {
    setState(() => _busy = true);
    final error = await action();
    if (!mounted) return;
    setState(() => _busy = false);
    if (error != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
    }
  }

  Future<void> _turnOff() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AdminAlertDialog(
        title: 'Turn off the voice server?',
        icon: Icons.power_settings_new_rounded,
        accentColor: AppConstants.warning,
        content: Text(
          'Anyone using the demo right now will be cut off.',
          style: Theme.of(
            dialogContext,
          ).textTheme.bodyMedium?.copyWith(color: AppConstants.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Turn off'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _run(ref.read(voiceServerProvider.notifier).turnOff);
    }
  }

  Future<void> _openDemo() async {
    final opened = await launchUrl(
      Uri.parse(ApiConstants.voiceDemoUrl),
      webOnlyWindowName: '_blank',
    );
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open the demo page')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = widget.status;
    final phase = status.phase;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppConstants.space20),
      decoration: BoxDecoration(
        color: AppConstants.surfaceColor,
        borderRadius: BorderRadius.circular(AppConstants.radiusLg),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppConstants.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppConstants.radiusMd),
                ),
                child: const Icon(
                  Icons.graphic_eq_rounded,
                  color: AppConstants.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  'GPU voice server',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: AppConstants.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              StatusBadge(label: _label(phase), color: _color(phase)),
            ],
          ),
          const SizedBox(height: AppConstants.space16),
          Text(
            _description(status),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppConstants.textSecondary,
            ),
          ),
          const SizedBox(height: AppConstants.space12),
          if (phase == VoiceServerPhase.ready ||
              phase == VoiceServerPhase.loadingVoice)
            _InfoRow(
              icon: Icons.schedule_rounded,
              text:
                  'On for ${_duration(status.runningMinutes)}, about '
                  '\$${status.estimatedCostUsd.toStringAsFixed(2)} so far',
            ),
          if (status.activeSessions > 0)
            _InfoRow(
              icon: Icons.headset_mic_rounded,
              text: status.activeSessions == 1
                  ? '1 demo in progress'
                  : '${status.activeSessions} demos in progress',
            ),
          if (status.configured && status.idleShutdownMinutes > 0)
            _InfoRow(
              icon: Icons.power_settings_new_rounded,
              text:
                  'Turns itself off after ${status.idleShutdownMinutes} min '
                  'without use',
            ),
          if (status.configured && status.hourlyCostUsd > 0)
            _InfoRow(
              icon: Icons.payments_outlined,
              text:
                  'About \$${status.hourlyCostUsd.toStringAsFixed(2)} an hour '
                  'while on, only storage while off',
            ),
          const SizedBox(height: AppConstants.space20),
          Wrap(
            spacing: AppConstants.space12,
            runSpacing: AppConstants.space12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (status.canTurnOn || phase == VoiceServerPhase.stopping)
                FilledButton.icon(
                  onPressed: _busy || !status.canTurnOn
                      ? null
                      : () =>
                            _run(ref.read(voiceServerProvider.notifier).turnOn),
                  icon: const Icon(Icons.power_settings_new_rounded, size: 18),
                  label: const Text('Turn on'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppConstants.primary,
                    foregroundColor: AppConstants.black,
                  ),
                ),
              if (status.canTurnOff)
                PillActionButton(
                  icon: Icons.power_settings_new_rounded,
                  label: 'Turn off',
                  color: AppConstants.danger,
                  onPressed: _busy ? null : _turnOff,
                ),
              if (phase == VoiceServerPhase.ready)
                PillActionButton(
                  icon: Icons.open_in_new_rounded,
                  label: 'Open demo',
                  color: AppConstants.info,
                  onPressed: _openDemo,
                ),
              if (_busy ||
                  (status.isTransitioning &&
                      phase != VoiceServerPhase.stopping))
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

  static String _label(VoiceServerPhase phase) => switch (phase) {
    VoiceServerPhase.notConfigured => 'Not set up',
    VoiceServerPhase.off || VoiceServerPhase.stopping => 'Off',
    VoiceServerPhase.starting => 'Starting',
    VoiceServerPhase.loadingVoice => 'Loading voice',
    VoiceServerPhase.ready => 'Ready',
    VoiceServerPhase.unavailable => 'Unavailable',
  };

  static Color _color(VoiceServerPhase phase) => switch (phase) {
    VoiceServerPhase.ready => AppConstants.success,
    VoiceServerPhase.starting ||
    VoiceServerPhase.loadingVoice => AppConstants.warning,
    VoiceServerPhase.off || VoiceServerPhase.stopping => AppConstants.textMuted,
    VoiceServerPhase.notConfigured ||
    VoiceServerPhase.unavailable => AppConstants.danger,
  };

  static String _description(VoiceServerStatus status) =>
      switch (status.phase) {
        VoiceServerPhase.notConfigured =>
          'The voice server is not set up yet. The backend needs '
              'VOICE_SERVER_INSTANCE_ID and AWS access to control it.',
        VoiceServerPhase.off =>
          'Off. Turning it on takes about 3 minutes, including loading the '
              'voice.',
        VoiceServerPhase.starting => 'Starting the server…',
        VoiceServerPhase.loadingVoice =>
          'The server is up and loading the voice. This takes under a minute.',
        VoiceServerPhase.ready =>
          'Ready. Open the demo and use headphones, so the mirrored voice does '
              'not feed back into the microphone.',
        VoiceServerPhase.stopping =>
          'Off and no longer billed. AWS takes about 4 more minutes to '
              'release the server, then you can turn it on again.',
        VoiceServerPhase.unavailable =>
          'The server is unavailable (state: ${status.state}).',
      };

  static String _duration(int minutes) {
    if (minutes < 60) return '$minutes min';
    final rest = minutes % 60;
    return rest == 0 ? '${minutes ~/ 60} h' : '${minutes ~/ 60} h $rest min';
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppConstants.space8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppConstants.textFaint),
          const SizedBox(width: AppConstants.space8),
          Expanded(
            child: Text(
              text,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppConstants.textMuted),
            ),
          ),
        ],
      ),
    );
  }
}
