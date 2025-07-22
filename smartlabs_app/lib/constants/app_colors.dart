import 'package:flutter/material.dart';

/// Constantes de colores basadas en el Bamboo Design System del Tecnológico de Monterrey
class AppColors {
  // Colores Institucionales Primarios
  static const Color azulTec = Color(0xFF0039A6);
  static const Color negro = Color(0xFF000000);
  static const Color blanco = Color(0xFFFFFFFF);

  // Gama de Grises y Azules
  static const Color grisOscuro = Color(0xFF292D34); // Charade
  static const Color azulSecundario = Color(0xFF2D69E3); // Mariner

  // Colores de Acento
  static const Color rojoAcento = Color(0xFF8D0E3F);
  static const Color naranjaAcento = Color(0xFFBB4C02);
  static const Color verdeAcento = Color(0xFF485116);
  static const Color moradoAcento = Color(0xFFA12780);

  // Colores adicionales para UI
  static const Color fondoPrimario = Color(0xFFF8F9FA);
  static const Color fondoSecundario = Color(0xFFE9ECEF);
  static const Color fondoClaro = Color(0xFFF0F8FF); // Azul muy claro
  static const Color textoSecundario = Color(0xFF6C757D);
  static const Color divider = Color(0xFFDEE2E6);
  static const Color bordePrimario = Color(0xFFDEE2E6);

  // Colores para estados
  static const Color success = verdeAcento;
  static const Color error = rojoAcento;
  static const Color warning = naranjaAcento;
  static const Color info = azulSecundario;
}