import "package:flutter/material.dart";

class MaterialTheme {
  final TextTheme textTheme;

  const MaterialTheme(this.textTheme);

  static ColorScheme lightScheme() {
    return const ColorScheme(
      brightness: Brightness.light,
      primary: Color(0xff864b6f),
      surfaceTint: Color(0xff864b6f),
      onPrimary: Color(0xffffffff),
      primaryContainer: Color(0xffffd8eb),
      onPrimaryContainer: Color(0xff6b3457),
      secondary: Color(0xff715765),
      onSecondary: Color(0xffffffff),
      secondaryContainer: Color(0xfffbd9ea),
      onSecondaryContainer: Color(0xff58404d),
      tertiary: Color(0xff80543d),
      onTertiary: Color(0xffffffff),
      tertiaryContainer: Color(0xffffdbcb),
      onTertiaryContainer: Color(0xff653d28),
      error: Color(0xffba1a1a),
      onError: Color(0xffffffff),
      errorContainer: Color(0xffffdad6),
      onErrorContainer: Color(0xff93000a),
      surface: Color(0xfffff8f8),
      onSurface: Color(0xff211a1d),
      onSurfaceVariant: Color(0xff4f4349),
      outline: Color(0xff81737a),
      outlineVariant: Color(0xffd3c2c9),
      shadow: Color(0xff000000),
      scrim: Color(0xff000000),
      inverseSurface: Color(0xff362e32),
      inversePrimary: Color(0xfffab1da),
      primaryFixed: Color(0xffffd8eb),
      onPrimaryFixed: Color(0xff370729),
      primaryFixedDim: Color(0xfffab1da),
      onPrimaryFixedVariant: Color(0xff6b3457),
      secondaryFixed: Color(0xfffbd9ea),
      onSecondaryFixed: Color(0xff291521),
      secondaryFixedDim: Color(0xffdebece),
      onSecondaryFixedVariant: Color(0xff58404d),
      tertiaryFixed: Color(0xffffdbcb),
      onTertiaryFixed: Color(0xff311303),
      tertiaryFixedDim: Color(0xfff4ba9d),
      onTertiaryFixedVariant: Color(0xff653d28),
      surfaceDim: Color(0xffe4d6db),
      surfaceBright: Color(0xfffff8f8),
      surfaceContainerLowest: Color(0xffffffff),
      surfaceContainerLow: Color(0xfffff0f5),
      surfaceContainer: Color(0xfff9eaef),
      surfaceContainerHigh: Color(0xfff3e4e9),
      surfaceContainerHighest: Color(0xffeddfe4),
    );
  }

  ThemeData light() {
    return theme(lightScheme());
  }

  static ColorScheme lightMediumContrastScheme() {
    return const ColorScheme(
      brightness: Brightness.light,
      primary: Color(0xff572345),
      surfaceTint: Color(0xff864b6f),
      onPrimary: Color(0xffffffff),
      primaryContainer: Color(0xff97597e),
      onPrimaryContainer: Color(0xffffffff),
      secondary: Color(0xff46303c),
      onSecondary: Color(0xffffffff),
      secondaryContainer: Color(0xff806673),
      onSecondaryContainer: Color(0xffffffff),
      tertiary: Color(0xff512d19),
      onTertiary: Color(0xffffffff),
      tertiaryContainer: Color(0xff91624a),
      onTertiaryContainer: Color(0xffffffff),
      error: Color(0xff740006),
      onError: Color(0xffffffff),
      errorContainer: Color(0xffcf2c27),
      onErrorContainer: Color(0xffffffff),
      surface: Color(0xfffff8f8),
      onSurface: Color(0xff160f13),
      onSurfaceVariant: Color(0xff3e3339),
      outline: Color(0xff5c4f55),
      outlineVariant: Color(0xff776970),
      shadow: Color(0xff000000),
      scrim: Color(0xff000000),
      inverseSurface: Color(0xff362e32),
      inversePrimary: Color(0xfffab1da),
      primaryFixed: Color(0xff97597e),
      onPrimaryFixed: Color(0xffffffff),
      primaryFixedDim: Color(0xff7b4265),
      onPrimaryFixedVariant: Color(0xffffffff),
      secondaryFixed: Color(0xff806673),
      onSecondaryFixed: Color(0xffffffff),
      secondaryFixedDim: Color(0xff674e5b),
      onSecondaryFixedVariant: Color(0xffffffff),
      tertiaryFixed: Color(0xff91624a),
      onTertiaryFixed: Color(0xffffffff),
      tertiaryFixedDim: Color(0xff754b34),
      onTertiaryFixedVariant: Color(0xffffffff),
      surfaceDim: Color(0xffd0c3c8),
      surfaceBright: Color(0xfffff8f8),
      surfaceContainerLowest: Color(0xffffffff),
      surfaceContainerLow: Color(0xfffff0f5),
      surfaceContainer: Color(0xfff3e4e9),
      surfaceContainerHigh: Color(0xffe7d9de),
      surfaceContainerHighest: Color(0xffdcced3),
    );
  }

