import 'package:flutter/material.dart';

class JoystickView extends StatefulWidget {
  final Function(double dx, double dy) onChanged;
  const JoystickView({super.key, required this.onChanged});

  @override
  State<JoystickView> createState() => _JoystickViewState();
}

class _JoystickViewState extends State<JoystickView> {
  Offset _knob = Offset.zero;
  static const double _radius = 55;

  void _update(Offset local) {
    final center = const Offset(70, 70);
    var delta = local - center;
    final dist = delta.distance;
    if (dist > _radius) {
      delta = delta / dist * _radius;
    }
    setState(() => _knob = delta);
    widget.onChanged(delta.dx / _radius, delta.dy / _radius);
  }

  void _reset() {
    setState(() => _knob = Offset.zero);
    widget.onChanged(0, 0);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: (d) => _update(d.localPosition),
      onPanUpdate: (d) => _update(d.localPosition),
      onPanEnd: (_) => _reset(),
      onPanCancel: _reset,
      child: Container(
        width: 140,
        height: 140,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.black.withOpacity(0.35),
          border: Border.all(color: Colors.white.withOpacity(0.25), width: 2),
        ),
        child: Stack(
          children: [
            Positioned(
              left: 70 + _knob.dx - 28,
              top: 70 + _knob.dy - 28,
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.85),
                  boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 8)],
                ),
                child: const Icon(Icons.navigation, color: Colors.green, size: 28),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
