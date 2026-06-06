import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/app_theme.dart';

/// A beautiful animated loading spinner with a glowing gradient arc.
class PremiumLoadingSpinner extends StatefulWidget {
  final double size;
  final double strokeWidth;
  final Color? color;

  const PremiumLoadingSpinner({
    super.key,
    this.size = 50.0,
    this.strokeWidth = 3.0,
    this.color,
  });

  @override
  State<PremiumLoadingSpinner> createState() => _PremiumLoadingSpinnerState();
}

class _PremiumLoadingSpinnerState extends State<PremiumLoadingSpinner>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final spinnerColor = widget.color ?? AppColors.amber;
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomPaint(
            painter: _GradientArcPainter(
              progress: _controller.value,
              color: spinnerColor,
              strokeWidth: widget.strokeWidth,
            ),
          );
        },
      ),
    );
  }
}

class _GradientArcPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double strokeWidth;

  _GradientArcPainter({
    required this.progress,
    required this.color,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    // Background track
    final trackPaint = Paint()
      ..color = Colors.white.withOpacity(0.04)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawCircle(center, radius, trackPaint);

    // Rotating gradient arc
    final sweepAngle = math.pi * 1.4;
    final startAngle = progress * 2 * math.pi - math.pi / 2;

    final gradient = SweepGradient(
      startAngle: startAngle,
      endAngle: startAngle + sweepAngle,
      colors: [
        color.withOpacity(0.0),
        color.withOpacity(0.4),
        color,
      ],
      stops: const [0.0, 0.6, 1.0],
    );

    final paint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(rect, startAngle, sweepAngle, false, paint);

    // Bright dot at the end of the arc
    final dotAngle = startAngle + sweepAngle;
    final dotCenter = Offset(
      center.dx + radius * math.cos(dotAngle),
      center.dy + radius * math.sin(dotAngle),
    );
    final dotPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawCircle(dotCenter, strokeWidth * 0.8, dotPaint);

    // Glow around the dot
    final glowPaint = Paint()
      ..color = color.withOpacity(0.3)
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawCircle(dotCenter, strokeWidth * 1.5, glowPaint);
  }

  @override
  bool shouldRepaint(_GradientArcPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

/// A shimmering skeleton merchant card placeholder for loading states.
class ShimmerMerchantCard extends StatefulWidget {
  const ShimmerMerchantCard({super.key});

  @override
  State<ShimmerMerchantCard> createState() => _ShimmerMerchantCardState();
}

class _ShimmerMerchantCardState extends State<ShimmerMerchantCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _shimmerAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    _shimmerAnimation = Tween<double>(begin: -2.0, end: 2.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _shimmerAnimation,
      builder: (context, child) {
        return Container(
          margin: const EdgeInsets.only(bottom: 24),
          decoration: BoxDecoration(
            color: AppColors.ink2,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: AppColors.line),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  // 16:9 Banner Shimmer
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                    child: AspectRatio(
                      aspectRatio: 16 / 9,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: _getShimmerGradient(),
                        ),
                      ),
                    ),
                  ),
                  // Discount badge skeleton
                  Positioned(
                    top: 16,
                    right: 16,
                    child: Container(
                      width: 80,
                      height: 28,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        gradient: _getShimmerGradient(),
                      ),
                    ),
                  ),
                  // Logo avatar shimmer
                  Positioned(
                    bottom: -20,
                    left: 20,
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: AppColors.ink2,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.line, width: 2),
                      ),
                      child: ClipOval(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: _getShimmerGradient(),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title shimmer
                    Container(
                      width: 180,
                      height: 18,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6),
                        gradient: _getShimmerGradient(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Container(
                          width: 14, height: 14,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: _getShimmerGradient(),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          width: 140,
                          height: 12,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4),
                            gradient: _getShimmerGradient(),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  LinearGradient _getShimmerGradient() {
    return LinearGradient(
      colors: const [
        Color(0xFF14141C),
        Color(0xFF1E1E2A),
        Color(0xFF14141C),
      ],
      stops: const [0.0, 0.5, 1.0],
      begin: Alignment(_shimmerAnimation.value - 1.0, -0.3),
      end: Alignment(_shimmerAnimation.value + 1.0, 0.3),
    );
  }
}

/// A gorgeous glassmorphic full-screen overlay for blocking operations.
class PremiumProcessingOverlay extends StatelessWidget {
  final String message;

  const PremiumProcessingOverlay({super.key, this.message = "Processing..."});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withOpacity(0.7),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 32),
          decoration: BoxDecoration(
            color: const Color(0xFF14141E),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
            boxShadow: [
              BoxShadow(
                color: AppColors.amber.withOpacity(0.06),
                blurRadius: 40,
                spreadRadius: 4,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const PremiumLoadingSpinner(size: 48, strokeWidth: 3.5),
              const SizedBox(height: 24),
              Text(
                message.toUpperCase(),
                style: GoogleFonts.jost(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                  decoration: TextDecoration.none,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                "Please wait",
                style: GoogleFonts.jost(
                  color: Colors.white24,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 1,
                  decoration: TextDecoration.none,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A small inline loading indicator for buttons and small areas.
class PremiumLoadingDots extends StatefulWidget {
  final Color? color;
  final double dotSize;

  const PremiumLoadingDots({super.key, this.color, this.dotSize = 6.0});

  @override
  State<PremiumLoadingDots> createState() => _PremiumLoadingDotsState();
}

class _PremiumLoadingDotsState extends State<PremiumLoadingDots>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dotColor = widget.color ?? AppColors.amber;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final delay = i * 0.2;
            final t = ((_controller.value - delay) % 1.0).clamp(0.0, 1.0);
            final scale = 0.5 + 0.5 * math.sin(t * math.pi);
            return Container(
              margin: EdgeInsets.symmetric(horizontal: widget.dotSize * 0.4),
              width: widget.dotSize,
              height: widget.dotSize,
              decoration: BoxDecoration(
                color: dotColor.withOpacity(0.3 + 0.7 * scale),
                shape: BoxShape.circle,
              ),
            );
          }),
        );
      },
    );
  }
}