  ThemeData lightMediumContrast() {
    return theme(lightMediumContrastScheme());
  }

  static ColorScheme lightHighContrastScheme() {
    return const ColorScheme(
      brightness: Brightness.light,
      primary: Color(0xff4b193b),
      surfaceTint: Color(0xff864b6f),
      onPrimary: Color(0xffffffff),
      primaryContainer: Color(0xff6e3659),
      onPrimaryContainer: Color(0xffffffff),
      secondary: Color(0xff3b2632),
      onSecondary: Color(0xffffffff),
      secondaryContainer: Color(0xff5a424f),
      onSecondaryContainer: Color(0xffffffff),
      tertiary: Color(0xff452310),
      onTertiary: Color(0xffffffff),
      tertiaryContainer: Color(0xff683f2a),
      onTertiaryContainer: Color(0xffffffff),
      error: Color(0xff600004),
      onError: Color(0xffffffff),
      errorContainer: Color(0xff98000a),
      onErrorContainer: Color(0xffffffff),
      surface: Color(0xfffff8f8),
      onSurface: Color(0xff000000),
      onSurfaceVariant: Color(0xff000000),
      outline: Color(0xff34292e),
      outlineVariant: Color(0xff52464c),
      shadow: Color(0xff000000),
      scrim: Color(0xff000000),
      inverseSurface: Color(0xff362e32),
      inversePrimary: Color(0xfffab1da),
      primaryFixed: Color(0xff6e3659),
      onPrimaryFixed: Color(0xffffffff),
      primaryFixedDim: Color(0xff532042),
      onPrimaryFixedVariant: Color(0xffffffff),
      secondaryFixed: Color(0xff5a424f),
      onSecondaryFixed: Color(0xffffffff),
      secondaryFixedDim: Color(0xff422c38),
      onSecondaryFixedVariant: Color(0xffffffff),
      tertiaryFixed: Color(0xff683f2a),
      onTertiaryFixed: Color(0xffffffff),
      tertiaryFixedDim: Color(0xff4d2916),
      onTertiaryFixedVariant: Color(0xffffffff),
      surfaceDim: Color(0xffc2b5ba),
      surfaceBright: Color(0xfffff8f8),
      surfaceContainerLowest: Color(0xffffffff),
      surfaceContainerLow: Color(0xfffcedf2),
      surfaceContainer: Color(0xffeddfe4),
      surfaceContainerHigh: Color(0xffdfd1d6),
      surfaceContainerHighest: Color(0xffd0c3c8),
    );
  }

  ThemeData lightHighContrast() {
    return theme(lightHighContrastScheme());
  }

