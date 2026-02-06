import 'package:flutter/material.dart';
import 'package:palmpay/utils/themes/text_theme.dart';

class AOutlinedButtonTheme {
  static OutlinedButtonThemeData outlinedButtonTheme = OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: Color(0xFF238EC2),
      backgroundColor: Colors.white,
      textStyle: ATextTheme.textTheme.titleLarge,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
        side: BorderSide(color: Color(0xFF238EC2), width: 2),
      ),
    ),
  );
}
