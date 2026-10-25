import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/core/config/api.dart';
import 'package:flutter_application_1/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:flutter_application_1/features/dashboard/data/repositories/dashboard_repository_impl.dart';
import 'package:flutter_application_1/features/devices/data/repositories/devices_repository_impl.dart';
import 'package:flutter_application_1/features/monitoring/data/repositories/energy_repository_impl.dart';
import 'package:flutter_application_1/features/alerts/data/repositories/alerts_repository_impl.dart';
import 'package:flutter_application_1/features/alerts/domain/entities/alert.dart';
import 'package:flutter_application_1/features/analytics/data/repositories/analytics_repository_impl.dart';
import 'package:flutter_application_1/core/utils/demo_seeder.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = null;
  SharedPreferences.setMockInitialValues({});

  test('Flujo completo autenticado contra el backend local', () async {
    print('1. Login con cuenta principal...');
    final auth = await AuthRepositoryImpl.login('colladojeanfabio@gmail.com', 'disenio123');
    expect(auth.token.isNotEmpty, true);
    expect(auth.user.email, 'colladojeanfabio@gmail.com');
    print('   Token OK, User=${auth.user.fullName}');

    await TokenStore.set(auth.token);

    print('2. GetMe...');
    final me = await AuthRepositoryImpl.getMe();
    expect(me.email, 'colladojeanfabio@gmail.com');
    print('   GetMe OK: ${me.id}');

    print('3. Dashboard Summary...');
    final summary = await DashboardRepositoryImpl.getSummary();
    expect(summary.activeDevices >= 0, true);
    print('   Dashboard OK: Devices=${summary.activeDevices}, TotalKwh=${summary.totalKwh}, Proyectado=S/${summary.projectedCost}');

    final readings = await DashboardRepositoryImpl.getRecentReadings();
    expect(readings.isNotEmpty, true);
    print('   Recent Readings OK: ${readings.length} días');

    print('4. Dispositivos...');
    final devices = await DevicesRepositoryImpl.getDevices();
    expect(devices.isNotEmpty, true);
    print('   Dispositivos OK: ${devices.length} dispositivos encontrados');

    print('5. Medidores y Desglose...');
    final meters = await EnergyRepositoryImpl.getMeters();
    expect(meters.isNotEmpty, true);
    print('   Medidores OK: ${meters.length} medidores');

    print('6. Prueba de Impacto de Recomendación de IA en Costo Proyectado...');
    final initialSummary = await DashboardRepositoryImpl.getSummary();
    final recs = await AnalyticsRepositoryImpl.getRecommendations();
    expect(recs.isNotEmpty, true);
    final targetRec = recs.firstWhere((r) => !r.applied, orElse: () => recs.first);

    print('   Recomendación elegida: "${targetRec.title}" (Ahorro: S/${targetRec.estimatedSaving})');
    await AnalyticsRepositoryImpl.applyRecommendation(targetRec.id);

    final updatedSummary = await DashboardRepositoryImpl.getSummary();

    print('   Proyectado inicial: S/${initialSummary.projectedCost.toStringAsFixed(2)} -> Actualizado: S/${updatedSummary.projectedCost.toStringAsFixed(2)}');
    print('   Ahorro inicial: S/${initialSummary.savingAmount.toStringAsFixed(2)} -> Actualizado: S/${updatedSummary.savingAmount.toStringAsFixed(2)}');
    expect(updatedSummary.savingAmount >= initialSummary.savingAmount, true);

    print('7. Prueba de Alerta por Tope/Límite de Consumo en Organización...');
    final prefs = await SharedPreferences.getInstance();
    // Fijar meta menor al consumo actual (ej: 200 kWh vs 382.2 kWh)
    await prefs.setString('consumption_goal_${me.id}', '200');
    final alertsOver = await AlertsRepositoryImpl.getAlerts();
    final hasOverAlert = alertsOver.any((a) => a.id.contains('goal-exceeded') && a.severity == AlertSeverity.critical);
    expect(hasOverAlert, true);
    print('   Alerta de límite superado activada correctamente (Meta 200 kWh < Consumo actual)');

    // Fijar meta muy alta (ej: 2000 kWh)
    await prefs.setString('consumption_goal_${me.id}', '2000');
    final alertsUnder = await AlertsRepositoryImpl.getAlerts();
    final hasOverAlert2 = alertsUnder.any((a) => a.id.contains('goal-exceeded'));
    expect(hasOverAlert2, false);
    print('   Alerta desactivada al elevar meta a 2000 kWh');

    // Restaurar meta normal a 350
    await prefs.setString('consumption_goal_${me.id}', '350');

    print('8. Prueba de Registro con Auto-generación de 4 a 9 Dispositivos al Azar...');
    final randEmail = 'test_user_${DateTime.now().millisecondsSinceEpoch}@sems.com';
    final regResponse = await AuthRepositoryImpl.register(randEmail, 'Password123!', fullName: 'Usuario Aleatorio');
    expect(regResponse.token.isNotEmpty, true);
    await TokenStore.set(regResponse.token);

    print('   Ejecutando DemoSeeder para nuevo usuario: ${regResponse.user.id}...');
    await DemoSeeder.seedData(regResponse.user.id);

    final seededDevices = await DevicesRepositoryImpl.getDevices();
    print('   Dispositivos creados al azar: ${seededDevices.length}');
    expect(seededDevices.length >= 4 && seededDevices.length <= 9, true);

    for (var d in seededDevices) {
      print('     - ${d.deviceName} (${d.deviceType}, ${d.brand} ${d.model}, ${d.connectionProtocol}, ${d.status.name})');
    }

    final seededAlerts = await AlertsRepositoryImpl.getAlerts();
    print('   Alertas creadas al azar: ${seededAlerts.length}');
    expect(seededAlerts.isNotEmpty, true);
    for (var a in seededAlerts) {
      print('     - [${a.severity.name.toUpperCase()}] ${a.title}: ${a.message}');
    }

    print('\n=== ¡TODAS LAS NUEVAS CARACTERÍSTICAS AUTOMÁTICAS FUNCIONAN AL 100%! ===');
  }, timeout: const Timeout(Duration(minutes: 2)));
}
