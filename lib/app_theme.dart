import 'package:flutter/material.dart';
import 'package:palmpay/utils/themes/elevated_button_theme.dart';
import 'package:palmpay/utils/themes/icon_theme.dart';
import 'package:palmpay/utils/themes/input_decoration_theme.dart';
import 'package:palmpay/utils/themes/outlined_button_theme.dart';
import 'package:palmpay/utils/themes/text_theme.dart';

class ATheme {
  static ThemeData appTheme = ThemeData(
    textTheme: ATextTheme.textTheme,
    iconTheme: AIconTheme.iconTheme,
    primaryColor: Color(0xFF238EC2),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Colors.white,
      selectedItemColor: Color(0xFF238EC2),
      unselectedItemColor: Color(0xFF9CA3AF),
      selectedLabelStyle: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        letterSpacing: -0.5,
      ),
      unselectedLabelStyle: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        letterSpacing: -0.5,
      ),
    ),
    elevatedButtonTheme: AElevatedButtonTheme.elevatedButtonTheme,
    outlinedButtonTheme: AOutlinedButtonTheme.outlinedButtonTheme,
    inputDecorationTheme: ATextFormFieldTheme.textFormFieldTheme,
  );
}
