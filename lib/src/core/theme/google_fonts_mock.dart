import 'package:flutter/material.dart';
import 'dart:ui';

class GoogleFonts {
  static TextStyle _font({
    TextStyle? textStyle,
    Color? color,
    Color? backgroundColor,
    double? fontSize,
    FontWeight? fontWeight,
    FontStyle? fontStyle,
    double? letterSpacing,
    double? wordSpacing,
    TextBaseline? textBaseline,
    double? height,
    Locale? locale,
    Paint? foreground,
    Paint? background,
    List<Shadow>? shadows,
    List<FontFeature>? fontFeatures,
    TextDecoration? decoration,
    Color? decorationColor,
    TextDecorationStyle? decorationStyle,
    double? decorationThickness,
  }) {
    final baseStyle = textStyle ?? const TextStyle();
    final double? finalSize = (fontSize ?? baseStyle.fontSize) != null 
        ? (fontSize ?? baseStyle.fontSize)! + 1.5 
        : null;

    return baseStyle.copyWith(
      fontFamily: 'KOMedia',
      color: color,
      backgroundColor: backgroundColor,
      fontSize: finalSize,
      fontWeight: fontWeight,
      fontStyle: fontStyle,
      letterSpacing: letterSpacing,
      wordSpacing: wordSpacing,
      textBaseline: textBaseline,
      height: height,
      locale: locale,
      foreground: foreground,
      background: background,
      shadows: shadows,
      fontFeatures: fontFeatures,
      decoration: decoration,
      decorationColor: decorationColor,
      decorationStyle: decorationStyle,
      decorationThickness: decorationThickness,
    );
  }

  static TextStyle almarai({
    TextStyle? textStyle, Color? color, Color? backgroundColor, double? fontSize,
    FontWeight? fontWeight, FontStyle? fontStyle, double? letterSpacing, double? wordSpacing,
    TextBaseline? textBaseline, double? height, Locale? locale, Paint? foreground, Paint? background,
    List<Shadow>? shadows, List<FontFeature>? fontFeatures, TextDecoration? decoration,
    Color? decorationColor, TextDecorationStyle? decorationStyle, double? decorationThickness,
  }) => _font(
    textStyle: textStyle, color: color, backgroundColor: backgroundColor, fontSize: fontSize,
    fontWeight: fontWeight, fontStyle: fontStyle, letterSpacing: letterSpacing, wordSpacing: wordSpacing,
    textBaseline: textBaseline, height: height, locale: locale, foreground: foreground, background: background,
    shadows: shadows, fontFeatures: fontFeatures, decoration: decoration,
    decorationColor: decorationColor, decorationStyle: decorationStyle, decorationThickness: decorationThickness,
  );

  static TextStyle tajawal({
    TextStyle? textStyle, Color? color, Color? backgroundColor, double? fontSize,
    FontWeight? fontWeight, FontStyle? fontStyle, double? letterSpacing, double? wordSpacing,
    TextBaseline? textBaseline, double? height, Locale? locale, Paint? foreground, Paint? background,
    List<Shadow>? shadows, List<FontFeature>? fontFeatures, TextDecoration? decoration,
    Color? decorationColor, TextDecorationStyle? decorationStyle, double? decorationThickness,
  }) => _font(
    textStyle: textStyle, color: color, backgroundColor: backgroundColor, fontSize: fontSize,
    fontWeight: fontWeight, fontStyle: fontStyle, letterSpacing: letterSpacing, wordSpacing: wordSpacing,
    textBaseline: textBaseline, height: height, locale: locale, foreground: foreground, background: background,
    shadows: shadows, fontFeatures: fontFeatures, decoration: decoration,
    decorationColor: decorationColor, decorationStyle: decorationStyle, decorationThickness: decorationThickness,
  );

  static TextStyle robotoMono({
    TextStyle? textStyle, Color? color, Color? backgroundColor, double? fontSize,
    FontWeight? fontWeight, FontStyle? fontStyle, double? letterSpacing, double? wordSpacing,
    TextBaseline? textBaseline, double? height, Locale? locale, Paint? foreground, Paint? background,
    List<Shadow>? shadows, List<FontFeature>? fontFeatures, TextDecoration? decoration,
    Color? decorationColor, TextDecorationStyle? decorationStyle, double? decorationThickness,
  }) => _font(
    textStyle: textStyle, color: color, backgroundColor: backgroundColor, fontSize: fontSize,
    fontWeight: fontWeight, fontStyle: fontStyle, letterSpacing: letterSpacing, wordSpacing: wordSpacing,
    textBaseline: textBaseline, height: height, locale: locale, foreground: foreground, background: background,
    shadows: shadows, fontFeatures: fontFeatures, decoration: decoration,
    decorationColor: decorationColor, decorationStyle: decorationStyle, decorationThickness: decorationThickness,
  );

  static TextStyle cairo({
    TextStyle? textStyle, Color? color, Color? backgroundColor, double? fontSize,
    FontWeight? fontWeight, FontStyle? fontStyle, double? letterSpacing, double? wordSpacing,
    TextBaseline? textBaseline, double? height, Locale? locale, Paint? foreground, Paint? background,
    List<Shadow>? shadows, List<FontFeature>? fontFeatures, TextDecoration? decoration,
    Color? decorationColor, TextDecorationStyle? decorationStyle, double? decorationThickness,
  }) => _font(
    textStyle: textStyle, color: color, backgroundColor: backgroundColor, fontSize: fontSize,
    fontWeight: fontWeight, fontStyle: fontStyle, letterSpacing: letterSpacing, wordSpacing: wordSpacing,
    textBaseline: textBaseline, height: height, locale: locale, foreground: foreground, background: background,
    shadows: shadows, fontFeatures: fontFeatures, decoration: decoration,
    decorationColor: decorationColor, decorationStyle: decorationStyle, decorationThickness: decorationThickness,
  );

