import 'package:flutter/material.dart';
import 'branded_loader.dart';

class CustomLoader extends StatelessWidget {
  final double size;
  const CustomLoader({super.key, this.size = 60});

  @override
  Widget build(BuildContext context) {
    return const BrandedLoader();
  }
}
