import 'package:flutter/material.dart';
import 'branded_loader.dart';

class ThreeColorLoader extends StatelessWidget {
  final double size;
  const ThreeColorLoader({super.key, this.size = 48, Color? color1, Color? color2, Color? color3});

  @override
  Widget build(BuildContext context) {
    return const BrandedLoader();
  }
}
