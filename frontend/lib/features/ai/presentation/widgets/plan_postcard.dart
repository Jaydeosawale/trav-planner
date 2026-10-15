import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// A local vector postcard: no image API, fabricated photograph or image cost.
class PlanPostcard extends StatelessWidget {
  const PlanPostcard({
    super.key,
    required this.destination,
    required this.days,
    required this.activities,
    this.stops = const [],
  });
  final String destination;
  final int days, activities;
  final List<String> stops;
  @override
  Widget build(BuildContext context) => Container(
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(24),
      gradient: const LinearGradient(
        colors: [AppColors.ocean, Color(0xFF176F79)],
      ),
    ),
    child: Stack(
      children: [
        const Positioned(
          right: -30,
          top: -18,
          width: 220,
          height: 220,
          child: CustomPaint(painter: _JourneyScene()),
        ),
        Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'YOUR NEXT CHAPTER',
                style: TextStyle(
                  color: Color(0xFF9FE3D6),
                  fontSize: 11,
                  letterSpacing: 2,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 40),
              Text(
                destination,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  _tag(Icons.calendar_today_outlined, '$days days'),
                  _tag(Icons.route_outlined, '$activities stops'),
                  _tag(Icons.auto_awesome_outlined, 'Made for you'),
                ],
              ),
              if (stops.isNotEmpty) ...[
                const SizedBox(height: 16),
                for (final stop in stops.take(3))
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          size: 14,
                          color: Color(0xFFFDBA74),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            stop,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
              const SizedBox(height: 12),
              const Text(
                'A suggested journey · review before you go',
                style: TextStyle(color: Color(0xFFD0EAE5), fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    ),
  );
  Widget _tag(IconData icon, String label) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 14, color: const Color(0xFFFDBA74)),
      const SizedBox(width: 5),
      Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
    ],
  );
}

class _JourneyScene extends CustomPainter {
  const _JourneyScene();
  @override
  void paint(Canvas c, Size s) {
    c.drawCircle(
      Offset(s.width * .58, s.height * .27),
      25,
      Paint()..color = AppColors.sunset,
    );
    c.drawPath(
      Path()
        ..moveTo(0, s.height * .72)
        ..lineTo(s.width * .35, s.height * .32)
        ..lineTo(s.width * .64, s.height * .72)
        ..close(),
      Paint()..color = const Color(0xFF64A99B),
    );
    c.drawPath(
      Path()
        ..moveTo(s.width * .28, s.height * .85)
        ..lineTo(s.width * .66, s.height * .41)
        ..lineTo(s.width, s.height * .85)
        ..close(),
      Paint()..color = const Color(0xFF8EC7AB),
    );
    final path = Path()
      ..moveTo(16, s.height * .8)
      ..cubicTo(
        s.width * .4,
        s.height * .5,
        s.width * .5,
        s.height * 1.1,
        s.width * .84,
        s.height * .65,
      );
    c.drawPath(
      path,
      Paint()
        ..color = const Color(0xFFFBE4A2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
    for (final point in [
      Offset(16, s.height * .8),
      Offset(s.width * .84, s.height * .65),
    ]) {
      c.drawCircle(point, 6, Paint()..color = Colors.white);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
