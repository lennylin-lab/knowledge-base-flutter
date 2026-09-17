import 'package:flutter/material.dart';

/// The app mark: the robot line art from `assets/icon/app_icon.svg`,
/// drawn as vector paths so it scales crisply and tints with any theme
/// color (the 30%-opacity face panel keeps its layering over the ring).
class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.size = 48, this.color});

  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    // Center shrink-wraps the mark to a square even inside stretch parents
    // (a tight-width Column would otherwise distort the CustomPaint).
    return Center(
      widthFactor: 1,
      heightFactor: 1,
      child: CustomPaint(
        size: Size.square(size),
        painter: _AppLogoPainter(
          // onSurface keeps the same neutral line-art color as the web
          // splash's themed mark — not the blue accent.
          color: color ?? Theme.of(context).colorScheme.onSurface,
        ),
      ),
    );
  }
}

/// The six SVG paths in paint order (face panel first, then ring, eyes,
/// mouth/ears/stem, antenna ball), in the 1024x1024 source space.
Path _appLogoPath0() => Path()
        ..moveTo(785.0667, 913.0667)
        ..lineTo(320.8533, 913.0667)
        ..cubicTo(283.3067, 913.0667, 252.5867, 882.3467, 252.5867, 844.8)
        ..lineTo(252.5867, 513.7067)
        ..cubicTo(252.5867, 476.16, 283.3067, 445.44, 320.8533, 445.44)
        ..lineTo(785.0667, 445.44)
        ..cubicTo(822.6133, 445.44, 853.3333, 476.16, 853.3333, 513.7067)
        ..lineTo(853.3333, 844.8)
        ..cubicTo(853.3333, 882.3467, 822.6133, 913.0667, 785.0667, 913.0667)
        ..close(); // alpha 1.0
Path _appLogoPath1() => Path()
        ..moveTo(783.36, 945.4933)
        ..lineTo(240.64, 945.4933)
        ..cubicTo(189.44, 945.4933, 146.7733, 902.8267, 146.7733, 851.6267)
        ..lineTo(146.7733, 445.44)
        ..cubicTo(146.7733, 394.24, 189.44, 351.5733, 240.64, 351.5733)
        ..lineTo(783.36, 351.5733)
        ..cubicTo(834.56, 351.5733, 877.2267, 394.24, 877.2267, 445.44)
        ..lineTo(877.2267, 851.6267)
        ..cubicTo(877.2267, 902.8267, 834.56, 945.4933, 783.36, 945.4933)
        ..close()
        ..moveTo(240.64, 402.7733)
        ..cubicTo(216.7467, 402.7733, 197.9733, 421.5467, 197.9733, 445.44)
        ..lineTo(197.9733, 851.6267)
        ..cubicTo(197.9733, 875.52, 216.7467, 894.2933, 240.64, 894.2933)
        ..lineTo(783.36, 894.2933)
        ..cubicTo(807.2533, 894.2933, 826.0267, 875.52, 826.0267, 851.6267)
        ..lineTo(826.0267, 445.44)
        ..cubicTo(826.0267, 421.5467, 807.2533, 402.7733, 783.36, 402.7733)
        ..lineTo(240.64, 402.7733)
        ..close(); // alpha .3
Path _appLogoPath2() => Path()
        ..moveTo(353.28, 558.08)
        ..moveTo(307.2, 558.08)
        ..arcToPoint(const Offset(399.36, 558.08), radius: const Radius.elliptical(46.08, 46.08), rotation: 0, largeArc: true, clockwise: false)
        ..arcToPoint(const Offset(307.2, 558.08), radius: const Radius.elliptical(46.08, 46.08), rotation: 0, largeArc: true, clockwise: false)
        ..close(); // alpha .3
Path _appLogoPath3() => Path()
        ..moveTo(670.72, 558.08)
        ..moveTo(624.64, 558.08)
        ..arcToPoint(const Offset(716.8, 558.08), radius: const Radius.elliptical(46.08, 46.08), rotation: 0, largeArc: true, clockwise: false)
        ..arcToPoint(const Offset(624.64, 558.08), radius: const Radius.elliptical(46.08, 46.08), rotation: 0, largeArc: true, clockwise: false)
        ..close(); // alpha .3
