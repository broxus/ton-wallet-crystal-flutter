import 'package:flutter/material.dart';

/// The palette of colors in the project
/// !!! Right now names of colors are approximate, it will be changed after creating of design system
class ColorsPalette {
  const ColorsPalette({
    required this.primaryBackgroundColor,
    required this.secondaryBackgroundColor,
    required this.thirdBackgroundColor,
    required this.fourthBackgroundColor,
    required this.primaryTextColor,
    required this.primaryButtonTextColor,
    required this.secondaryButtonTextColor,
    required this.primaryButtonColor,
    required this.secondaryButtonColor,
    required this.thirdButtonColor,
    required this.textPrimaryTextButtonColor,
    required this.textSecondaryTextButtonColor,
    required this.iconPrimaryButtonColor,
    required this.iconSecondaryButtonColor,
    required this.activeInputColor,
    required this.inactiveInputColor,
    required this.primaryPressStateColor,
    required this.secondaryPressStateColor,
    required this.errorTextColor,
    required this.errorInputColor,
  });

  /// Colors for backgrounds
  final Color primaryBackgroundColor;
  final Color secondaryBackgroundColor;
  final Color thirdBackgroundColor;
  final Color fourthBackgroundColor;

  /// Colors for basic text
  final Color primaryTextColor;

  /// Colors for main button texts
  final Color primaryButtonTextColor;
  final Color secondaryButtonTextColor;

  /// Colors of default buttons
  final Color primaryButtonColor;
  final Color secondaryButtonColor;
  final Color thirdButtonColor;

  /// Colors of text of text buttons
  final Color textPrimaryTextButtonColor;
  final Color textSecondaryTextButtonColor;

  /// Colors for all icon based button
  final Color iconPrimaryButtonColor;
  final Color iconSecondaryButtonColor;

  /// Colors for inputs, checkboxes
  final Color activeInputColor;
  final Color inactiveInputColor;

  /// Color when pressing button
  final Color primaryPressStateColor;
  final Color secondaryPressStateColor;

  /// Errors
  final Color errorTextColor;
  final Color errorInputColor;
}

/// Color design system
class ColorsRes {
  const ColorsRes._();

  static const bluePrimary400 = Color(0xFF2B63F1);
  static const neutral400 = Color(0xFF8B909A);
  static const neutral500 = Color(0xFF999DA6);
  static const neutral600 = Color(0xFFA6AAB2);
  static const neutral700 = Color(0xFFB7BAC2);
  static const neutral750 = Color(0xFFF7F7F9);
  static const neutral800 = Color(0xFFD4D7DC);
  static const neutral900 = Color(0xFFF0F1F5);
  static const neutral950 = Color(0xFFF7F7F9);
  static const blue600 = Color(0xFF648DF5);
  static const blue900 = Color(0xFFDAE4FD);
  static const blue950 = Color(0xFFECF1FE);
  static const blue970 = Color(0xFFF9FAFF);
  static const red400Primary = Color(0xFFD83F5A);
  static const redBackground = Color(0x1AD83F5A);

  static const blackBlue = Color(0xFF182768);
  static const blackBlueLight = Color(0xFF555B7A);
  static const darkBlue = Color(0xFF0088CC);
  static const lightBlue = Color(0xFFC5E4F3);
  static const lightBlueOpacity = Color(0xA3C5E4F3);
  static const white = Colors.white;
  static const whiteOpacity = Color(0x8FFFFFFF);
  static const whiteOpacityLight = Color(0x66FFFFFF);
  static const black = Color(0xFF060C32);
  static const onboardingErrorBackground = Color(0xFF1A1F43);
  static const modalBarrier = Color.fromRGBO(0, 0, 0, 0.5);
  static const text = Color(0xFF050A2E);
  static const buttonOpacity = Color(0x29C5E4F3);
  static const greenOpacity = Color(0x524AB44A);
  static const green400 = Color(0xFF4AB44A);
  static const grey = Color(0xFF96A1A7);
  static const grey2 = Color(0xFFDDE1E2);
  static const grey3 = Color(0xFFCED3D6);
  static const grey4 = Color(0xFF7D8B92);
  static const notWhite = Color(0xFFF8F9F9);
  static const greyLight = Color(0xFFEBEDEE);
  static const greyOpacity = Color(0xE0F8F8FB);
  static const greyBlue = Color(0xFF838699);
  static const redDark = Color(0xFF9A325C);
  static const redLight = Color(0xFFEB4361);
  static const caution = Color(0xFFE6AC00);
}
