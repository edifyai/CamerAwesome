import 'package:flutter/material.dart';

class ShutterButton extends StatelessWidget {
  final VoidCallback onPressed;
  const ShutterButton({super.key, required this.onPressed});
  @override
  Widget build(BuildContext context) => Center(
        child: GestureDetector(
          onTap: onPressed,
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 6),
              color: Colors.white.withOpacity(0.7),
            ),
          ),
        ),
      );
} 