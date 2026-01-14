import 'package:flutter/material.dart';

/// Centralized animation configuration for the entire app
/// All durations and curves are optimized for fast, responsive feel
class AppAnimations {
  // ============ DURATIONS ============
  // Fast animations for micro-interactions (buttons, hovers)
  static const Duration instant = Duration(milliseconds: 100);
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 200);
  
  // Medium animations for transitions and cards
  static const Duration medium = Duration(milliseconds: 250);
  static const Duration mediumSlow = Duration(milliseconds: 300);
  
  // Slower animations for page transitions (still snappy)
  static const Duration slow = Duration(milliseconds: 350);
  static const Duration slower = Duration(milliseconds: 400);
  
  // ============ CURVES ============
  // Standard curves for most animations
  static const Curve standardCurve = Curves.easeOutCubic;
  static const Curve emphasizedCurve = Curves.easeOutQuart;
  static const Curve bouncyCurve = Curves.easeOutBack;
  
  // Entry and exit curves
  static const Curve entryCurve = Curves.easeOut;
  static const Curve exitCurve = Curves.easeIn;
  
  // Smooth deceleration curves
  static const Curve decelerateCurve = Curves.decelerate;
  static const Curve smoothCurve = Curves.easeInOut;
  
  // ============ HOVER EFFECTS ============
  static const double hoverScale = 1.02;
  static const double hoverElevation = 6.0;
  
  // ============ PRESS EFFECTS ============
  static const double pressScale = 0.96;
  
  // ============ FADE VALUES ============
  static const double fadeStart = 0.0;
  static const double fadeEnd = 1.0;
  static const double fadePartial = 0.7;
}

/// Ultra-fast fade transition for page navigation
class QuickFadeRoute<T> extends PageRouteBuilder<T> {
  final Widget page;
  
  QuickFadeRoute({required this.page})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: AppAnimations.medium,
          reverseTransitionDuration: AppAnimations.fast,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            var fadeTween = Tween<double>(
              begin: AppAnimations.fadeStart, 
              end: AppAnimations.fadeEnd,
            ).chain(CurveTween(curve: AppAnimations.standardCurve));
            
            return FadeTransition(
              opacity: animation.drive(fadeTween),
              child: child,
            );
          },
        );
}

/// Fast slide-fade combination for smooth page transitions
class QuickSlideRoute<T> extends PageRouteBuilder<T> {
  final Widget page;
  final SlideDirection direction;
  
  QuickSlideRoute({
    required this.page,
    this.direction = SlideDirection.right,
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: AppAnimations.mediumSlow,
          reverseTransitionDuration: AppAnimations.medium,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            Offset begin;
            switch (direction) {
              case SlideDirection.right:
                begin = const Offset(0.015, 0.0); // Very subtle slide
                break;
              case SlideDirection.left:
                begin = const Offset(-0.015, 0.0);
                break;
              case SlideDirection.up:
                begin = const Offset(0.0, 0.015);
                break;
              case SlideDirection.down:
                begin = const Offset(0.0, -0.015);
                break;
            }
            
            var slideTween = Tween<Offset>(
              begin: begin,
              end: Offset.zero,
            ).chain(CurveTween(curve: AppAnimations.emphasizedCurve));
            
            var fadeTween = Tween<double>(
              begin: AppAnimations.fadeStart, 
              end: AppAnimations.fadeEnd,
            ).chain(CurveTween(curve: AppAnimations.entryCurve));
            
            return SlideTransition(
              position: animation.drive(slideTween),
              child: FadeTransition(
                opacity: animation.drive(fadeTween),
                child: child,
              ),
            );
          },
        );
}

enum SlideDirection { left, right, up, down }

/// Scale transition for modal dialogs
class ScaleRoute<T> extends PageRouteBuilder<T> {
  final Widget page;
  
  ScaleRoute({required this.page})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: AppAnimations.medium,
          reverseTransitionDuration: AppAnimations.fast,
          opaque: false,
          barrierColor: Colors.black54,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            var scaleTween = Tween<double>(begin: 0.9, end: 1.0)
                .chain(CurveTween(curve: AppAnimations.bouncyCurve));
            
            var fadeTween = Tween<double>(
              begin: AppAnimations.fadeStart, 
              end: AppAnimations.fadeEnd,
            ).chain(CurveTween(curve: AppAnimations.entryCurve));
            
