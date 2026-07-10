import 'package:flutter/material.dart';
import 'branded_loader.dart';

class CustomLoader extends StatelessWidget {
  final double size;
  final String? message;
  const CustomLoader({super.key, this.size = 60, this.message});

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
