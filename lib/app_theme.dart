import 'package:flutter/material.dart';

/// A quiet field journal: paper, ink, forest and a little clay.
abstract final class AppPalette {
  static const paper = Color(0xFFF4F1E9);
  static const surface = Color(0xFFFFFDF8);
  static const ink = Color(0xFF263B33);
  static const forest = Color(0xFF335C49);
  static const sage = Color(0xFFE3E9DD);
  static const clay = Color(0xFFA04F36);
  static const blush = Color(0xFFF0E1D6);
  static const gold = Color(0xFFECE2BC);
  static const muted = Color(0xFF657168);
  static const line = Color(0xFFD6D9CE);
}

ThemeData buildAppTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: AppPalette.forest,
    primary: AppPalette.forest,
    onPrimary: AppPalette.surface,
    primaryContainer: AppPalette.sage,
    onPrimaryContainer: AppPalette.ink,
    secondary: AppPalette.clay,
    secondaryContainer: AppPalette.blush,
    surface: AppPalette.surface,
    onSurface: AppPalette.ink,
    onSurfaceVariant: AppPalette.muted,
    outline: AppPalette.muted,
    outlineVariant: AppPalette.line,
  );
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    fontFamily: 'Roboto',
  );
  final text = base.textTheme.apply(
    bodyColor: AppPalette.ink,
    displayColor: AppPalette.ink,
  );
  final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(14));
  final border = OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: const BorderSide(color: AppPalette.line),
  );
  return base.copyWith(
    scaffoldBackgroundColor: AppPalette.paper,
    textTheme: text.copyWith(
      headlineLarge: const TextStyle(
        fontFamily: 'Georgia',
        fontFamilyFallback: ['serif'],
        fontSize: 36,
        height: 1.15,
        color: AppPalette.ink,
      ),
      headlineSmall: const TextStyle(
        fontFamily: 'Georgia',
        fontFamilyFallback: ['serif'],
        fontSize: 28,
        height: 1.2,
        color: AppPalette.ink,
      ),
      titleLarge: text.titleLarge?.copyWith(
        fontWeight: FontWeight.w600,
        letterSpacing: -0.5,
      ),
      bodyLarge: text.bodyLarge?.copyWith(height: 1.45),
      bodyMedium: text.bodyMedium?.copyWith(height: 1.4),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppPalette.paper,
      foregroundColor: AppPalette.ink,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontFamily: 'Roboto',
        color: AppPalette.ink,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
    ),
    cardTheme: CardThemeData(
      color: AppPalette.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppPalette.line),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppPalette.surface,
      border: border,
      enabledBorder: border,
      focusedBorder: border.copyWith(
        borderSide: const BorderSide(color: AppPalette.forest, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      labelStyle: const TextStyle(
        fontFamily: 'Roboto',
        color: AppPalette.muted,
      ),
      hintStyle: const TextStyle(
        fontFamily: 'Roboto',
        color: AppPalette.muted,
        fontWeight: FontWeight.normal,
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(48, 48),
        shape: shape,
        textStyle: const TextStyle(
          fontFamily: 'Roboto',
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppPalette.forest,
        foregroundColor: AppPalette.surface,
        minimumSize: const Size(48, 48),
        elevation: 0,
        shape: shape,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppPalette.ink,
        minimumSize: const Size(48, 48),
        side: const BorderSide(color: AppPalette.line),
        shape: shape,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
    ),
    chipTheme: base.chipTheme.copyWith(
      backgroundColor: AppPalette.surface,
      selectedColor: AppPalette.sage,
      side: const BorderSide(color: AppPalette.line),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      labelStyle: const TextStyle(
        fontFamily: 'Roboto',
        color: AppPalette.ink,
        fontSize: 13,
      ),
    ),
    dividerTheme: const DividerThemeData(color: AppPalette.line, thickness: 1),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppPalette.paper,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: AppPalette.surface,
      surfaceTintColor: Colors.transparent,
      shape: shape,
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: AppPalette.surface,
      surfaceTintColor: Colors.transparent,
      shape: shape,
    ),
    listTileTheme: const ListTileThemeData(
      iconColor: AppPalette.forest,
      textColor: AppPalette.ink,
    ),
    expansionTileTheme: const ExpansionTileThemeData(
      iconColor: AppPalette.forest,
      textColor: AppPalette.ink,
      collapsedIconColor: AppPalette.forest,
    ),
  );
}
