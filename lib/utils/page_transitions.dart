import 'package:flutter/material.dart';

class SmoothPageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;
  
  SmoothPageRoute({required this.page})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: const Duration(milliseconds: 200),
          reverseTransitionDuration: const Duration(milliseconds: 200),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            // Subtle fade transition with gentle easing curve
            const curve = Curves.easeInOut;
            final fadeAnimation = CurvedAnimation(
              parent: animation,
              curve: curve,
            );
            
            return FadeTransition(
              opacity: fadeAnimation,
              child: child,
            );
          },
        );
}

class SmoothReplacementPageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;
  
  SmoothReplacementPageRoute({required this.page})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: const Duration(milliseconds: 250),
          reverseTransitionDuration: const Duration(milliseconds: 250),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            // Slightly longer fade for replacement to feel more natural
            const curve = Curves.easeInOut;
            final fadeAnimation = CurvedAnimation(
              parent: animation,
              curve: curve,
            );
            
            return FadeTransition(
              opacity: fadeAnimation,
              child: child,
            );
          },
        );
}
