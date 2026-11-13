import 'package:emam_admin_web_app/core/widgets/skeleton.dart';
import 'package:emam_admin_web_app/core/constants/app_constants.dart';
import 'package:emam_admin_web_app/core/network/api_error.dart';
import 'package:emam_admin_web_app/core/widgets/admin_alert_dialog.dart';
import 'package:emam_admin_web_app/core/widgets/inline_retry_error.dart';
import 'package:emam_admin_web_app/features/content/views/widgets/content_section_card.dart';
import 'package:emam_admin_web_app/features/notifications/models/notification_models.dart';
import 'package:emam_admin_web_app/features/notifications/provider/notifications_provider.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class NotificationsView extends ConsumerStatefulWidget {
  const NotificationsView({super.key});

  @override
  ConsumerState<NotificationsView> createState() => _NotificationsViewState();
}

class _NotificationsViewState extends ConsumerState<NotificationsView> {
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  String? _topic;

  @override
  void initState() {
    super.initState();
    _titleController.addListener(_onChanged);
    _bodyController.addListener(_onChanged);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  void _onChanged() => setState(() {});

  bool get _canTranslate {
    final title = _titleController.text.trim().length;
    final body = _bodyController.text.trim().length;
    return _topic != null &&
        title > 0 &&
        title <= NotificationLimits.titleMax &&
        body > 0 &&
        body <= NotificationLimits.bodyMax;
  }

  void _startOver() {
    ref.read(notificationsProvider.notifier).reset();
    _titleController.clear();
    _bodyController.clear();
  }

  Future<void> _confirmSend(NotificationsState state, String topicLabel) async {
    final count = state.toSend.length;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AdminAlertDialog(
        title: 'Send to $count ${count == 1 ? 'language' : 'languages'}?',
        icon: Icons.send_rounded,
        accentColor: AppConstants.warning,
        contentWidth: 420,
        content: Text(
          'This goes straight to every user subscribed to $topicLabel in '
          'these languages. A sent notification cannot be recalled.',
          style: Theme.of(
            dialogContext,
          ).textTheme.bodyMedium?.copyWith(color: AppConstants.textSecondary),
        ),
        actions: [
          TextButton(
            autofocus: true,
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Send now'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await ref.read(notificationsProvider.notifier).send();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(notificationsProvider);
    final options = ref.watch(notificationOptionsProvider);

    return LayoutBuilder(
      builder: (context, constraints) {
        final pad = contentHorizontalPadding(constraints.maxWidth);
        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(pad, 24, pad, 32),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Push Notifications',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: AppConstants.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Write one English message, review the translations, then '
                    'send it to users in each language.',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: AppConstants.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (state.result != null)
                    _ResultCard(state: state, onDone: _startOver)
                  else if (state.isReviewing)
                    _buildReview(state, options.asData?.value)
                  else
                    _buildCompose(state, options),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCompose(
    NotificationsState state,
    AsyncValue<NotificationOptions> options,
  ) {
    return _Card(
      child: options.when(
        loading: () => const SkeletonList(rows: 2),
        error: (error, _) => InlineRetryError(
          message: error is DioException
              ? parseApiError(error)
              : 'Could not load notification options.',
          onRetry: () => ref.invalidate(notificationOptionsProvider),
        ),
        data: (data) {
          _topic ??= data.topics.isEmpty ? null : data.topics.first.id;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: AppConstants.space8,
                children: [
                  for (final topic in data.topics)
                    ChoiceChip(
                      label: Text(topic.label),
                      selected: _topic == topic.id,
                      onSelected: state.busy
                          ? null
                          : (_) => setState(() => _topic = topic.id),
                    ),
                ],
              ),
              const SizedBox(height: AppConstants.space16),
              TextField(
                controller: _titleController,
                enabled: !state.busy,
                maxLength: NotificationLimits.titleMax,
                maxLengthEnforcement: MaxLengthEnforcement.enforced,
                decoration: const InputDecoration(
                  labelText: 'Title (English)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: AppConstants.space12),
              TextField(
                controller: _bodyController,
                enabled: !state.busy,
                maxLength: NotificationLimits.bodyMax,
                maxLengthEnforcement: MaxLengthEnforcement.enforced,
                minLines: 3,
                maxLines: 6,
                decoration: const InputDecoration(
                  labelText: 'Message (English)',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(),
                ),
              ),
              if (state.error != null) ...[
                const SizedBox(height: AppConstants.space12),
                _Message(text: state.error!, failed: true),
              ],
              const SizedBox(height: AppConstants.space16),
              Row(
                children: [
                  FilledButton(
                    onPressed: _canTranslate && !state.busy
                        ? () => ref
                              .read(notificationsProvider.notifier)
                              .translate(
                                topic: _topic!,
                                title: _titleController.text,
                                body: _bodyController.text,
                              )
                        : null,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppConstants.primary,
                      foregroundColor: AppConstants.black,
                    ),
                    child: const Text('Translate'),
                  ),
                  if (state.translating) ...[
                    const SizedBox(width: AppConstants.space12),
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(width: AppConstants.space12),
                    Flexible(
                      child: Text(
                        'Translating into every language. This can take a '
                        'minute.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppConstants.textMuted,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildReview(NotificationsState state, NotificationOptions? options) {
    final theme = Theme.of(context);
    final notifier = ref.read(notificationsProvider.notifier);
    final topicLabel =
        options?.topics
            .where((t) => t.id == state.topic)
            .map((t) => t.label)
            .firstOrNull ??
        state.topic ??
        '';
    final count = state.toSend.length;
    final allTicked = state.rows.every((r) => r.selected);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Card(
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Review translations for $topicLabel',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: AppConstants.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              TextButton(
                onPressed: state.busy ? null : _startOver,
                child: const Text('Start over'),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppConstants.space12),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            onPressed: state.busy ? null : () => notifier.setAll(!allTicked),
            child: Text(allTicked ? 'Untick all' : 'Tick all'),
          ),
        ),
        for (final row in state.rows)
          Padding(
            padding: const EdgeInsets.only(bottom: AppConstants.space12),
            child: _LanguageRow(
              key: ValueKey(row.lang),
              row: row,
              enabled: !state.busy,
              onToggle: (v) => notifier.toggle(row.lang, v),
              onTitle: (v) => notifier.edit(row.lang, title: v),
              onBody: (v) => notifier.edit(row.lang, body: v),
            ),
          ),
        if (state.error != null) ...[
          _Message(text: state.error!, failed: true),
          const SizedBox(height: AppConstants.space12),
        ],
        Row(
          children: [
            FilledButton.icon(
              onPressed: count > 0 && !state.busy
                  ? () => _confirmSend(state, topicLabel)
                  : null,
              icon: const Icon(Icons.send_rounded, size: 18),
              label: Text(
                count == 0
                    ? 'Tick at least one language'
                    : 'Send to $count ${count == 1 ? 'language' : 'languages'}',
              ),
              style: FilledButton.styleFrom(
                backgroundColor: AppConstants.primary,
                foregroundColor: AppConstants.black,
              ),
            ),
            if (state.sending) ...[
              const SizedBox(width: AppConstants.space12),
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _LanguageRow extends StatelessWidget {
  const _LanguageRow({
    super.key,
    required this.row,
    required this.enabled,
    required this.onToggle,
    required this.onTitle,
    required this.onBody,
  });

  final ReviewRow row;
  final bool enabled;
  final ValueChanged<bool> onToggle;
  final ValueChanged<String> onTitle;
  final ValueChanged<String> onBody;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Checkbox(
                value: row.selected,
                // An incomplete row can't be ticked.
                onChanged: enabled && (row.isValid || row.selected)
                    ? (v) => onToggle(v ?? false)
                    : null,
              ),
              Expanded(
                child: Text(
                  '${row.label} (${row.lang})',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: AppConstants.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          if (row.error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: AppConstants.space8),
              child: _Message(text: row.error!, failed: true),
            ),
          // Text is rendered by TextFormField as plain text, never as markup.
          TextFormField(
            initialValue: row.title,
            enabled: enabled,
            maxLength: NotificationLimits.titleMax,
            maxLengthEnforcement: MaxLengthEnforcement.enforced,
            onChanged: onTitle,
            decoration: const InputDecoration(
              labelText: 'Title',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: AppConstants.space8),
          TextFormField(
            initialValue: row.body,
            enabled: enabled,
            maxLength: NotificationLimits.bodyMax,
            maxLengthEnforcement: MaxLengthEnforcement.enforced,
            minLines: 2,
            maxLines: 5,
            onChanged: onBody,
            decoration: const InputDecoration(
              labelText: 'Message',
              alignLabelWithHint: true,
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({required this.state, required this.onDone});

  final NotificationsState state;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final result = state.result!;
    final theme = Theme.of(context);
    String names(List<String> langs) => langs.map(state.labelFor).join(', ');
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Notification sent',
            style: theme.textTheme.titleMedium?.copyWith(
              color: AppConstants.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppConstants.space12),
          if (result.sent.isNotEmpty)
            _Message(text: 'Sent: ${names(result.sent)}', failed: false),
          if (result.failed.isNotEmpty) ...[
            const SizedBox(height: AppConstants.space8),
            _Message(
              text: 'Not delivered: ${names(result.failed)}',
              failed: true,
            ),
          ],
          const SizedBox(height: AppConstants.space16),
          FilledButton(
            onPressed: onDone,
            style: FilledButton.styleFrom(
              backgroundColor: AppConstants.primary,
              foregroundColor: AppConstants.black,
            ),
            child: const Text('Write another'),
          ),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(AppConstants.space16),
    decoration: BoxDecoration(
      color: AppConstants.surfaceColor,
      borderRadius: BorderRadius.circular(AppConstants.radiusLg),
      border: Border.all(color: AppConstants.borderColor),
    ),
    child: child,
  );
}

class _Message extends StatelessWidget {
  const _Message({required this.text, required this.failed});

  final String text;
  final bool failed;

  @override
  Widget build(BuildContext context) {
    final color = failed ? AppConstants.danger : AppConstants.primary;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          failed
              ? Icons.error_outline_rounded
              : Icons.check_circle_outline_rounded,
          size: 18,
          color: color,
        ),
        const SizedBox(width: AppConstants.space8),
        Expanded(
          child: Text(
            text,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: color),
          ),
        ),
      ],
    );
  }
}
