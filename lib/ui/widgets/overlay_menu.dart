import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/audio_service.dart';
import '../../core/i18n.dart';
import 'banner_ad_widget.dart';
import 'confirm_dialog.dart';

class OverlayMenu extends StatelessWidget {
  const OverlayMenu({
    super.key,
    required this.title,
    required this.score,
    required this.bestScore,
    this.onResume,
    required this.onRestart,
    required this.onHome,
    this.confirmOnHome = false,
  });

  final String title;
  final int score;
  final int bestScore;
  final VoidCallback? onResume;
  final VoidCallback onRestart;
  final VoidCallback onHome;
  final bool confirmOnHome;

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
    return Positioned.fill(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          color: Colors.black.withValues(alpha: 0.4),
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
              decoration: BoxDecoration(
                color: const Color(0xFF0D1420).withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                    blurRadius: 30,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const BannerAdWidget(),
                    const SizedBox(height: 16),
                    Text(
                      title,
                      style: GoogleFonts.orbitron(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        shadows: [Shadow(color: Theme.of(context).colorScheme.primary, blurRadius: 15)],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _ScoreItem(label: context.t('score'), value: score),
                        const SizedBox(width: 40),
                        _ScoreItem(label: context.t('best'), value: bestScore),
                      ],
                    ),
                    const SizedBox(height: 28),
                    if (onResume != null) ...[
                      _MenuButton(
                        label: context.t('resume'),
                        icon: Icons.play_arrow,
                        onTap: onResume!,
                        color: const Color(0xFF00E676),
                      ),
                      const SizedBox(height: 14),
                    ] else ...[
                      _MenuButton(
                        label: context.t('share_score'),
                        icon: Icons.share,
                        onTap: () {
                          final text =
                              '🧊💥 He logrado $score pts en Cubix Blast! ¿Puedes vencerme? 🟦🟩🟪';
                          // ignore: deprecated_member_use
                          Share.share(text);
                        },
                        color: const Color(0xFFFFD600),
                      ),
                      const SizedBox(height: 14),
                    ],
                    // Botón de Modo Música dentro de pausa
                    ValueListenableBuilder<bool>(
                      valueListenable: AudioService.instance.bgmNotifier,
                      builder: (context, isBgmEnabled, _) {
                        final isExternalMusicMode = !isBgmEnabled;
                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _MenuButton(
                              label: isExternalMusicMode
                                  ? context.t('music_mode_on')
                                  : context.t('music_mode_off'),
                              icon: isExternalMusicMode ? Icons.headphones : Icons.music_note,
                              onTap: () {
                                AudioService.instance.playBoton();
                                AudioService.instance.toggleBgm();
                              },
                              color: isExternalMusicMode
                                  ? const Color(0xFFFF0055)
                                  : const Color(0xFF00E5FF),
                            ),
                            const SizedBox(height: 14),
                          ],
                        );
                      },
                    ),
                    _MenuButton(
                      label: context.t('retry'),
                      icon: Icons.refresh,
                      onTap: () async {
                        final confirmed = await showNeonConfirmDialog(
                          context: context,
                          title: context.t('confirm_restart_title'),
                          message: context.t('confirm_restart_body'),
                          confirmLabel: context.t('confirm_restart_btn'),
                          confirmColor: const Color(0xFF00E5FF),
                          confirmIcon: Icons.refresh,
                        );
                        if (confirmed) {
                          onRestart();
                        }
                      },
                      color: const Color(0xFF00E5FF),
                    ),
                    const SizedBox(height: 14),
                    _MenuButton(
                      label: context.t('home'),
                      icon: Icons.home,
                      onTap: () async {
                        if (confirmOnHome) {
                          final confirmed = await showNeonConfirmDialog(
                            context: context,
                            title: context.t('confirm_quit_title'),
                            message: context.t('confirm_quit_body'),
                            confirmLabel: context.t('confirm_quit_btn'),
                            confirmColor: const Color(0xFFFF1744),
                            confirmIcon: Icons.exit_to_app,
                          );
                          if (confirmed) {
                            onHome();
                          }
                        } else {
                          onHome();
                        }
                      },
                      color: const Color(0xFFFF1744),
                    ),
                    const SizedBox(height: 16),
                    const BannerAdWidget(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ScoreItem extends StatelessWidget {
  const _ScoreItem({required this.label, required this.value});
  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: GoogleFonts.orbitron(
            fontSize: 12,
            color: Colors.white70,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value.toString(),
          style: GoogleFonts.orbitron(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}

class _MenuButton extends StatelessWidget {
  const _MenuButton({
    required this.label,
    required this.icon,
    required this.onTap,
    required this.color,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 200,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.5)),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: GoogleFonts.orbitron(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: color,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
