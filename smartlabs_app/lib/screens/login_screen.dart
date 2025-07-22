import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../providers/user_provider.dart';
import '../services/api_service.dart';
import '../models/user_model.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
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
        title: Text('Error', style: AppTextStyles.h3),
        content: Text(message, style: AppTextStyles.bodyMedium),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('OK', style: AppTextStyles.buttonSecondary),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.fondoClaro,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo SmartLabs
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.blanco,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.azulTec.withOpacity(0.1),
                      spreadRadius: 2,
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: SvgPicture.asset(
                  'assets/images/smartlabs.svg',
                  width: 120,
                  height: 80,
                ),
              ),
              const SizedBox(height: 32),
              
              Text(
                'SmartLabs',
                style: AppTextStyles.h1Azul,
              ),
              const SizedBox(height: 8),
              
              Text(
                'Ingresa tu matrícula para acceder',
                style: AppTextStyles.subtitle,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              
              // Campo de matrícula
              TextField(
                controller: _registrationController,
                style: AppTextStyles.textField,
                decoration: InputDecoration(
                  labelText: 'Matrícula',
                  labelStyle: AppTextStyles.textFieldLabel,
                  hintText: 'Ej: A01234567',
                  hintStyle: AppTextStyles.textField.copyWith(color: AppColors.textoSecundario),
                  prefixIcon: Icon(Icons.person, color: AppColors.azulTec),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.bordePrimario),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.bordePrimario),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.azulTec, width: 2),
                  ),
                  filled: true,
                  fillColor: AppColors.blanco,
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
                    backgroundColor: AppColors.azulTec,
                    foregroundColor: AppColors.blanco,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: _isLoading
                      ? CircularProgressIndicator(color: AppColors.blanco)
                      : Text(
                          'Acceder',
                          style: AppTextStyles.button,
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