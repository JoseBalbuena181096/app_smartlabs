import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user_model.dart';

class ApiService {
  static const String baseUrl = 'http://192.168.0.100:3001/api';

  // Login del usuario por matrícula
  static Future<Map<String, dynamic>> getUserByRegistration(String registration) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/users/registration/$registration'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Error al obtener usuario: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // Simular préstamo de herramienta
  static Future<Map<String, dynamic>> simulateLoan(String registration, String deviceSerie) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/prestamo/simular'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'registration': registration,
          'device_serie': deviceSerie,
        }),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Error al simular préstamo: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // Obtener estado del dispositivo
  static Future<Map<String, dynamic>> getDeviceStatus(String deviceSerie) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/devices/$deviceSerie/status'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Error al obtener estado del dispositivo: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // Controlar dispositivo
  static Future<Map<String, dynamic>> controlDevice(String registration, String deviceSerie, int action) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/devices/control'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'registration': registration,
          'device_serie': deviceSerie,
          'action': action,
        }),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Error al controlar dispositivo: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }
}