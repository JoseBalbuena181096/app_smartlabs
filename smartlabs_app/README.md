# SmartLabs App

Aplicación Flutter para el sistema SmartLabs que permite el login de usuarios y control de dispositivos/herramientas mediante códigos QR.

## Características

- **Login por matrícula**: Los usuarios pueden acceder ingresando su matrícula estudiantil
- **Escáner QR**: Cámara integrada para escanear códigos QR de dispositivos y herramientas
- **Dos modos de operación**:
  - **Herramientas**: Simula préstamos de herramientas
  - **Equipos**: Controla el estado (encendido/apagado) de equipos
- **Estado global**: Mantiene la información del usuario durante toda la sesión

## Flujo de trabajo

### 1. Login
- El usuario ingresa su matrícula en el campo de texto
- Al presionar "Acceder", se realiza una consulta GET a: `http://192.168.0.100:3001/api/users/registration/{MATRICULA}`
- Si el usuario existe, se guarda en el estado global y se navega a la pantalla principal

### 2. Pantalla Principal
- Muestra información del usuario (nombre, correo, matrícula)
- Switch para alternar entre modo "Herramientas" y "Equipos"
- Escáner QR activo para leer códigos

### 3. Modo Herramientas
- Al escanear un QR (ej: SMART10003), se envía POST a: `http://192.168.0.100:3001/api/prestamo/simular`
- Body: `{"registration": "A01736214", "device_serie": "SMART10003"}`
- Simula el préstamo de la herramienta

### 4. Modo Equipos
- Al escanear un QR (ej: SMART00005):
  1. GET a: `http://192.168.0.100:3001/api/devices/SMART00005/status`
  2. Obtiene el estado actual del dispositivo
  3. Invierte el estado (false → 1, true → 0)
  4. POST a: `http://192.168.0.100:3001/api/devices/control`
  5. Body: `{"registration": "L03533767", "device_serie": "SMART00005", "action": 0}`

## Estructura del Proyecto

```
lib/
├── models/
│   └── user_model.dart          # Modelo de datos del usuario
├── providers/
│   └── user_provider.dart       # Provider para estado global
├── screens/
│   ├── login_screen.dart        # Pantalla de login
│   └── scanner_screen.dart      # Pantalla principal con escáner
├── services/
│   └── api_service.dart         # Servicio para peticiones HTTP
└── main.dart                    # Punto de entrada de la aplicación
```

## Dependencias

- `http`: Para peticiones HTTP a la API
- `qr_code_scanner`: Para escanear códigos QR
- `provider`: Para manejo de estado global
- `permission_handler`: Para permisos de cámara

## Instalación y Ejecución

1. Asegúrate de tener Flutter instalado
2. Clona o descarga el proyecto
3. Ejecuta `flutter pub get` para instalar dependencias
4. Para web: `flutter run -d chrome`
5. Para Android: `flutter run` (requiere dispositivo/emulador)

## Permisos

### Android
- Cámara: Para escanear códigos QR
- Internet: Para comunicación con la API

### Web
- Cámara: Se solicita automáticamente al usar el escáner

## API Endpoints

- **Login**: `GET /api/users/registration/{matricula}`
- **Simular préstamo**: `POST /api/prestamo/simular`
- **Estado dispositivo**: `GET /api/devices/{serie}/status`
- **Control dispositivo**: `POST /api/devices/control`

## Notas

- La aplicación está configurada para conectarse a `http://192.168.0.100:3001`
- Para desarrollo en web, el escáner QR funciona con la cámara del dispositivo
- El estado del usuario se mantiene durante toda la sesión
- Incluye manejo de errores y diálogos informativos
