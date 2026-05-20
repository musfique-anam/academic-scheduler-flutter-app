// lib/utils/app_logo.dart

import 'package:flutter/material.dart';

class AppLogo extends StatelessWidget {
  final double size;
  final Color? color;
  final bool withBackground;

  const AppLogo({
    super.key,
    this.size = 120,
    this.color,
    this.withBackground = true,
  });

  @override
  Widget build(BuildContext context) {
    if (withBackground) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Icon(
          Icons.school,
          size: size * 0.6,
          color: color ?? const Color(0xFF1976D2),
        ),
      );
    } else {
      return Icon(
        Icons.school,
        size: size,
        color: color ?? Colors.white,
      );
    }
  }
}