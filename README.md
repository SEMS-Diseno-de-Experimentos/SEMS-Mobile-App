# SEMS - Mobile Application ⚡

Aplicación móvil oficial de **SEMS (Smart Energy Management System)** desarrollada en **Flutter**, diseñada para la gestión, optimización y telemetría de energía inteligente para cadenas de retail y establecimientos comerciales.

---

## 📱 Tecnologías y Arquitectura

La aplicación está construida siguiendo los principios de **Clean Architecture** y **Domain-Driven Design (DDD)**:

- **Framework**: [Flutter](https://flutter.dev) (Multiplataforma: Android, iOS, Web y Escritorio).
- **Gestión de Estado**: `Provider` + `ValueNotifier` reactivo para sincronización instantánea.
- **Enrutamiento**: `go_router` con guardas de autenticación (RBAC) y redirección automática.
- **Cliente HTTP**: `dio` con interceptores para inyección de JWT, manejo de errores y limpieza de sesión en 401.
- **Gráficos y Visualización**: `fl_chart` para curvas de potencia activa, demanda y consumo acumulado en 14 días.
- **Diseño & UI**: Sistema de diseño basado en Tailwind/Sora typography con modo oscuro dinámico y soporte bilingüe (ES / EN).

### Estructura de Capas

```
lib/
├── core/
│   ├── config/       # API cliente Dio, rutas GoRouter, tema y paleta de colores
│   ├── layout/       # AppShell, Drawer, BottomNavigationBar y Responsive Scaffold
│   ├── providers/    # LanguageProvider (ES/EN) y ThemeProvider
│   ├── utils/        # DemoSeeder para aprovisionamiento aleatorio de dispositivos IoT
│   └── widgets/      # SemsButton, SemsCard, SemsBadge, KPI Cards, gráficos
└── features/
    ├── auth/          # Identidad: Login, Register, Forgot Password, Reset y Verify
    ├── dashboard/     # Resumen general: KPIs de costo/kWh, anomalías y proyección
    ├── devices/       # Gestión de dispositivos IoT (WiFi, Zigbee, Matter, Bluetooth)
    ├── monitoring/    # Medidores inteligentes, telemetría y escáner QR
    ├── analytics/     # Predicciones de factura, recomendaciones de IA y reportes
    ├── alerts/        # Alertas de consumo, tope mensual de organización y estados
    ├── subscriptions/ # Planes Pro, suscripción activa y facturación
    └── settings/      # Mi Organización (Tope kWh/mes, tarifa eléctrica) y perfil
```

---

## ✨ Características Principales

1. **Autenticación y Registro Resiliente**:
   - Soporte para cuentas administrativas y de personal.
   - Aprovisionamiento automático al registrarse de **4 a 9 dispositivos IoT al azar** con marcas y configuraciones reales.
2. **Dashboard & KPIs en Tiempo Real**:
   - Consumo del mes (kWh y S/), Costo estimado actual y Costo Proyectado a fin de mes.
   - Curva de consumo histórico de los últimos 14 días.
   - Tarjetas de anomalías prioritarias (*Requieren atención*).
3. **Recomendaciones de IA con Impacto Inmediato**:
   - Visualización de ahorros estimados mensuales (ej. S/ 7.00, S/ 15.50, S/ 25.00).
   - Al pulsar **Aplicar**, el ahorro se descuenta instantáneamente del Costo Proyectado en el Dashboard mediante sincronización reactiva.
4. **Tope de Consumo de Organización y Alertas**:
   - Configuración de límite mensual en **Mi Organización**.
   - Evaluación continua en base al consumo real medido: si el consumo acumulado supera el límite, se dispara de inmediato una alerta crítica de sobrecosto.
5. **Modo Bilingüe**:
   - Cambio fluido en tiempo real entre **Español** e **Inglés**.

---

## 🚀 Puesta en Marcha Local

### Prerrequisitos
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (versión 3.24 o superior).
- Backend de SEMS corriendo en `http://localhost:8080`.

### 1. Clonar e Instalar Dependencias
```bash
git clone https://github.com/SEMS-Diseno-de-Experimentos/SEMS-Mobile-App.git
cd SEMS-Mobile-App
flutter pub get
```

### 2. Configurar Variables de Entorno
Crea un archivo `.env` en la raíz de `mobile/`:
```bash
cp .env.example .env
```
Contenido de `.env`:
```env
API_URL=http://localhost:8080
```

### 3. Ejecutar la Aplicación

- **En Navegador Chrome / Web**:
  ```bash
  flutter run -d chrome --web-port=5000
  ```
- **En Emulador Android**:
  ```bash
  flutter run -d android
  ```

---

## 🧪 Pruebas Automatizadas

Para ejecutar la suite de pruebas unitarias y de integración de flujo completo:
```bash
flutter test test/flow_test.dart
```

---

## 👥 Integrantes del Equipo (Organización)

- **Jean Fabio Noriega Collado** (`dumbaskidd`) - *Lead Mobile Developer*
- **Alexis Encalada Salazar** (`Alexiz248`)
- **Elias Daniel Ramos Cerdan** (`eliocerdan`)
- **Winnie Merino** (`winniemerino`)
- **Nelson Romero** (`nes-ro`)
