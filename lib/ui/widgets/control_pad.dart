import 'package:flutter/material.dart';

/// On-screen touch controls for mobile play.
class ControlPad extends StatelessWidget {
  const ControlPad({
    super.key,
    required this.onLeft,
    required this.onRight,
    required this.onRotate,
    required this.onSoftDrop,
    required this.onHardDrop,
    required this.onHold,
  });

  final VoidCallback onLeft;
  final VoidCallback onRight;
  final VoidCallback onRotate;
  final VoidCallback onSoftDrop;
  final VoidCallback onHardDrop;
  final VoidCallback onHold;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // D-pad: left / down / right
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _ControlButton(
                icon: Icons.chevron_left,
                onTap: onLeft,
                onLongPress: onLeft,
              ),
              const SizedBox(width: 4),
              _ControlButton(
                icon: Icons.keyboard_double_arrow_down,
                onTap: onHardDrop,
              ),
              const SizedBox(width: 4),
              _ControlButton(
                icon: Icons.chevron_right,
                onTap: onRight,
                onLongPress: onRight,
              ),
            ],
          ),

          // Action buttons: soft drop / rotate
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _ControlButton(
                icon: Icons.arrow_downward,
                onTap: onSoftDrop,
                onLongPress: onSoftDrop,
              ),
              const SizedBox(width: 8),
              _ControlButton(icon: Icons.swap_vert, onTap: onHold),
              const SizedBox(width: 8),
              _ControlButton(
                icon: Icons.rotate_right,
                onTap: onRotate,
                size: 56,
                isPrimary: true,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  const _ControlButton({
    required this.icon,
    required this.onTap,
    this.onLongPress,
    this.size = 48,
    this.isPrimary = false,
  });

  final IconData icon;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final double size;
  final bool isPrimary;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: isPrimary
              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.2)
              : const Color(0xFF1A2332),
          borderRadius: BorderRadius.circular(isPrimary ? size / 2 : 12),
          border: Border.all(
            color: isPrimary
                ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.6)
                : const Color(0xFF2A3A4A),
            width: isPrimary ? 2 : 1,
          ),
          boxShadow: isPrimary
              ? [
                  BoxShadow(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                    blurRadius: 12,
                  ),
                ]
              : null,
        ),
        child: Icon(
          icon,
          color: isPrimary ? Theme.of(context).colorScheme.primary : Colors.white70,
          size: size * 0.5,
        ),
      ),
    );
  }
}
