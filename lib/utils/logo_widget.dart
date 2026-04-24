import 'package:flutter/material.dart';

class AppLogo extends StatelessWidget {
  final double size;

  const AppLogo({super.key, this.size = 100});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            Color(0xFFE3F2FD),
          ],
        ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            spreadRadius: 2,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Academic Cap Icon
            Icon(
              Icons.school,
              size: size * 0.3,
              color: const Color(0xFF1976D2),
            ),
            const SizedBox(height: 5),
            // SAS Text
            Text(
              'SAS',
              style: TextStyle(
                color: const Color(0xFF1976D2),
                fontSize: size * 0.15,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 2),
            // Small subtitle
            Text(
              'v1.0',
              style: TextStyle(
                color: const Color(0xFF1976D2).withOpacity(0.7),
                fontSize: size * 0.05,
                fontWeight: FontWeight.w300,
              ),
            ),
          ],
        ),
      ),
    );
  }
}