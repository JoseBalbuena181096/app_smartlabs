import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../services/api_service.dart';
import '../models/user_model.dart';
import 'scanner_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _registrationController = TextEditingController();
  bool _isLoading = false;

  Future<void> _login() async {
    if (_registrationController.text.trim().isEmpty) {
      _showErrorDialog('Por favor ingresa tu matrícula');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await ApiService.getUserByRegistration(_registrationController.text.trim());
      
      if (response['success'] == true) {
        final user = UserModel.fromJson(response['data']);
        
        if (mounted) {
          Provider.of<UserProvider>(context, listen: false).setUser(user);
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const ScannerScreen()),
          );
        }
      } else {
        _showErrorDialog(response['message'] ?? 'Error al iniciar sesión');
      }
    } catch (e) {
      _showErrorDialog('Error de conexión: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue[50],
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo o título
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.blue[600],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.science,
                  size: 80,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 32),
              
              const Text(
                'SmartLabs',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(height: 8),
              
              const Text(
                'Ingresa tu matrícula para acceder',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              
              // Campo de matrícula
              TextField(
                controller: _registrationController,
                decoration: InputDecoration(
                  labelText: 'Matrícula',
                  hintText: 'Ej: A01234567',
                  prefixIcon: const Icon(Icons.person),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                textCapitalization: TextCapitalization.characters,
                onSubmitted: (_) => _login(),
              ),
              const SizedBox(height: 24),
              
              // Botón de acceso
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[600],
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Acceder',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _registrationController.dispose();
    super.dispose();
  }
}