Path _appLogoPath4() => Path()
        ..moveTo(421.5467, 692.9067)
        ..cubicTo(395.9467, 692.9067, 375.4667, 713.3867, 375.4667, 738.9867)
        ..cubicTo(375.4667, 764.5867, 395.9467, 785.0667, 421.5467, 785.0667)
        ..lineTo(421.5467, 692.9067)
        ..close()
        ..moveTo(602.4533, 783.36)
        ..cubicTo(628.0533, 783.36, 648.5333, 762.88, 648.5333, 737.28)
        ..cubicTo(648.5333, 711.68, 628.0533, 691.2, 602.4533, 691.2)
        ..lineTo(602.4533, 783.36)
        ..close()
        ..moveTo(421.5467, 783.36)
        ..lineTo(602.4533, 783.36)
        ..lineTo(602.4533, 692.9067)
        ..lineTo(421.5467, 692.9067)
        ..lineTo(421.5467, 783.36)
        ..close()
        ..moveTo(512, 402.7733)
        ..cubicTo(498.3467, 402.7733, 486.4, 390.8267, 486.4, 377.1733)
        ..lineTo(486.4, 194.56)
        ..cubicTo(486.4, 180.9067, 498.3467, 168.96, 512, 168.96)
        ..cubicTo(525.6533, 168.96, 537.6, 180.9067, 537.6, 194.56)
        ..lineTo(537.6, 375.4667)
        ..cubicTo(537.6, 390.8267, 525.6533, 402.7733, 512, 402.7733)
        ..close()
        ..moveTo(59.7333, 762.88)
        ..cubicTo(46.08, 762.88, 34.1333, 750.9333, 34.1333, 737.28)
        ..lineTo(34.1333, 558.08)
        ..cubicTo(34.1333, 544.4267, 46.08, 532.48, 59.7333, 532.48)
        ..cubicTo(73.3867, 532.48, 85.3333, 542.72, 85.3333, 558.08)
        ..lineTo(85.3333, 738.9867)
        ..cubicTo(85.3333, 752.64, 73.3867, 762.88, 59.7333, 762.88)
        ..close()
        ..moveTo(964.2667, 762.88)
        ..cubicTo(950.6133, 762.88, 938.6667, 750.9333, 938.6667, 737.28)
        ..lineTo(938.6667, 558.08)
        ..cubicTo(938.6667, 544.4267, 950.6133, 532.48, 964.2667, 532.48)
        ..cubicTo(977.92, 532.48, 989.8667, 544.4267, 989.8667, 558.08)
        ..lineTo(989.8667, 738.9867)
        ..cubicTo(989.8667, 752.64, 977.92, 762.88, 964.2667, 762.88)
        ..close(); // alpha .3
Path _appLogoPath5() => Path()
        ..moveTo(512, 220.16)
        ..cubicTo(472.7467, 220.16, 442.0267, 187.7333, 442.0267, 150.1867)
        ..cubicTo(442.0267, 112.64, 474.4533, 78.5067, 512, 78.5067)
        ..cubicTo(549.5467, 78.5067, 581.9733, 110.9333, 581.9733, 150.1867)
        ..cubicTo(581.9733, 189.44, 551.2533, 220.16, 512, 220.16)
        ..close()
        ..moveTo(512, 131.4133)
        ..cubicTo(501.76, 131.4133, 493.2267, 139.9467, 493.2267, 151.8933)
        ..cubicTo(493.2267, 162.1333, 501.76, 170.6667, 512, 170.6667)
        ..cubicTo(522.24, 170.6667, 530.7733, 162.1333, 530.7733, 151.8933)
        ..cubicTo(530.7733, 139.9467, 522.24, 131.4133, 512, 131.4133)
        ..close(); // alpha .3

final List<(Path, double)> _appLogoParts = [
  (_appLogoPath0(), .3),
  (_appLogoPath1(), 1.0),
  (_appLogoPath2(), 1.0),
  (_appLogoPath3(), 1.0),
  (_appLogoPath4(), 1.0),
  (_appLogoPath5(), 1.0),
];

class _AppLogoPainter extends CustomPainter {
  const _AppLogoPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    // Always scale uniformly and center, whatever box the widget ends up in.
    final scale = size.shortestSide / 1024;
    canvas.translate(
      (size.width - 1024 * scale) / 2,
      (size.height - 1024 * scale) / 2,
    );
    canvas.scale(scale, scale);
    final paint = Paint()..style = PaintingStyle.fill;
    for (final (path, alpha) in _appLogoParts) {
      paint.color = color.withValues(alpha: alpha);
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_AppLogoPainter oldDelegate) =>
      oldDelegate.color != color;
}
