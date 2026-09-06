import 'dart:math' as math;
import 'package:flutter/material.dart';


class RadialMenuItem {
  final String title;
  final IconData icon;
  final Color baseColor;
  final Color highlightColor;

  RadialMenuItem({
    required this.title,
    required this.icon,
    required this.baseColor,
    required this.highlightColor,
  });
}

class RadialModeMenu extends StatefulWidget {
  final List<RadialMenuItem> items;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final VoidCallback onRandomPressed;
  final bool isBottom;

  const RadialModeMenu({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onSelected,
    required this.onRandomPressed,
    this.isBottom = false,
  });

  @override
  State<RadialModeMenu> createState() => _RadialModeMenuState();
}

class _RadialModeMenuState extends State<RadialModeMenu> {
  final double _accumulatedDelta = 0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final height = constraints.maxHeight;
        final width = constraints.maxWidth;
        final centerOffset = height * 0.15; 

        final pointingAngle = widget.isBottom ? -math.pi / 2 : 0.0;
        final startOffset = widget.isBottom ? math.pi : -math.pi / 2;
        
        final sweepAngle = math.pi / widget.items.length;
        final targetRotation = pointingAngle - (startOffset + ((widget.selectedIndex + 0.5) * sweepAngle));

        return TweenAnimationBuilder<double>(
          tween: Tween(
            begin: targetRotation - (math.pi * 1.5),
            end: targetRotation
          ),
          duration: const Duration(milliseconds: 1200),
          curve: Curves.easeOutQuart,
          builder: (context, rotation, child) {
            return GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTapDown: (details) {
                final center = widget.isBottom 
                    ? Offset(width / 2, height)
                    : Offset(centerOffset, height / 2);
                
                final dx = details.localPosition.dx - center.dx;
                final dy = details.localPosition.dy - center.dy;
                final distance = math.sqrt(dx * dx + dy * dy);

                final coreRadius = widget.isBottom ? height * 0.25 : height * 0.16;
                if (distance < coreRadius) {
                  widget.onRandomPressed();
                  return;
                }

                final outerRadius = widget.isBottom ? height * 0.8 : height * 0.45;
                if (distance > outerRadius + 80) return;

                double screenAngle = math.atan2(dy, dx);
                
                if (widget.isBottom) {
                  if (screenAngle > 0.1 && screenAngle < math.pi - 0.1) return;
                } else {
                  if (screenAngle < (-math.pi / 2 - 0.4) || screenAngle > (math.pi / 2 + 0.4)) return;
                }

                // Find the closest visual item clone to the tapped angle
                int bestIndex = widget.selectedIndex;
                double minDiff = double.infinity;
                final int searchRange = widget.items.length; // Max 1 revolution to avoid overlap duplicates!
                for (int i = widget.selectedIndex - searchRange; i <= widget.selectedIndex + searchRange; i++) {
                  double itemAngle = startOffset + (i + 0.5) * sweepAngle + rotation;
                  // normalize diff to [-pi, pi]
                  double diff = math.atan2(math.sin(screenAngle - itemAngle), math.cos(screenAngle - itemAngle));
                  if (diff.abs() < minDiff) {
                    minDiff = diff.abs();
                    bestIndex = i;
                  }
                }
                widget.onSelected(bestIndex);
              },
              child: SizedBox(
                width: width,
                height: height,
                child: ClipRect(
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned.fill(
                        child: CustomPaint(
                          painter: RadialMenuPainter(
                            items: widget.items,
                            selectedIndex: widget.selectedIndex,
                            rotationOffset: rotation,
                            isBottom: widget.isBottom,
                            centerOffsetVal: centerOffset,
                          ),
                        ),
                      ),
                      Positioned(
                        left: widget.isBottom ? (width / 2 - height * 0.2) : 0,
                        top: widget.isBottom ? (height - height * 0.2) : height * 0.35,
                        child: Container(
                          width: widget.isBottom ? height * 0.4 : height * 0.3,
                          height: widget.isBottom ? height * 0.4 : height * 0.3,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF0F172A),
                          border: Border.all(color: const Color(0xFF00E5FF), width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF00E5FF).withValues(alpha: 0.5),
                              blurRadius: 20,
                              spreadRadius: 2,
                            ),
                            BoxShadow(
                              color: const Color(0xFF060A14),
                              blurRadius: 20,
                              spreadRadius: -5,
                              blurStyle: BlurStyle.inner,
                            )
                          ],
                        ),
                          alignment: widget.isBottom ? Alignment.topCenter : Alignment.centerRight,
                          padding: widget.isBottom ? EdgeInsets.only(top: height * 0.05) : EdgeInsets.only(right: height * 0.04),
                          child: Icon(
                            Icons.shuffle,
                            color: const Color(0xFF00E5FF),
                            size: widget.isBottom ? height * 0.1 : height * 0.08,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class RadialMenuPainter extends CustomPainter {
  final List<RadialMenuItem> items;
  final int selectedIndex;
  final double rotationOffset;
  final bool isBottom;
  final double centerOffsetVal;

  RadialMenuPainter({
    required this.items,
    required this.selectedIndex,
    required this.rotationOffset,
    this.isBottom = false,
    this.centerOffsetVal = 0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = isBottom 
        ? Offset(size.width / 2, size.height)
        : Offset(centerOffsetVal, size.height / 2);
        
    // El radio debe ajustarse al ancho en modo isBottom para no cortar los bordes.
    final outerRadius = isBottom ? size.width * 0.50 : size.height * 0.50;
    final innerRadius = isBottom ? outerRadius * 0.45 : outerRadius * 0.35; 
    
    final sweepAngle = math.pi / items.length;
    final startOffset = isBottom ? math.pi : -math.pi / 2;

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotationOffset);
    canvas.translate(-center.dx, -center.dy);

    final totalItems = items.length;

    // Dibujamos de afuera hacia adentro para que los originales (más cercanos al centro)
    // SIEMPRE se dibujen por encima de las copias/clones (más lejanos al centro).
    for (int dist = totalItems; dist >= 0; dist--) {
      if (dist == 0) {
        // Centro (botón principal seleccionado)
        int actualIndex = selectedIndex % totalItems;
        if (actualIndex < 0) actualIndex += totalItems;
        _drawSingleItem(canvas, center, outerRadius, innerRadius, startOffset, sweepAngle, selectedIndex, actualIndex, true);
      } else {
        // Lado izquierdo (i < selectedIndex)
        int iLeft = selectedIndex - dist;
        int actualLeft = iLeft % totalItems;
        if (actualLeft < 0) actualLeft += totalItems;
        _drawSingleItem(canvas, center, outerRadius, innerRadius, startOffset, sweepAngle, iLeft, actualLeft, false);

        // Lado derecho (i > selectedIndex)
        int iRight = selectedIndex + dist;
        int actualRight = iRight % totalItems;
        if (actualRight < 0) actualRight += totalItems;
        _drawSingleItem(canvas, center, outerRadius, innerRadius, startOffset, sweepAngle, iRight, actualRight, false);
      }
    }
    
    canvas.restore();
  }

  void _drawSingleItem(Canvas canvas, Offset center, double outerRadius, double innerRadius, double startOffset, double sweepAngle, int i, int actualIndex, bool isSelected) {
    final item = items[actualIndex];
    final currentStart = startOffset + (i * sweepAngle);
    
    final gap = 0.02;
    
    // Si está seleccionado, sobresale un poco
    final extraRadius = isSelected ? 20.0 : 0.0;
    final currentOuterRadius = outerRadius + extraRadius;

    final path = Path()
      ..arcTo(
        Rect.fromCircle(center: center, radius: currentOuterRadius),
        currentStart + gap,
        sweepAngle - (gap * 2),
        true,
      )
      ..arcTo(
        Rect.fromCircle(center: center, radius: innerRadius),
        currentStart + sweepAngle - gap,
        -(sweepAngle - (gap * 2)),
        false,
      )
      ..close();

    // Calculamos el ángulo central de este botón
    final midAngle = currentStart + (sweepAngle / 2);
    // Para que la luz sea exactamente igual (tenue) en TODOS los botones sin importar su posición,
    // colocamos el centro del gradiente en el lado exactamente OPUESTO del círculo.
    final gradientCenter = Alignment(-math.cos(midAngle), -math.sin(midAngle));

    final gradient = RadialGradient(
      center: gradientCenter,
      radius: 1.0,
      colors: [
        isSelected ? item.highlightColor : item.baseColor.withValues(alpha: 0.6),
        const Color(0xFF060A14),
      ],
    );

    final paint = Paint()
      ..style = PaintingStyle.fill
      ..shader = gradient.createShader(Rect.fromCircle(center: center, radius: currentOuterRadius));

    if (isSelected) {
      canvas.drawShadow(path, item.highlightColor, 20, true);
    } else {
      canvas.drawShadow(path, Colors.black, 10, true);
    }

    canvas.drawPath(path, paint);

    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = isSelected ? 3.0 : 1.5
      ..color = isSelected ? item.highlightColor : item.baseColor.withValues(alpha: 0.5);
    canvas.drawPath(path, borderPaint);

    _drawItemContent(canvas, center, currentOuterRadius, innerRadius, currentStart, sweepAngle, item, isSelected);
  }

  void _drawItemContent(Canvas canvas, Offset center, double outerRadius, double innerRadius, double startAngle, double sweepAngle, RadialMenuItem item, bool isSelected) {
    final midAngle = startAngle + (sweepAngle / 2);
    final midRadius = innerRadius + ((outerRadius - innerRadius) / 2);

    final iconX = center.dx + midRadius * math.cos(midAngle);
    final iconY = center.dy + midRadius * math.sin(midAngle);

    canvas.save();
    canvas.translate(iconX, iconY);
    
    canvas.rotate(midAngle);

    final iconPainter = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(item.icon.codePoint),
        style: TextStyle(
          fontSize: isSelected ? 46 : 38,
          fontFamily: item.icon.fontFamily,
          package: item.icon.fontPackage,
          color: isSelected ? Colors.white : Colors.white70,
          shadows: isSelected ? [Shadow(color: item.highlightColor, blurRadius: 15)] : null,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    iconPainter.layout();
    iconPainter.paint(canvas, Offset(-iconPainter.width / 2, -iconPainter.height / 2));

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant RadialMenuPainter oldDelegate) {
    return oldDelegate.selectedIndex != selectedIndex || oldDelegate.rotationOffset != rotationOffset;
  }
}
