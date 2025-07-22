import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_code_scanner_plus/qr_code_scanner_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import '../providers/user_provider.dart';
import '../services/api_service.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import 'login_screen.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  QRViewController? controller;
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  bool isToolsMode = true; // true = herramientas, false = equipos
  bool isProcessing = false;

  @override
  void initState() {
    super.initState();
    _requestCameraPermission();
  }

  Future<void> _requestCameraPermission() async {
    final status = await Permission.camera.request();
    if (status.isDenied) {
      _showErrorDialog('Se requiere permiso de cámara para escanear códigos QR');
    }
  }

  void _onQRViewCreated(QRViewController controller) {
    this.controller = controller;
    _setupScannerStream();
  }

  void _setupScannerStream() {
    controller?.scannedDataStream.listen((scanData) {
      if (!isProcessing && scanData.code != null) {
        _handleQRCode(scanData.code!);
      }
    });
  }

  void _pauseCamera() {
    controller?.pauseCamera();
  }

  void _resumeCamera() {
    controller?.resumeCamera();
  }

  void _restartScanner() async {
    await controller?.stopCamera();
    await Future.delayed(const Duration(milliseconds: 200));
    await controller?.resumeCamera();
  }

  Future<void> _handleQRCode(String qrCode) async {
    if (isProcessing) return;
    
    setState(() {
      isProcessing = true;
    });

    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final user = userProvider.user;

    if (user == null) {
      _showErrorDialog('Error: Usuario no encontrado');
      setState(() {
        isProcessing = false;
      });
      return;
    }

    try {
      if (isToolsMode) {
        // Modo herramientas - simular préstamo
        final response = await ApiService.simulateLoan(user.registration, qrCode);
        _showSuccessDialog('Préstamo simulado', response['message'] ?? 'Operación exitosa');
      } else {
        // Modo equipos - controlar dispositivo
        final statusResponse = await ApiService.getDeviceStatus(qrCode);
        
        if (statusResponse['success'] == true) {
          final deviceData = statusResponse['data'];
          final currentState = deviceData['state'] as bool;
          final newAction = currentState ? 0 : 1; // Invertir estado
          
          final controlResponse = await ApiService.controlDevice(
            user.registration,
            qrCode,
            newAction,
          );
          
          final deviceAlias = deviceData['device_alias'] ?? 'Dispositivo';
          final newStatus = newAction == 1 ? 'Encendido' : 'Apagado';
          
          _showSuccessDialog(
            'Control de Equipo',
            '$deviceAlias\nEstado: $newStatus',
          );
        } else {
          _showErrorDialog('Error al obtener estado del dispositivo');
        }
      }
    } catch (e) {
      _showErrorDialog('Error: $e');
    } finally {
      // Breve pausa antes de permitir otro escaneo
      await Future.delayed(const Duration(milliseconds: 500));
      setState(() {
        isProcessing = false;
      });
    }
  }

  void _showSuccessDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title, style: AppTextStyles.h3),
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

  void _logout() {
    Provider.of<UserProvider>(context, listen: false).logout();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('SmartLabs Scanner', style: AppTextStyles.appBarTitle),
        backgroundColor: AppColors.azulTec,
        foregroundColor: AppColors.blanco,
        elevation: 2,
        actions: [
          IconButton(
            icon: Icon(Icons.logout, color: AppColors.blanco),
            onPressed: _logout,
          ),
        ],
      ),
      body: Consumer<UserProvider>(
        builder: (context, userProvider, child) {
          final user = userProvider.user;
          
          if (user == null) {
            return Center(
              child: Text(
                'Error: Usuario no encontrado',
                style: AppTextStyles.error,
              ),
            );
          }

          return Column(
            children: [
              // Información del usuario
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.fondoClaro,
                  border: Border(
                    bottom: BorderSide(
                      color: AppColors.bordePrimario,
                      width: 1,
                    ),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bienvenido, ${user.name}',
                      style: AppTextStyles.h3,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Correo: ${user.email}',
                      style: AppTextStyles.bodySmall,
                    ),
                    Text(
                      'Matrícula: ${user.registration}',
                      style: AppTextStyles.bodySmall,
                    ),
                  ],
                ),
              ),
              
              // Switch para modo
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.blanco,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Herramientas',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: isToolsMode ? AppColors.azulTec : AppColors.textoSecundario,
                        fontWeight: isToolsMode ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Switch(
                      value: !isToolsMode,
                      onChanged: (value) {
                        setState(() {
                          isToolsMode = !value;
                        });
                      },
                      activeColor: AppColors.azulTec,
                      inactiveThumbColor: AppColors.azulTec,
                      inactiveTrackColor: AppColors.azulTec.withOpacity(0.3),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      'Equipos',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: !isToolsMode ? AppColors.azulTec : AppColors.textoSecundario,
                        fontWeight: !isToolsMode ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Indicador de modo actual
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.azulTec.withOpacity(0.1),
                ),
                child: Center(
                  child: Text(
                    'Modo actual: ${isToolsMode ? "Herramientas" : "Equipos"}',
                    style: AppTextStyles.bodyBold.copyWith(
                      color: AppColors.azulTec,
                    ),
                  ),
                ),
              ),
              
              // Escáner QR
              Expanded(
                child: Container(
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.azulTec, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.azulTec.withOpacity(0.1),
                        spreadRadius: 2,
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Stack(
                      children: [
                        QRView(
                          key: qrKey,
                          onQRViewCreated: _onQRViewCreated,
                          overlay: QrScannerOverlayShape(
                            borderColor: AppColors.blanco,
                            borderRadius: 10,
                            borderLength: 30,
                            borderWidth: 4,
                            cutOutSize: 250,
                          ),
                        ),
                        // Línea de escaneo adicional
                        if (!isProcessing)
                          Center(
                            child: Container(
                              width: 250,
                              height: 250,
                              child: Positioned(
                                top: 125,
                                left: 10,
                                right: 10,
                                child: Container(
                                  height: 2,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.transparent,
                                        AppColors.azulTec,
                                        AppColors.azulTec,
                                        Colors.transparent,
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              
              // Instrucciones
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.blanco,
                ),
                child: Text(
                  isProcessing
                      ? 'Procesando...'
                      : 'Apunta la cámara hacia un código QR para escanearlo',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: isProcessing ? AppColors.azulTec : AppColors.textoSecundario,
                    fontWeight: isProcessing ? FontWeight.w600 : FontWeight.w400,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }
}