  static ColorScheme darkScheme() {
    return const ColorScheme(
      brightness: Brightness.dark,
      primary: Color(0xfffab1da),
      surfaceTint: Color(0xfffab1da),
      onPrimary: Color(0xff501e3f),
      primaryContainer: Color(0xff6b3457),
      onPrimaryContainer: Color(0xffffd8eb),
      secondary: Color(0xffdebece),
      onSecondary: Color(0xff402a36),
      secondaryContainer: Color(0xff58404d),
      onSecondaryContainer: Color(0xfffbd9ea),
      tertiary: Color(0xfff4ba9d),
      onTertiary: Color(0xff4b2714),
      tertiaryContainer: Color(0xff653d28),
      onTertiaryContainer: Color(0xffffdbcb),
      error: Color(0xffffb4ab),
      onError: Color(0xff690005),
      errorContainer: Color(0xff93000a),
      onErrorContainer: Color(0xffffdad6),
      surface: Color(0xff181115),
      onSurface: Color(0xffeddfe4),
      onSurfaceVariant: Color(0xffd3c2c9),
      outline: Color(0xff9c8d93),
      outlineVariant: Color(0xff4f4349),
      shadow: Color(0xff000000),
      scrim: Color(0xff000000),
      inverseSurface: Color(0xffeddfe4),
      inversePrimary: Color(0xff864b6f),
      primaryFixed: Color(0xffffd8eb),
      onPrimaryFixed: Color(0xff370729),
      primaryFixedDim: Color(0xfffab1da),
      onPrimaryFixedVariant: Color(0xff6b3457),
      secondaryFixed: Color(0xfffbd9ea),
      onSecondaryFixed: Color(0xff291521),
      secondaryFixedDim: Color(0xffdebece),
      onSecondaryFixedVariant: Color(0xff58404d),
      tertiaryFixed: Color(0xffffdbcb),
      onTertiaryFixed: Color(0xff311303),
      tertiaryFixedDim: Color(0xfff4ba9d),
      onTertiaryFixedVariant: Color(0xff653d28),
      surfaceDim: Color(0xff181115),
      surfaceBright: Color(0xff3f373b),
      surfaceContainerLowest: Color(0xff130c10),
      surfaceContainerLow: Color(0xff211a1d),
      surfaceContainer: Color(0xff251e21),
      surfaceContainerHigh: Color(0xff30282c),
      surfaceContainerHighest: Color(0xff3b3236),
    );
  }

  ThemeData dark() {
    return theme(darkScheme());
  }

  static ColorScheme darkMediumContrastScheme() {
    return const ColorScheme(
      brightness: Brightness.dark,
      primary: Color(0xffffcfe8),
      surfaceTint: Color(0xfffab1da),
      onPrimary: Color(0xff431234),
      primaryContainer: Color(0xffbe7ca3),
      onPrimaryContainer: Color(0xff000000),
      secondary: Color(0xfff5d3e3),
      onSecondary: Color(0xff341f2b),
      secondaryContainer: Color(0xffa68997),
      onSecondaryContainer: Color(0xff000000),
      tertiary: Color(0xffffd3bf),
      onTertiary: Color(0xff3e1d0a),
      tertiaryContainer: Color(0xffb9856b),
      onTertiaryContainer: Color(0xff000000),
      error: Color(0xffffd2cc),
      onError: Color(0xff540003),
      errorContainer: Color(0xffff5449),
      onErrorContainer: Color(0xff000000),
      surface: Color(0xff181115),
      onSurface: Color(0xffffffff),
      onSurfaceVariant: Color(0xffead8df),
      outline: Color(0xffbeaeb4),
      outlineVariant: Color(0xff9b8c93),
      shadow: Color(0xff000000),
      scrim: Color(0xff000000),
      inverseSurface: Color(0xffeddfe4),
      inversePrimary: Color(0xff6c3558),
      primaryFixed: Color(0xffffd8eb),
      onPrimaryFixed: Color(0xff29001e),
      primaryFixedDim: Color(0xfffab1da),
      onPrimaryFixedVariant: Color(0xff572345),
      secondaryFixed: Color(0xfffbd9ea),
      onSecondaryFixed: Color(0xff1d0b16),
      secondaryFixedDim: Color(0xffdebece),
      onSecondaryFixedVariant: Color(0xff46303c),
      tertiaryFixed: Color(0xffffdbcb),
      onTertiaryFixed: Color(0xff230900),
      tertiaryFixedDim: Color(0xfff4ba9d),
      onTertiaryFixedVariant: Color(0xff512d19),
      surfaceDim: Color(0xff181115),
      surfaceBright: Color(0xff4b4246),
      surfaceContainerLowest: Color(0xff0b0609),
      surfaceContainerLow: Color(0xff231c1f),
      surfaceContainer: Color(0xff2e2629),
      surfaceContainerHigh: Color(0xff393034),
      surfaceContainerHighest: Color(0xff443b3f),
    );
  }

