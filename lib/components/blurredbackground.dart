import 'dart:ui';
import 'package:flutter/material.dart';

class BlurredBackgroundContainer extends StatelessWidget {
  final Widget child;

  const BlurredBackgroundContainer({Key? key, required this.child})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          color: Colors.grey.withOpacity(0.5),
          width: MediaQuery.of(context).size.width,
          height: 60,
        ),
        // Blurred container
        BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Container(
            color: Colors.transparent,
            width: MediaQuery.of(context).size.width,
            height: 60,
            child: child,
          ),
        ),
      ],
    );
  }
}
