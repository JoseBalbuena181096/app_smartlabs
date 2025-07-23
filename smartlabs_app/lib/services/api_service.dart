import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user_model.dart';

class ApiService {
  static const String baseUrl = 'http://192.168.0.100:3001/api';
  static const Duration defaultTimeout = Duration(seconds: 10);
  static const Duration loanTimeout = Duration(seconds: 15);

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
  
  // Obtener estado de préstamo
  static Future<Map<String, dynamic>> getLoanStatus() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/prestamo/estado'),
        headers: {
          'Content-Type': 'application/json',
          'Connection': 'keep-alive',
        },
      ).timeout(defaultTimeout);

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        print('Estado de préstamo obtenido: $result');
        return result;
      } else {
        print('Error HTTP al obtener estado: ${response.statusCode} - ${response.body}');
        throw Exception('Error al obtener estado de préstamo: ${response.statusCode}');
      }
    } catch (e) {
      print('Excepción en getLoanStatus: $e');
      throw Exception('Error de conexión: $e');
    }
  }

  // Controlar préstamo de herramienta
  static Future<Map<String, dynamic>> controlLoan(String registration, String deviceSerie, int action) async {
    try {
      final requestBody = {
        'registration': registration,
        'device_serie': deviceSerie,
        'action': action,
      };
      
      print('Enviando control de préstamo: $requestBody');
      
      final response = await http.post(
        Uri.parse('$baseUrl/prestamo/control'),
        headers: {
          'Content-Type': 'application/json',
          'Connection': 'keep-alive',
          'Accept': 'application/json',
        },
        body: json.encode(requestBody),
      ).timeout(loanTimeout);

      print('Respuesta del servidor: ${response.statusCode} - ${response.body}');
      
      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        print('Control de préstamo exitoso: $result');
        return result;
      } else {
        print('Error HTTP en control de préstamo: ${response.statusCode}');
        final errorBody = response.body.isNotEmpty ? response.body : 'Sin mensaje de error';
        throw Exception('Error al controlar préstamo: ${response.statusCode} - $errorBody');
      }
    } catch (e) {
      print('Excepción en controlLoan: $e');
      if (e.toString().contains('TimeoutException')) {
        throw Exception('Timeout: El servidor tardó demasiado en responder');
      }
      throw Exception('Error de conexión: $e');
    }
  }

  // Obtener estado del dispositivo
  static Future<Map<String, dynamic>> getDeviceStatus(String deviceSerie) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/devices/$deviceSerie/status'),
        headers: {
          'Content-Type': 'application/json',
          'Connection': 'keep-alive',
        },
      ).timeout(defaultTimeout);

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        print('Estado del dispositivo obtenido: $result');
        return result;
      } else {
        print('Error HTTP al obtener estado del dispositivo: ${response.statusCode}');
        throw Exception('Error al obtener estado del dispositivo: ${response.statusCode}');
      }
    } catch (e) {
      print('Excepción en getDeviceStatus: $e');
      throw Exception('Error de conexión: $e');
    }
  }

  // Controlar dispositivo
  static Future<Map<String, dynamic>> controlDevice(String registration, String deviceSerie, int action) async {
    try {
      final requestBody = {
        'registration': registration,
        'device_serie': deviceSerie,
        'action': action,
      };
      
      print('Enviando control de dispositivo: $requestBody');
      
      final response = await http.post(
        Uri.parse('$baseUrl/devices/control'),
        headers: {
          'Content-Type': 'application/json',
          'Connection': 'keep-alive',
          'Accept': 'application/json',
        },
        body: json.encode(requestBody),
      ).timeout(defaultTimeout);

      print('Respuesta del control de dispositivo: ${response.statusCode} - ${response.body}');
      
      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        print('Control de dispositivo exitoso: $result');
        return result;
      } else {
        print('Error HTTP en control de dispositivo: ${response.statusCode}');
        throw Exception('Error al controlar dispositivo: ${response.statusCode}');
      }
    } catch (e) {
      print('Excepción en controlDevice: $e');
      if (e.toString().contains('TimeoutException')) {
        throw Exception('Timeout: El servidor tardó demasiado en responder');
      }
      throw Exception('Error de conexión: $e');
    }
  }
}