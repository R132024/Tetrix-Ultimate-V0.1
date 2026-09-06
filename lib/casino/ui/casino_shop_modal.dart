import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cubix_blast/casino/logic/charms.dart';
import 'package:cubix_blast/casino/logic/casino_engine.dart';

class CasinoShopModal extends StatefulWidget {
  final CasinoEngine engine;
  final VoidCallback onNextRound;

  const CasinoShopModal({
    super.key,
    required this.engine,
    required this.onNextRound,
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

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
      child: Center(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A).withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFFFD600), width: 2),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFFD600).withValues(alpha: 0.3),
                blurRadius: 30,
              ),
            ],
          ),
          child: Material(
            type: MaterialType.transparency,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'TIENDA DE AMULETOS',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 16),
                TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0, end: widget.engine.runMoney.toDouble()),
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeOutQuint,
                  builder: (context, val, child) {
                    return Text(
                      'Fichas de Partida: \$${val.toInt()}',
                      style: const TextStyle(color: Color(0xFFFFD600), fontSize: 18, fontWeight: FontWeight.bold),
                    );
                  },
                ),
                const SizedBox(height: 24),
                ..._shopItems.map((charm) => _buildCharmCard(charm)),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _reroll,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
                  child: const Text('GIRAR TIENDA (-50 Monedas)'),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: widget.onNextRound,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFD600),
                    foregroundColor: Colors.black,
                  ),
                  child: const Text('SIGUIENTE RONDA', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCharmCard(Charm charm) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black45,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white24),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(charm.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                Text(charm.description, style: const TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () => _buyCharm(charm),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: Text('${charm.cost} M', style: const TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }
}