  static TextStyle lato({
    TextStyle? textStyle, Color? color, Color? backgroundColor, double? fontSize,
    FontWeight? fontWeight, FontStyle? fontStyle, double? letterSpacing, double? wordSpacing,
    TextBaseline? textBaseline, double? height, Locale? locale, Paint? foreground, Paint? background,
    List<Shadow>? shadows, List<FontFeature>? fontFeatures, TextDecoration? decoration,
    Color? decorationColor, TextDecorationStyle? decorationStyle, double? decorationThickness,
  }) => _font(
    textStyle: textStyle, color: color, backgroundColor: backgroundColor, fontSize: fontSize,
    fontWeight: fontWeight, fontStyle: fontStyle, letterSpacing: letterSpacing, wordSpacing: wordSpacing,
    textBaseline: textBaseline, height: height, locale: locale, foreground: foreground, background: background,
    shadows: shadows, fontFeatures: fontFeatures, decoration: decoration,
    decorationColor: decorationColor, decorationStyle: decorationStyle, decorationThickness: decorationThickness,
  );

  static TextStyle poppins({
    TextStyle? textStyle, Color? color, Color? backgroundColor, double? fontSize,
    FontWeight? fontWeight, FontStyle? fontStyle, double? letterSpacing, double? wordSpacing,
    TextBaseline? textBaseline, double? height, Locale? locale, Paint? foreground, Paint? background,
    List<Shadow>? shadows, List<FontFeature>? fontFeatures, TextDecoration? decoration,
    Color? decorationColor, TextDecorationStyle? decorationStyle, double? decorationThickness,
  }) => _font(
    textStyle: textStyle, color: color, backgroundColor: backgroundColor, fontSize: fontSize,
    fontWeight: fontWeight, fontStyle: fontStyle, letterSpacing: letterSpacing, wordSpacing: wordSpacing,
    textBaseline: textBaseline, height: height, locale: locale, foreground: foreground, background: background,
    shadows: shadows, fontFeatures: fontFeatures, decoration: decoration,
    decorationColor: decorationColor, decorationStyle: decorationStyle, decorationThickness: decorationThickness,
  );

  static TextStyle inter({
    TextStyle? textStyle, Color? color, Color? backgroundColor, double? fontSize,
    FontWeight? fontWeight, FontStyle? fontStyle, double? letterSpacing, double? wordSpacing,
    TextBaseline? textBaseline, double? height, Locale? locale, Paint? foreground, Paint? background,
    List<Shadow>? shadows, List<FontFeature>? fontFeatures, TextDecoration? decoration,
    Color? decorationColor, TextDecorationStyle? decorationStyle, double? decorationThickness,
  }) => _font(
    textStyle: textStyle, color: color, backgroundColor: backgroundColor, fontSize: fontSize,
    fontWeight: fontWeight, fontStyle: fontStyle, letterSpacing: letterSpacing, wordSpacing: wordSpacing,
    textBaseline: textBaseline, height: height, locale: locale, foreground: foreground, background: background,
    shadows: shadows, fontFeatures: fontFeatures, decoration: decoration,
    decorationColor: decorationColor, decorationStyle: decorationStyle, decorationThickness: decorationThickness,
  );

  static TextStyle outfit({
    TextStyle? textStyle, Color? color, Color? backgroundColor, double? fontSize,
    FontWeight? fontWeight, FontStyle? fontStyle, double? letterSpacing, double? wordSpacing,
    TextBaseline? textBaseline, double? height, Locale? locale, Paint? foreground, Paint? background,
    List<Shadow>? shadows, List<FontFeature>? fontFeatures, TextDecoration? decoration,
    Color? decorationColor, TextDecorationStyle? decorationStyle, double? decorationThickness,
  }) => _font(
    textStyle: textStyle, color: color, backgroundColor: backgroundColor, fontSize: fontSize,
    fontWeight: fontWeight, fontStyle: fontStyle, letterSpacing: letterSpacing, wordSpacing: wordSpacing,
    textBaseline: textBaseline, height: height, locale: locale, foreground: foreground, background: background,
    shadows: shadows, fontFeatures: fontFeatures, decoration: decoration,
    decorationColor: decorationColor, decorationStyle: decorationStyle, decorationThickness: decorationThickness,
  );

  static TextStyle roboto({
    TextStyle? textStyle, Color? color, Color? backgroundColor, double? fontSize,
    FontWeight? fontWeight, FontStyle? fontStyle, double? letterSpacing, double? wordSpacing,
    TextBaseline? textBaseline, double? height, Locale? locale, Paint? foreground, Paint? background,
    List<Shadow>? shadows, List<FontFeature>? fontFeatures, TextDecoration? decoration,
    Color? decorationColor, TextDecorationStyle? decorationStyle, double? decorationThickness,
  }) => _font(
    textStyle: textStyle, color: color, backgroundColor: backgroundColor, fontSize: fontSize,
    fontWeight: fontWeight, fontStyle: fontStyle, letterSpacing: letterSpacing, wordSpacing: wordSpacing,
    textBaseline: textBaseline, height: height, locale: locale, foreground: foreground, background: background,
    shadows: shadows, fontFeatures: fontFeatures, decoration: decoration,
    decorationColor: decorationColor, decorationStyle: decorationStyle, decorationThickness: decorationThickness,
  );
}
