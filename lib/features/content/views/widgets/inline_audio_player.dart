import 'dart:async';

import 'package:emam_admin_web_app/core/constants/app_constants.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

/// Compact inline audio player: play/pause + seekable progress bar + timings.
///
/// Fully self-contained: it owns its own [AudioPlayer], disposes it, and
/// reloads when [url] changes. Safe to drop into any card.
class InlineAudioPlayer extends StatefulWidget {
  const InlineAudioPlayer({
    super.key,
    required this.url,
    this.title,
  });

  final String url;
  final String? title;

  @override
  State<InlineAudioPlayer> createState() => _InlineAudioPlayerState();
}

class _InlineAudioPlayerState extends State<InlineAudioPlayer> {
  late final AudioPlayer _player;
  StreamSubscription<PlayerState>? _stateSub;
  Object? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();
    _stateSub = _player.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        _player.pause();
        _player.seek(Duration.zero);
      }
    });
    _load(widget.url);
  }

  @override
  void didUpdateWidget(covariant InlineAudioPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) {
      _load(widget.url);
    }
  }

  Future<void> _load(String url) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await _player.setUrl(url);
      if (mounted) setState(() => _loading = false);
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = e;
        });
      }
    }
  }

  @override
  void dispose() {
    _stateSub?.cancel();
    _player.dispose();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (d.inHours > 0) {
      return '${d.inHours}:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppConstants.bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: _error != null
          ? Row(
              children: [
                const Icon(Icons.error_outline,
                    color: Colors.redAccent, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Audio failed to load: $_error',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: Colors.white70),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh_rounded,
                      color: Colors.white70, size: 20),
                  onPressed: () => _load(widget.url),
                  tooltip: 'Retry',
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.title != null && widget.title!.isNotEmpty) ...[
                  Text(
                    widget.title!,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: AppConstants.primary,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 6),
                ],
                Row(
                  children: [
                    _PlayPauseButton(player: _player, loading: _loading),
                    const SizedBox(width: 10),
                    Expanded(child: _ProgressBar(player: _player)),
                    const SizedBox(width: 10),
                    _TimeLabel(
                      player: _player,
                      formatter: _formatDuration,
                    ),
                  ],
                ),
              ],
            ),
    );
  }
}

class _PlayPauseButton extends StatelessWidget {
  const _PlayPauseButton({required this.player, required this.loading});

  final AudioPlayer player;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<PlayerState>(
      stream: player.playerStateStream,
      builder: (context, snapshot) {
        final state = snapshot.data;
        final processing = state?.processingState;
        final isPlaying = state?.playing ?? false;
        final isBuffering = processing == ProcessingState.loading ||
            processing == ProcessingState.buffering ||
            loading;

        final child = isBuffering
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppConstants.primary,
                ),
              )
            : Icon(
                isPlaying
                    ? Icons.pause_rounded
                    : Icons.play_arrow_rounded,
                color: AppConstants.primary,
                size: 26,
              );

        return Material(
          color: AppConstants.primary.withValues(alpha: 0.14),
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: isBuffering
                ? null
                : () => isPlaying ? player.pause() : player.play(),
            child: SizedBox(
              width: 40,
              height: 40,
              child: Center(child: child),
            ),
          ),
        );
      },
    );
  }
}

class _ProgressBar extends StatefulWidget {
  const _ProgressBar({required this.player});

  final AudioPlayer player;

  @override
  State<_ProgressBar> createState() => _ProgressBarState();
}

class _ProgressBarState extends State<_ProgressBar> {
  double? _dragValue;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Duration?>(
      stream: widget.player.durationStream,
      builder: (context, durSnap) {
        final duration = durSnap.data ?? Duration.zero;
        return StreamBuilder<Duration>(
          stream: widget.player.positionStream,
          builder: (context, posSnap) {
            final position = posSnap.data ?? Duration.zero;
            final maxMs = duration.inMilliseconds.toDouble();
            final posMs = position.inMilliseconds
                .clamp(0, duration.inMilliseconds)
                .toDouble();
            final value = _dragValue ?? posMs;

            return SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 3,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                overlayShape:
                    const RoundSliderOverlayShape(overlayRadius: 12),
                activeTrackColor: AppConstants.primary,
                inactiveTrackColor: Colors.white.withValues(alpha: 0.12),
                thumbColor: AppConstants.primary,
                overlayColor: AppConstants.primary.withValues(alpha: 0.18),
              ),
              child: Slider(
                min: 0,
                max: maxMs > 0 ? maxMs : 1,
                value: maxMs > 0 ? value.clamp(0, maxMs) : 0,
                onChanged: maxMs > 0
                    ? (v) => setState(() => _dragValue = v)
                    : null,
                onChangeEnd: maxMs > 0
                    ? (v) {
                        widget.player
                            .seek(Duration(milliseconds: v.toInt()));
                        setState(() => _dragValue = null);
                      }
                    : null,
              ),
            );
          },
        );
      },
    );
  }
}

class _TimeLabel extends StatelessWidget {
  const _TimeLabel({required this.player, required this.formatter});

  final AudioPlayer player;
  final String Function(Duration) formatter;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Duration?>(
      stream: player.durationStream,
      builder: (context, durSnap) {
        final duration = durSnap.data ?? Duration.zero;
        return StreamBuilder<Duration>(
          stream: player.positionStream,
          builder: (context, posSnap) {
            final position = posSnap.data ?? Duration.zero;
            return Text(
              '${formatter(position)} / ${formatter(duration)}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.white70,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
            );
          },
        );
      },
    );
  }
}
