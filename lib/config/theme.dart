import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

final cherryLightTheme = ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(
    seedColor: const Color(0xFFD74248),
    brightness: Brightness.light,
    primary: const Color(0xFF333333),
    secondary: const Color(0xFFD74248),
    surface: Colors.white,
  ),
  cardColor: const Color.fromARGB(255, 230, 230, 230),
  textTheme: TextTheme(
    displayLarge: GoogleFonts.inter(
      fontSize: 72,
      fontWeight: FontWeight.bold,
      color: Colors.black,
    ),
    titleLarge: GoogleFonts.inter(
      fontSize: 21,
      fontWeight: FontWeight.bold,
      color: Colors.black,
    ),
    bodyMedium: GoogleFonts.inter(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: Colors.black,
      letterSpacing: -0.5,
    ),
    displaySmall: GoogleFonts.inter(),
    headlineSmall: GoogleFonts.inter(
      fontSize: 22,
      fontWeight: FontWeight.w700,
      color: Colors.black87,
      letterSpacing: -0.7,
    ),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFFD74248),
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      minimumSize: const Size(double.infinity, 50),
      side: const BorderSide(color: Color(0xFFD74248), width: 2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
    ),
  ),
  scaffoldBackgroundColor: Colors.white,
  canvasColor: Colors.white,
  iconTheme: const IconThemeData(color: Colors.black),
);

final cherryDarkTheme = ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(
    seedColor: const Color(0xFFD74248),
    brightness: Brightness.dark,
    primary: Colors.white,
    secondary: const Color(0xFFD74248),
    surface: const Color(0xFF181818),
  ),
  cardColor: const Color.fromARGB(255, 69, 69, 69),
  textTheme: TextTheme(
    displayLarge: GoogleFonts.inter(
      fontSize: 72,
      fontWeight: FontWeight.bold,
    ),
    titleLarge: GoogleFonts.inter(
      fontSize: 20,
      fontWeight: FontWeight.bold,
      color: Colors.white, // Ensure this is white for dark theme
    ),
    bodyMedium: GoogleFonts.inter(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: Colors.white,
      letterSpacing: -0.5,
    ),
    displaySmall: GoogleFonts.inter(),
    headlineSmall: GoogleFonts.inter(
      fontSize: 22,
      fontWeight: FontWeight.w700,
      color: Colors.white,
      letterSpacing: -0.7,
    ),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFFD74248),
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      minimumSize: const Size(double.infinity, 50),
      side: const BorderSide(color: Color(0xFFD74248), width: 2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
    ),
  ),
  scaffoldBackgroundColor: const Color(0xFF181818),
  canvasColor: const Color(0xFF181818),
  iconTheme: const IconThemeData(color: Colors.white),
);