            return ScaleTransition(
              scale: animation.drive(scaleTween),
              child: FadeTransition(
                opacity: animation.drive(fadeTween),
                child: child,
              ),
            );
          },
        );
}

/// Navigator extensions for easy smooth navigation
extension QuickNavigation on BuildContext {
  /// Fast fade navigation
  Future<T?> quickFade<T>(Widget page) {
    return Navigator.push<T>(this, QuickFadeRoute<T>(page: page));
  }
  
  /// Fast slide navigation
  Future<T?> quickSlide<T>(Widget page, {SlideDirection direction = SlideDirection.right}) {
    return Navigator.push<T>(this, QuickSlideRoute<T>(page: page, direction: direction));
  }
  
  /// Replace with fade
  Future<T?> quickReplace<T>(Widget page) {
    return Navigator.pushReplacement<T, dynamic>(this, QuickFadeRoute<T>(page: page));
  }
  
  /// Modal dialog with scale
  Future<T?> showQuickDialog<T>(Widget page) {
    return Navigator.push<T>(this, ScaleRoute<T>(page: page));
  }
}

/// Fast animated button with press effect
class QuickButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final double scale;
  
  const QuickButton({
    super.key,
    required this.child,
    required this.onPressed,
    this.scale = AppAnimations.pressScale,
  });

  @override
  State<QuickButton> createState() => _QuickButtonState();
}

class _QuickButtonState extends State<QuickButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: AppAnimations.fast,
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: widget.scale,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: AppAnimations.standardCurve,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.onPressed != null ? (_) => _controller.forward() : null,
      onTapUp: widget.onPressed != null ? (_) {
        _controller.reverse();
        widget.onPressed?.call();
      } : null,
      onTapCancel: widget.onPressed != null ? () => _controller.reverse() : null,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: widget.child,
      ),
    );
  }
}

/// Fast hover animation for cards
class QuickHover extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double scale;
  final double elevation;
  
  const QuickHover({
    super.key,
    required this.child,
    this.onTap,
    this.scale = AppAnimations.hoverScale,
    this.elevation = AppAnimations.hoverElevation,
  });

  @override
  State<QuickHover> createState() => _QuickHoverState();
}

class _QuickHoverState extends State<QuickHover> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _elevationAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: AppAnimations.normal,
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: widget.scale,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: AppAnimations.emphasizedCurve,
    ));

    _elevationAnimation = Tween<double>(
      begin: 0.0,
      end: widget.elevation,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: AppAnimations.entryCurve,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => _controller.forward(),
      onExit: (_) => _controller.reverse(),
      cursor: widget.onTap != null ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: GestureDetector(
              onTap: widget.onTap,
              child: widget.child,
            ),
          );
        },
      ),
    );
  }
}

/// Fast counter animation for stats
class QuickCounter extends StatefulWidget {
  final int value;
  final TextStyle? style;
  
  const QuickCounter({
    super.key,
    required this.value,
    this.style,
  });

  @override
  State<QuickCounter> createState() => _QuickCounterState();
}

class _QuickCounterState extends State<QuickCounter> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  int _previousValue = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: AppAnimations.slow,
      vsync: this,
    );
    
    _animation = Tween<double>(
      begin: 0,
      end: widget.value.toDouble(),
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: AppAnimations.emphasizedCurve,
    ));
    
    _controller.forward();
  }

  @override
  void didUpdateWidget(QuickCounter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _previousValue = oldWidget.value;
      _animation = Tween<double>(
        begin: _previousValue.toDouble(),
        end: widget.value.toDouble(),
      ).animate(CurvedAnimation(
        parent: _controller,
        curve: AppAnimations.emphasizedCurve,
      ));
      _controller.reset();
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Text(
          _animation.value.toInt().toString(),
          style: widget.style,
        );
      },
    );
  }
}

/// Backwards compatibility aliases
typedef FadePageRoute<T> = QuickFadeRoute<T>;
typedef SlidePageRoute<T> = QuickSlideRoute<T>;
typedef AnimatedButton = QuickButton;

/// Legacy navigation extension
extension SmoothNavigation on BuildContext {
  Future<T?> navigateWithFade<T>(Widget page) => quickFade<T>(page);
  Future<T?> replaceWithFade<T>(Widget page) => quickReplace<T>(page);
  Future<T?> navigateWithSlide<T>(Widget page) => quickSlide<T>(page);
}