  ThemeData darkMediumContrast() {
    return theme(darkMediumContrastScheme());
  }

  static ColorScheme darkHighContrastScheme() {
    return const ColorScheme(
      brightness: Brightness.dark,
      primary: Color(0xffffebf3),
      surfaceTint: Color(0xfffab1da),
      onPrimary: Color(0xff000000),
      primaryContainer: Color(0xfff5add6),
      onPrimaryContainer: Color(0xff1f0015),
      secondary: Color(0xffffebf3),
      onSecondary: Color(0xff000000),
      secondaryContainer: Color(0xffdabaca),
      onSecondaryContainer: Color(0xff160610),
      tertiary: Color(0xffffece4),
      onTertiary: Color(0xff000000),
      tertiaryContainer: Color(0xffefb69a),
      onTertiaryContainer: Color(0xff1a0600),
      error: Color(0xffffece9),
      onError: Color(0xff000000),
      errorContainer: Color(0xffffaea4),
      onErrorContainer: Color(0xff220001),
      surface: Color(0xff181115),
      onSurface: Color(0xffffffff),
      onSurfaceVariant: Color(0xffffffff),
      outline: Color(0xfffeebf2),
      outlineVariant: Color(0xffcfbec5),
      shadow: Color(0xff000000),
      scrim: Color(0xff000000),
      inverseSurface: Color(0xffeddfe4),
      inversePrimary: Color(0xff6c3558),
      primaryFixed: Color(0xffffd8eb),
      onPrimaryFixed: Color(0xff000000),
      primaryFixedDim: Color(0xfffab1da),
      onPrimaryFixedVariant: Color(0xff29001e),
      secondaryFixed: Color(0xfffbd9ea),
      onSecondaryFixed: Color(0xff000000),
      secondaryFixedDim: Color(0xffdebece),
      onSecondaryFixedVariant: Color(0xff1d0b16),
      tertiaryFixed: Color(0xffffdbcb),
      onTertiaryFixed: Color(0xff000000),
      tertiaryFixedDim: Color(0xfff4ba9d),
      onTertiaryFixedVariant: Color(0xff230900),
      surfaceDim: Color(0xff181115),
      surfaceBright: Color(0xff574e52),
      surfaceContainerLowest: Color(0xff000000),
      surfaceContainerLow: Color(0xff251e21),
      surfaceContainer: Color(0xff362e32),
      surfaceContainerHigh: Color(0xff42393d),
      surfaceContainerHighest: Color(0xff4d4448),
    );
  }

  ThemeData darkHighContrast() {
    return theme(darkHighContrastScheme());
  }

  ThemeData theme(ColorScheme colorScheme) => ThemeData(
    useMaterial3: true,
    brightness: colorScheme.brightness,
    colorScheme: colorScheme,
    textTheme: textTheme.apply(
      bodyColor: colorScheme.onSurface,
      displayColor: colorScheme.onSurface,
    ),
    scaffoldBackgroundColor: colorScheme.surface,
    canvasColor: colorScheme.surface,
  );

  List<ExtendedColor> get extendedColors => [];
}

class ExtendedColor {
  final Color seed, value;
  final ColorFamily light;
  final ColorFamily lightHighContrast;
  final ColorFamily lightMediumContrast;
  final ColorFamily dark;
  final ColorFamily darkHighContrast;
  final ColorFamily darkMediumContrast;

  const ExtendedColor({
    required this.seed,
    required this.value,
    required this.light,
    required this.lightHighContrast,
    required this.lightMediumContrast,
    required this.dark,
    required this.darkHighContrast,
    required this.darkMediumContrast,
  });
}

class ColorFamily {
  const ColorFamily({
    required this.color,
    required this.onColor,
    required this.colorContainer,
    required this.onColorContainer,
  });

  final Color color;
  final Color onColor;
  final Color colorContainer;
  final Color onColorContainer;
}
