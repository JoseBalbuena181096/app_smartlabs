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
  bool isToolsMode = false; // true = herramientas, false = equipos
  bool isProcessing = false;
  String? lastScannedCode;
  DateTime? lastScanTime;

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
        // Evitar escaneos duplicados muy rápidos del mismo código
        // pero solo durante el procesamiento, no después de completar una operación
        final now = DateTime.now();
        if (lastScannedCode == scanData.code && 
            lastScanTime != null && 
            now.difference(lastScanTime!).inMilliseconds < 1000) {
          return; // Ignorar si es el mismo código escaneado hace menos de 1 segundo
        }
        
        lastScannedCode = scanData.code;
        lastScanTime = now;
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
    
    // Pausar la cámara inmediatamente para evitar múltiples escaneos
    _pauseCamera();
    
    setState(() {
      isProcessing = true;
    });

    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final user = userProvider.user;

    if (user == null) {
      _showErrorDialog('Error: Usuario no encontrado');
      _resetScanner();
      return;
    }

    try {
      if (isToolsMode) {
        // Modo herramientas - controlar préstamo
        await _handleToolsMode(user, qrCode);
      } else {
        // Modo equipos - controlar dispositivo
        await _handleEquipmentMode(user, qrCode);
      }
    } catch (e) {
      print('Error en _handleQRCode: $e');
      _showErrorDialog('Error de conexión: Verifique su conexión a internet');
      _resetScanner();
    }
    // Removido el finally que causaba doble reset
  }
  
  Future<void> _handleToolsMode(user, String qrCode) async {
    try {
      // Obtener el estado actual de préstamo
      final statusResponse = await ApiService.getLoanStatus().timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw Exception('Timeout al obtener estado de préstamo'),
      );
      
      if (statusResponse['success'] == true) {
        final loanData = statusResponse['data'];
        final sessionActive = loanData['session_active'] as bool;
        // La acción es la inversa del estado de sesión: si hay sesión activa (true) -> devolver (0), si no hay sesión (false) -> prestar (1)
        final action = sessionActive ? 0 : 1;
        final userName = loanData['user'] ?? 'Usuario';
        
        print('QR escaneado: $qrCode');
        print('Estado session_active: $sessionActive');
        print('Acción determinada: $action (${action == 0 ? "Devolución" : "Préstamo"})');
        
        // Mostrar diálogo de confirmación
        _showConfirmationDialog(
          qrCode: qrCode,
          sessionActive: sessionActive,
          action: action,
          userName: userName,
          user: user,
        );
      } else {
        print('Error al obtener estado: ${statusResponse['message']}');
        _showErrorDialog(statusResponse['message'] ?? 'Error al obtener estado de préstamo');
      }
    } catch (e) {
      print('Error en _handleToolsMode: $e');
      rethrow;
    }
  }
  

  Future<void> _handleEquipmentMode(user, String qrCode) async {
    try {
      final statusResponse = await ApiService.getDeviceStatus(qrCode).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw Exception('Timeout al obtener estado del dispositivo'),
      );
      
      if (statusResponse['success'] == true) {
        final deviceData = statusResponse['data'];
        final currentState = deviceData['state'] as bool;
        final newAction = currentState ? 0 : 1;
        final deviceAlias = deviceData['alias'] ?? qrCode;
        
        print('Estado actual del dispositivo $qrCode: ${currentState ? "Encendido" : "Apagado"}, acción a realizar: ${newAction == 1 ? "Encender" : "Apagar"}');
        
        // Mostrar diálogo de confirmación antes de ejecutar la acción
        _showEquipmentConfirmationDialog(
          qrCode: qrCode,
          currentState: currentState,
          action: newAction,
          deviceAlias: deviceAlias,
          user: user,
        );
      } else {
        _showErrorDialog('Error al obtener estado del dispositivo');
      }
    } catch (e) {
      print('Error en _handleEquipmentMode: $e');
      _showErrorDialog('Error de conexión: Verifique su conexión a internet');
      _resetScanner();
    }
  }
  
  void _resetScanner() async {
    // Pausa más larga antes de reactivar el escáner
    await Future.delayed(const Duration(milliseconds: 1000));
    setState(() {
      isProcessing = false;
    });
    // Limpiar el último código escaneado para permitir escanear el mismo código
    // después de completar una operación
    lastScannedCode = null;
    lastScanTime = null;
    _resumeCamera();
  }

  void _showConfirmationDialog({
    required String qrCode,
    required bool sessionActive,
    required int action,
    required String userName,
    required dynamic user,
  }) {
    final actionText = action == 1 ? 'Realizar Préstamo' : 'Realizar Devolución';
    final statusText = sessionActive ? 'Sesión Activa' : 'Sesión Inactiva';
    
    showDialog(
      context: context,
      barrierDismissible: false, // No permitir cerrar tocando fuera
      builder: (context) => AlertDialog(
        title: Text('Confirmar Acción', style: AppTextStyles.h3),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('QR Escaneado:', style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
            Text(qrCode, style: AppTextStyles.bodyMedium),
            const SizedBox(height: 8),
            Text('Estado Actual:', style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
            Text(statusText, style: AppTextStyles.bodyMedium),
            const SizedBox(height: 8),
            Text('Usuario:', style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
            Text(userName, style: AppTextStyles.bodyMedium),
            const SizedBox(height: 16),
            Text('¿Desea $actionText?', style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _resetScanner(); // Reactivar escáner sin ejecutar acción
            },
            child: Text('Cancelar', style: AppTextStyles.buttonSecondary),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _executeControlAction(user, qrCode, action, userName);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.azulTec,
              foregroundColor: AppColors.blanco,
            ),
            child: Text('Aceptar', style: AppTextStyles.button),
          ),
        ],
      ),
    );
  }

  void _showEquipmentConfirmationDialog({
    required String qrCode,
    required bool currentState,
    required int action,
    required String deviceAlias,
    required dynamic user,
  }) {
    final actionText = action == 1 ? 'Encender Equipo' : 'Apagar Equipo';
    final statusText = currentState ? 'Encendido' : 'Apagado';
    
    showDialog(
      context: context,
      barrierDismissible: false, // No permitir cerrar tocando fuera
      builder: (context) => AlertDialog(
        title: Text('Confirmar Acción', style: AppTextStyles.h3),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('QR Escaneado:', style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
            Text(qrCode, style: AppTextStyles.bodyMedium),
            const SizedBox(height: 8),
            Text('Equipo:', style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
            Text(deviceAlias, style: AppTextStyles.bodyMedium),
            const SizedBox(height: 8),
            Text('Estado Actual:', style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
            Text(statusText, style: AppTextStyles.bodyMedium),
            const SizedBox(height: 16),
            Text('¿Desea $actionText?', style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _resetScanner(); // Reactivar escáner sin ejecutar acción
            },
            child: Text('Cancelar', style: AppTextStyles.buttonSecondary),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _executeEquipmentAction(user, qrCode, action, deviceAlias);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.azulTec,
              foregroundColor: AppColors.blanco,
            ),
            child: Text('Aceptar', style: AppTextStyles.button),
          ),
        ],
      ),
    );
  }

  Future<void> _executeControlAction(dynamic user, String qrCode, int action, String userName) async {
    try {
      print('Ejecutando controlLoan - QR: $qrCode, Action: $action, User: ${user.registration}');
      
      // Usar el mismo método para ambas acciones
      final controlResponse = await ApiService.controlLoan(
        user.registration,
        qrCode,
        action,
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () => throw Exception('Timeout al procesar operación'),
      );
      
      print('Respuesta del servidor: $controlResponse');
      
      if (controlResponse['success'] == true) {
        final actionText = action == 1 ? 'Préstamo realizado' : 'Devolución realizada';
        
        print('Operación exitosa: $actionText');
        
        _showSuccessDialog(
          'Control de Herramienta',
          '$actionText\nUsuario: $userName',
        );
      } else {
        print('Error en operación: ${controlResponse['message']}');
        _showErrorDialog(controlResponse['message'] ?? 'Error al controlar préstamo');
      }
    } catch (e) {
      print('Error en _executeControlAction: $e');
      _showErrorDialog('Error de conexión: Verifique su conexión a internet');
    } finally {
      _resetScanner();
    }
  }

  Future<void> _executeEquipmentAction(dynamic user, String qrCode, int action, String deviceAlias) async {
    try {
      final controlResponse = await ApiService.controlDevice(
        user.registration,
        qrCode,
        action,
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw Exception('Timeout al controlar dispositivo'),
      );
      
      if (controlResponse['success'] == true) {
        final actionText = action == 1 ? 'Equipo encendido' : 'Equipo apagado';
        final newStatus = action == 1 ? 'Encendido' : 'Apagado';
        
        print('Operación exitosa: $actionText');
        
        _showSuccessDialog(
          'Control de Equipo',
          '$deviceAlias\nEstado: $newStatus',
        );
      } else {
        print('Error en operación: ${controlResponse['message']}');
        _showErrorDialog(controlResponse['message'] ?? 'Error al controlar equipo');
      }
    } catch (e) {
      print('Error en _executeEquipmentAction: $e');
      _showErrorDialog('Error de conexión: Verifique su conexión a internet');
    } finally {
      _resetScanner();
    }
  }

  void _showSuccessDialog(String title, [String? message]) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title, style: AppTextStyles.h3),
        content: message != null ? Text(message, style: AppTextStyles.bodyMedium) : null,
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
                      'Equipos',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: !isToolsMode ? AppColors.azulTec : AppColors.textoSecundario,
                        fontWeight: !isToolsMode ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Switch(
                      value: isToolsMode,
                      onChanged: (value) {
                        setState(() {
                          isToolsMode = value;
                        });
                      },
                      activeColor: AppColors.azulTec,
                      inactiveThumbColor: AppColors.azulTec,
                      inactiveTrackColor: AppColors.azulTec.withOpacity(0.3),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      'Herramientas',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: isToolsMode ? AppColors.azulTec : AppColors.textoSecundario,
                        fontWeight: isToolsMode ? FontWeight.w600 : FontWeight.w400,
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