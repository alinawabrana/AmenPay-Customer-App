import 'package:flutter/material.dart';
import 'package:palmpay/utils/constants/image_text.dart';

/// A reusable widget for displaying a palm icon in a container.
/// This widget can be customized with different dimensions, colors, and icon properties.
class PalmIconContainer extends StatelessWidget {
  /// Width of the container
  final double width;

  /// Height of the container
  final double height;

  /// Border radius of the container
  final double radius;

  /// Background color of the container
  final Color backgroundColor;

  /// Icon size (width x height)
  final double iconWidth;
  final double iconHeight;

  /// Icon color
  final Color iconColor;

  /// Path to the icon asset
  final String iconPath;

  const PalmIconContainer({
    super.key,
    this.width = 96,
    this.height = 96,
    this.radius = 24,
    this.backgroundColor = const Color(0xFF238EC2),
    this.iconWidth = 40,
    this.iconHeight = 45,
    this.iconColor = Colors.white,
    this.iconPath = AImageText.palmIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Center(
        child: Image.asset(
          iconPath,
          width: iconWidth,
          height: iconHeight,
          color: iconColor,
        ),
      ),
    );
  }
}
