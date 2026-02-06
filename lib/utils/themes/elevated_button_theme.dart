import 'package:flutter/material.dart';
import 'package:palmpay/utils/themes/text_theme.dart';

class AElevatedButtonTheme {
  static ElevatedButtonThemeData elevatedButtonTheme = ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: Color(0xFF238EC2),
      foregroundColor: Colors.white,
      textStyle: ATextTheme.textTheme.titleLarge,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
        side: BorderSide(color: Color(0xFFE5E7EB), width: 1),
      ),
    ),
  );
}
