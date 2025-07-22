import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Estilos de texto basados en el Bamboo Design System del Tecnológico de Monterrey
class AppTextStyles {
  // Encabezados Principales (H1, Títulos de pantalla)
  static TextStyle get h1 => GoogleFonts.poppins(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: AppColors.negro,
      );

  static TextStyle get h1White => GoogleFonts.poppins(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: AppColors.blanco,
      );

  static TextStyle get h1Azul => GoogleFonts.poppins(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: AppColors.azulTec,
      );

  // Subtítulos y Etiquetas (H2, H3)
  static TextStyle get h2 => GoogleFonts.poppins(
        fontSize: 24,
        fontWeight: FontWeight.w600, // SemiBold
        color: AppColors.negro,
      );

  static TextStyle get h3 => GoogleFonts.poppins(
        fontSize: 20,
        fontWeight: FontWeight.w500, // Medium
        color: AppColors.negro,
      );

  static TextStyle get subtitle => GoogleFonts.poppins(
        fontSize: 18,
        fontWeight: FontWeight.w400, // Regular
        color: AppColors.grisOscuro,
      );

  // Cuerpo de Texto (Párrafos, descripciones)
  static TextStyle get bodyLarge => GoogleFonts.poppins(
        fontSize: 16,
        fontWeight: FontWeight.w400, // Regular
        color: AppColors.negro,
      );

  static TextStyle get bodyMedium => GoogleFonts.poppins(
        fontSize: 14,
        fontWeight: FontWeight.w400, // Regular
        color: AppColors.negro,
      );

  static TextStyle get bodySmall => GoogleFonts.poppins(
        fontSize: 12,
        fontWeight: FontWeight.w400, // Regular
        color: AppColors.textoSecundario,
      );

  // Texto con énfasis
  static TextStyle get bodyBold => GoogleFonts.poppins(
        fontSize: 16,
        fontWeight: FontWeight.w600, // SemiBold
        color: AppColors.negro,
      );

  // Estilos para botones
  static TextStyle get button => GoogleFonts.poppins(
        fontSize: 16,
        fontWeight: FontWeight.w600, // SemiBold
        color: AppColors.blanco,
      );

  static TextStyle get buttonSecondary => GoogleFonts.poppins(
        fontSize: 16,
        fontWeight: FontWeight.w600, // SemiBold
        color: AppColors.azulTec,
      );

  // Estilos para campos de texto
  static TextStyle get textField => GoogleFonts.poppins(
        fontSize: 16,
        fontWeight: FontWeight.w400, // Regular
        color: AppColors.negro,
      );

  static TextStyle get textFieldLabel => GoogleFonts.poppins(
        fontSize: 14,
        fontWeight: FontWeight.w500, // Medium
        color: AppColors.grisOscuro,
      );

  // Estilos para navegación
  static TextStyle get appBarTitle => GoogleFonts.poppins(
        fontSize: 20,
        fontWeight: FontWeight.w600, // SemiBold
        color: AppColors.blanco,
      );

  // Estilos para estados de error
  static TextStyle get error => GoogleFonts.poppins(
        fontSize: 14,
        fontWeight: FontWeight.w400, // Regular
        color: AppColors.error,
      );

  // Estilos para estados de éxito
  static TextStyle get success => GoogleFonts.poppins(
        fontSize: 14,
        fontWeight: FontWeight.w400, // Regular
        color: AppColors.success,
      );
}