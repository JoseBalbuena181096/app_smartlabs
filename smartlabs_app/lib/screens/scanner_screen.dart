import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_code_scanner_plus/qr_code_scanner_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import '../providers/user_provider.dart';
import '../services/api_service.dart';
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
    await Future.delayed(const Duration(milliseconds: 500));
    await controller?.resumeCamera();
  }

  Future<void> _handleQRCode(String qrCode) async {
    if (isProcessing) return;
    
    setState(() {
      isProcessing = true;
    });
    
    // Pausar la cámara para evitar múltiples escaneos
    _pauseCamera();

    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final user = userProvider.user;

    if (user == null) {
      _showErrorDialog('Error: Usuario no encontrado');
      setState(() {
        isProcessing = false;
      });
      _restartScanner();
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
      // Esperar un poco antes de permitir otro escaneo
      await Future.delayed(const Duration(seconds: 2));
      setState(() {
        isProcessing = false;
      });
      // Reiniciar completamente el scanner para permitir nuevos escaneos
      _restartScanner();
    }
  }

  void _showSuccessDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
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
        title: const Text('SmartLabs Scanner'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: Consumer<UserProvider>(
        builder: (context, userProvider, child) {
          final user = userProvider.user;
          
          if (user == null) {
            return const Center(
              child: Text('Error: Usuario no encontrado'),
            );
          }

          return Column(
            children: [
              // Información del usuario
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                color: Colors.blue[50],
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bienvenido, ${user.name}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Correo: ${user.email}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                    Text(
                      'Matrícula: ${user.registration}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Switch para modo
              Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Herramientas',
                      style: TextStyle(fontSize: 16),
                    ),
                    const SizedBox(width: 16),
                    Switch(
                      value: !isToolsMode,
                      onChanged: (value) {
                        setState(() {
                          isToolsMode = !value;
                        });
                      },
                      activeColor: Colors.blue[600],
                    ),
                    const SizedBox(width: 16),
                    const Text(
                      'Equipos',
                      style: TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
              
              // Indicador de modo actual
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  'Modo actual: ${isToolsMode ? "Herramientas" : "Equipos"}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[600],
                  ),
                ),
              ),
              
              // Escáner QR
              Expanded(
                child: Container(
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue, width: 2),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Stack(
                      children: [
                        QRView(
                          key: qrKey,
                          onQRViewCreated: _onQRViewCreated,
                          overlay: QrScannerOverlayShape(
                            borderColor: Colors.white,
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
                                        Colors.red,
                                        Colors.red,
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
                child: Text(
                  isProcessing
                      ? 'Procesando...'
                      : 'Apunta la cámara hacia un código QR para escanearlo',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
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