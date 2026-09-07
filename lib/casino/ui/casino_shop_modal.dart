import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cubix_blast/casino/logic/charms.dart';
import 'package:cubix_blast/casino/logic/casino_engine.dart';
import 'package:cubix_blast/core/audio_service.dart';

class CasinoShopModal extends StatefulWidget {
  final CasinoEngine engine;
  final VoidCallback onNextRound;
  final VoidCallback onGameOver;

  const CasinoShopModal({
    super.key,
    required this.engine,
    required this.onNextRound,
    required this.onGameOver,
  });

  @override
  State<CasinoShopModal> createState() => _CasinoShopModalState();
}

class _CasinoShopModalState extends State<CasinoShopModal> {
  List<Charm> _shopItems = [];

  @override
  void initState() {
    super.initState();
    _rollShop();
  }

  void _rollShop() {
    final allCharms = CharmsRegistry.getAllAvailable();
    allCharms.shuffle();
    setState(() {
      _shopItems = allCharms.take(3).toList();
    });
  }

  void _reroll() {
    if (widget.engine.runMoney >= 50) {
      setState(() {
        widget.engine.runMoney -= 50;
        _rollShop();
      });
    }
  }

  void _buyCharm(Charm charm) {
    if (widget.engine.runMoney >= charm.cost) {
      setState(() {
        widget.engine.runMoney -= charm.cost;
        widget.engine.activeCharms.add(charm);
        charm.onEquip(widget.engine);
        _shopItems.remove(charm);
      });
    }
  }

  // --- RETRO COLORS ---
  static const Color crtGreen = Color(0xFF4AF626);
  static const Color crtDark = Color(0xFF051005);
  static const Color crtAmber = Color(0xFFFFB000);
  static const Color crtRed = Color(0xFFFF1744);

  Color _getRarityColor(CharmRarity rarity) {
    switch (rarity) {
      case CharmRarity.common: return Colors.white;
      case CharmRarity.rare: return Colors.blueAccent;
      case CharmRarity.epic: return Colors.purpleAccent;
      case CharmRarity.legendary: return crtAmber;
      case CharmRarity.cursed: return crtRed;
      case CharmRarity.punishment: return Colors.deepOrange;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool canPayDebt = widget.engine.runMoney >= widget.engine.targetDebt;

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
      child: Center(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.95,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: crtDark,
            border: Border.all(color: crtGreen, width: 4), // Blocky 8-bit border
            boxShadow: [
              BoxShadow(
                color: crtGreen.withValues(alpha: 0.2),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Material(
            type: MaterialType.transparency,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                Text(
                  'TIENDA DE AMULETOS',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.pressStart2p(fontSize: 14, color: crtGreen, shadows: [
                    const Shadow(color: crtGreen, blurRadius: 10)
                  ]),
                ),
                const SizedBox(height: 8),
                
                // PANEL DE DEUDA
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  decoration: BoxDecoration(
                    color: crtRed.withValues(alpha: 0.2),
                    border: Border.all(color: crtRed, width: 2),
                  ),
                  child: Text(
                    'DEUDA: \$${widget.engine.targetDebt} -> \$${widget.engine.nextTargetDebt}',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.vt323(
                      color: crtRed, 
                      fontSize: 18, 
                      fontWeight: FontWeight.bold
                    ),
                  ),
                ),
                
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    border: Border.all(color: crtAmber, width: 2),
                    color: Colors.black,
                  ),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0, end: widget.engine.runMoney.toDouble()),
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeOutQuint,
                    builder: (context, val, child) {
                      return Text(
                        'FICHAS: \$${val.toInt()}',
                        style: GoogleFonts.vt323(color: crtAmber, fontSize: 24, fontWeight: FontWeight.bold),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),
                ..._shopItems.map((charm) => _buildCharmCard(charm)),
                const SizedBox(height: 8),
                _buildRetroButton(
                  text: 'GIRAR TIENDA (-\$50)',
                  color: Colors.blueAccent,
                  onPressed: _reroll,
                ),
                const SizedBox(height: 8),
                if (!widget.engine.isCycleDebtPaid && !widget.engine.isDebtRound) ...[
                  _buildRetroButton(
                    text: canPayDebt ? 'PAGAR DEUDA' : 'DEUDA NO PAGABLE',
                    color: canPayDebt ? const Color(0xFF00E676) : Colors.grey,
                    textColor: Colors.black,
                    onPressed: () {
                      if (canPayDebt) {
                        setState(() {
                          widget.engine.runMoney -= widget.engine.targetDebt;
                          widget.engine.isCycleDebtPaid = true;
                        });
                        AudioService.instance.playBoton();
                      }
                    },
                  ),
                  const SizedBox(height: 8),
                ],
                _buildRetroButton(
                  text: widget.engine.isCycleDebtPaid || !widget.engine.isDebtRound
                      ? 'SIGUIENTE RONDA >>'
                      : (canPayDebt ? 'PAGAR Y AVANZAR >>' : 'BANCARROTA (MORIR)'),
                  color: (widget.engine.isCycleDebtPaid || !widget.engine.isDebtRound || canPayDebt) ? crtGreen : crtRed,
                  textColor: Colors.black,
                  onPressed: () {
                    if (widget.engine.isCycleDebtPaid || !widget.engine.isDebtRound) {
                      widget.onNextRound();
                    } else if (canPayDebt) {
                      setState(() {
                        widget.engine.runMoney -= widget.engine.targetDebt;
                        widget.engine.isCycleDebtPaid = true;
                      });
                      widget.onNextRound();
                    } else {
                      widget.onGameOver();
                    }
                  },
                ),
              ],
            ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCharmCard(Charm charm) {
    final rarityColor = _getRarityColor(charm.rarity);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.black,
        border: Border.all(color: rarityColor, width: 2),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white24),
              color: const Color(0xFF111111),
            ),
            child: Text(
              charm.icon,
              style: const TextStyle(fontSize: 24),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  charm.name.toUpperCase(), 
                  style: GoogleFonts.pressStart2p(color: rarityColor, fontSize: 10)
                ),
                const SizedBox(height: 4),
                Text(
                  charm.description, 
                  style: GoogleFonts.vt323(color: Colors.white70, fontSize: 14),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('\$${charm.cost}', style: GoogleFonts.vt323(color: crtAmber, fontSize: 20)),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () => _buyCharm(charm),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: rarityColor.withValues(alpha: 0.2),
                    border: Border.all(color: rarityColor, width: 2),
                  ),
                  child: Text('COMPRAR', style: GoogleFonts.vt323(color: rarityColor, fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildRetroButton({required String text, required Color color, Color? textColor, required VoidCallback onPressed}) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color,
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: const [
            BoxShadow(
              color: Colors.black,
              offset: Offset(4, 4), // 8-bit drop shadow
            )
          ]
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: GoogleFonts.pressStart2p(color: textColor ?? Colors.white, fontSize: 12),
        ),
      ),
    );
  }
}
