import 'package:flutter/material.dart';

/// Custom page route with smooth fade transition
class FadePageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;
  
  FadePageRoute({required this.page})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: const Duration(milliseconds: 300),
          reverseTransitionDuration: const Duration(milliseconds: 300),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            // Smooth fade transition with easing
            var fadeTween = Tween<double>(begin: 0.0, end: 1.0).chain(
              CurveTween(curve: Curves.easeInOut),
            );
            
            var fadeAnimation = animation.drive(fadeTween);
            
            return FadeTransition(
              opacity: fadeAnimation,
              child: child,
            );
          },
        );
}

/// Custom page route with smooth slide and fade transition
class SlidePageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;
  
  SlidePageRoute({required this.page})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: const Duration(milliseconds: 350),
          reverseTransitionDuration: const Duration(milliseconds: 300),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            // Smooth slide from right with fade
            var slideTween = Tween<Offset>(
              begin: const Offset(0.03, 0.0), // Subtle slide from right
              end: Offset.zero,
            ).chain(CurveTween(curve: Curves.easeOutCubic));
            
            var fadeTween = Tween<double>(begin: 0.0, end: 1.0).chain(
              CurveTween(curve: Curves.easeIn),
            );
            
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

/// Helper function to create smooth route with fade transition
PageRoute<T> createSmoothRoute<T>(Widget page, {bool useFade = true}) {
  if (useFade) {
    return FadePageRoute<T>(page: page);
  } else {
    return SlidePageRoute<T>(page: page);
  }
}

/// Extension on Navigator for easier smooth navigation
extension SmoothNavigation on BuildContext {
  /// Navigate to a page with smooth fade transition
  Future<T?> navigateWithFade<T>(Widget page) {
    return Navigator.push<T>(
      this,
      FadePageRoute<T>(page: page),
    );
  }
  
  /// Replace current page with smooth fade transition
  Future<T?> replaceWithFade<T>(Widget page) {
    return Navigator.pushReplacement<T, dynamic>(
      this,
      FadePageRoute<T>(page: page),
    );
  }
  
  /// Navigate to a page with slide transition
  Future<T?> navigateWithSlide<T>(Widget page) {
    return Navigator.push<T>(
      this,
      SlidePageRoute<T>(page: page),
    );
  }
}
