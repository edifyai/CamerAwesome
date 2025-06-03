import 'package:flutter/material.dart';

class CameraSwitchButton extends StatelessWidget {
  const CameraSwitchButton({super.key});
  @override
  Widget build(BuildContext context) => CircleAvatar(
        backgroundColor: Colors.black54,
        child: IconButton(
          icon: const Icon(Icons.cameraswitch, color: Colors.white),
          onPressed: () {
            // switch camera
          },
        ),
      );
} 