import 'package:flutter/material.dart';
import 'branded_loader.dart';

class ThreeColorLoader extends StatelessWidget {
  final double size;
  final Color? color1;
  final Color? color2;
  final Color? color3;
  final String? message;
  const ThreeColorLoader({super.key, this.size = 48, this.color1, this.color2, this.color3, this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: size,
        height: size,
        child: BrandedLoader(message: message),
      ),
    );
  }
}
