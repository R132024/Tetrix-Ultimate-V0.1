import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cubix_blast/core/daily_rewards_manager.dart';

class DailyRewardsModal extends StatefulWidget {
  const DailyRewardsModal({super.key});

  @override
  State<DailyRewardsModal> createState() => _DailyRewardsModalState();
}

class _DailyRewardsModalState extends State<DailyRewardsModal> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;
  bool _isClaiming = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.elasticOut,
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _handleClaim() async {
    if (_isClaiming) return;
    setState(() => _isClaiming = true);
    
    final reward = await DailyRewardsManager.claimReward();
    
    if (!mounted) return;

    if (reward != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF0F172A),
          content: Text(
            '¡Reclamado! +${reward.coins} monedas',
            style: const TextStyle(color: Color(0xFFFFD600), fontWeight: FontWeight.bold),
          ),
        ),
      );
    }

    // Delay closing to show animations
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A).withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: const Color(0xFFFFD600),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFFD600).withValues(alpha: 0.3),
                  blurRadius: 30,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Material(
              type: MaterialType.transparency,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'RECOMPENSA DIARIA',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '¡Vuelve todos los días para obtener el cofre!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ValueListenableBuilder<int>(
                    valueListenable: DailyRewardsManager.currentStreakNotifier,
                    builder: (context, streak, child) {
                      return Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        alignment: WrapAlignment.center,
                        children: List.generate(7, (index) {
                          final reward = DailyRewardsManager.rewards[index];
                          final isToday = index == streak;
                          final isClaimed = index < streak;

                          return _buildDayCard(reward, isToday, isClaimed);
                        }),
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  ValueListenableBuilder<bool>(
                    valueListenable: DailyRewardsManager.canClaimTodayNotifier,
                    builder: (context, canClaim, child) {
                      return ElevatedButton(
                        onPressed: (_isClaiming || !canClaim) ? null : _handleClaim,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFFD600),
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          elevation: 8,
                        ),
                        child: Text(
                          _isClaiming ? 'RECLAMANDO...' : 'RECLAMAR',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () {
                      if (!_isClaiming) Navigator.of(context).pop();
                    },
                    child: const Text(
                      'CERRAR',
                      style: TextStyle(color: Colors.white54),
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDayCard(DailyReward reward, bool isToday, bool isClaimed) {
    Color borderColor = Colors.white24;
    Color bgColor = Colors.black26;
    if (isToday) {
      borderColor = const Color(0xFF00E5FF);
      bgColor = const Color(0xFF00E5FF).withValues(alpha: 0.2);
    } else if (isClaimed) {
      borderColor = const Color(0xFF00E676);
      bgColor = const Color(0xFF00E676).withValues(alpha: 0.2);
    }

    if (reward.isPremium) {
      borderColor = const Color(0xFFFFD600);
      if (isToday) bgColor = const Color(0xFFFFD600).withValues(alpha: 0.3);
    }

    return Container(
      width: reward.isPremium ? 120 : 70,
      height: 80,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: isToday ? 2 : 1),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Día ${reward.day}',
                style: TextStyle(
                  color: isClaimed ? Colors.white54 : Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Icon(
                reward.isPremium ? Icons.card_giftcard : Icons.monetization_on,
                color: isClaimed ? Colors.white30 : (reward.isPremium ? const Color(0xFFFFD600) : Colors.yellow),
                size: reward.isPremium ? 28 : 20,
              ),
              const SizedBox(height: 4),
              Text(
                '+${reward.coins}',
                style: TextStyle(
                  color: isClaimed ? Colors.white54 : const Color(0xFFFFD600),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          if (isClaimed)
            const Positioned(
              child: Icon(Icons.check_circle, color: Color(0xFF00E676), size: 32),
            ),
        ],
      ),
    );
  }
}
