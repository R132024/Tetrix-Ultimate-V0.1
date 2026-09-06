import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cubix_blast/core/game_engine.dart';
import 'package:cubix_blast/core/high_score_store.dart';
import 'package:cubix_blast/core/player_manager.dart';
import 'package:cubix_blast/core/mission_manager.dart';
import 'package:cubix_blast/core/score_manager.dart';
import 'package:cubix_blast/core/i18n.dart';
import 'banner_ad_widget.dart';

class GameOverModal extends StatefulWidget {
  const GameOverModal({
    super.key,
    required this.state,
    required this.mode,
    required this.onRetry,
    required this.onMenu,
    required this.onResume,
    this.onRevive,
    this.titleOverride,
  });

  final GameState state;
  final String mode;
  final VoidCallback onRetry;
  final VoidCallback onMenu;
  final VoidCallback onResume;
  final VoidCallback? onRevive;
  final String? titleOverride;

  @override
  State<GameOverModal> createState() => _GameOverModalState();
}

class _GameOverModalState extends State<GameOverModal> {
  late final TextEditingController _nameController;
  bool _saved = false;
  HighScore? _previousRecord;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    if (widget.state.status == GameStatus.gameOver) {
      _loadRecord();
    }
  }

  Future<void> _loadRecord() async {
    final record = await HighScoreStore.getHighScore(widget.mode);
    if (mounted) {
      setState(() {
        _previousRecord = record;
      });
    }

    if (widget.state.score > 0) {
      // Guardado automático del récord
      if (record.score == 0 || widget.state.score > record.score) {
        await HighScoreStore.saveHighScore(
          widget.mode,
          widget.state.score,
          widget.state.level,
          'YOU ',
        );
        if (mounted) {
          setState(() {
            _saved = true;
          });
        }
      }

      // Progresar Misiones y XP
      final completed = await MissionManager.reportProgress(MissionType.scorePoints, widget.state.score);
      completed.addAll(await MissionManager.reportProgress(MissionType.clearLines, widget.state.linesCleared));
      
      if (widget.mode == 'arena') {
        completed.addAll(await MissionManager.reportProgress(MissionType.playArena, 1));
      }

      int xpGained = widget.state.score ~/ 10;
      for (var m in completed) {
        xpGained += m.xpReward;
        ScoreManager.addCoins(m.coinsReward);
      }

      final leveledUp = await PlayerManager.addXp(xpGained);

      if (mounted && (completed.isNotEmpty || leveledUp)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF0F172A),
            content: Text(
              leveledUp
                  ? context.t('xp_level_up', params: {
                      'lvl': PlayerManager.profileNotifier.value.level.toString(),
                      'xp': xpGained.toString(),
                    })
                  : context.t('xp_gained', params: {'xp': xpGained.toString()}),
              style: const TextStyle(color: Color(0xFF00E5FF), fontWeight: FontWeight.bold),
            ),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  String _formatTime(double elapsedSeconds) {
    final int total = elapsedSeconds.floor();
    final int minutes = total ~/ 60;
    final int seconds = total % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: LocaleController.instance.localeNotifier,
      builder: (context, locale, _) {
        return _buildContent(context);
      },
    );
  }

  Widget _buildContent(BuildContext context) {
    final isGameOver = widget.state.status == GameStatus.gameOver;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const BannerAdWidget(),
          const SizedBox(height: 16),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOutBack,
            builder: (context, value, child) {
              return Opacity(
                opacity: value.clamp(0.0, 1.0),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10 * value, sigmaY: 10 * value),
                  child: Container(
                    color: Colors.black.withValues(
                      alpha: 0.4 * value.clamp(0.0, 1.0),
                    ),
                    alignment: Alignment.center,
                    child: Transform.scale(
                      scale: value,
                      child: Container(
                        width: 320,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F172A).withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(0xFF00E5FF),
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF00E5FF).withValues(alpha: 0.2),
                              blurRadius: 20,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Material(
                          type: MaterialType.transparency,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                isGameOver ? (widget.titleOverride ?? context.t('game_over')) : context.t('paused'),
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: 2,
                                ),
                              ),
                              const SizedBox(height: 24),
                              if (isGameOver) ...[
                                Text(
                                  '${context.t('score')}: ${widget.state.score}',
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF00E676),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '${context.t('time')}: ${_formatTime(widget.state.elapsedSeconds)}',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    color: Colors.white70,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                if (_previousRecord != null &&
                                    widget.state.score > _previousRecord!.score)
                                  const Padding(
                                    padding: EdgeInsets.only(bottom: 16),
                                    child: Text(
                                      '¡NUEVO RÉCORD!',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFFFFD600),
                                      ),
                                    ),
                                  ),
                                if (_saved)
                                  Text(
                                    context.t('score_saved'),
                                    style: const TextStyle(
                                      color: Color(0xFF00E676),
                                      fontSize: 14,
                                    ),
                                  ),
                                const SizedBox(height: 24),
                              ],
                              Wrap(
                                alignment: WrapAlignment.center,
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  if (isGameOver) ...[
                                    if (widget.onRevive != null)
                                      ElevatedButton.icon(
                                        onPressed: widget.onRevive,
                                        icon: const Icon(Icons.ondemand_video, color: Colors.white),
                                        label: const Text('Revivir', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFF00E676),
                                        ),
                                      ),
                                    ElevatedButton(
                                      onPressed: widget.onRetry,
                                      child: Text(context.t('retry')),
                                    ),
                                  ] else
                                    ElevatedButton(
                                      onPressed: widget.onResume,
                                      child: Text(context.t('resume')),
                                    ),
                                  OutlinedButton(
                                    onPressed: widget.onMenu,
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.white70,
                                      side: const BorderSide(color: Colors.white30),
                                    ),
                                    child: Text(context.t('menu')),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          const BannerAdWidget(),
        ],
      ),
    );
  }
}
