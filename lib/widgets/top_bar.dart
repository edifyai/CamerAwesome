import 'package:flutter/material.dart';

class TopBar extends StatelessWidget {
  const TopBar({super.key});
  @override
  Widget build(BuildContext context) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(icon: const Icon(Icons.arrow_back), onPressed: () {}),
          IconButton(icon: const Icon(Icons.flash_on), onPressed: () {}),
          const Text('Done', style: TextStyle(color: Colors.yellow, fontSize: 18)),
        ],
      );
} 