/// A breathtaking full-screen app opening loader with logo and premium glows.
class PremiumAppOpeningLoader extends StatefulWidget {
  const PremiumAppOpeningLoader({super.key});

  @override
  State<PremiumAppOpeningLoader> createState() => _PremiumAppOpeningLoaderState();
}

class _PremiumAppOpeningLoaderState extends State<PremiumAppOpeningLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );
    _scaleAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(
        parent: _fadeController,
        curve: Curves.easeOutBack,
      ),
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF07070A),
      body: Stack(
        children: [
          // Background ambient light glows for premium depth
          Positioned(
            top: -100,
            right: -50,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [AppColors.amber.withOpacity(0.12), Colors.transparent],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            left: -100,
            child: Container(
              width: 350,
              height: 350,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [AppColors.amber.withOpacity(0.06), Colors.transparent],
                ),
              ),
            ),
          ),
          
          // Centered content
          Center(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Premium glowing container for the logo
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.amber.withOpacity(0.04),
                            blurRadius: 40,
                            spreadRadius: 8,
                          ),
                        ],
                      ),
                      child: Image.asset(
                        'res/images/logo_transparent.png',
                        height: 120,
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(height: 48),
                    
                    // Rotating glowing arc spinner
                    const PremiumLoadingSpinner(size: 44, strokeWidth: 3.0),
                    const SizedBox(height: 24),
                    
                    // High-end Jost font status text
                    Text(
                      "LOADING APP",
                      style: GoogleFonts.jost(
                        color: Colors.white60,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 3.0,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const PremiumLoadingDots(dotSize: 5.0),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
