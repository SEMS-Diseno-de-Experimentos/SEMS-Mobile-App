import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_application_1/core/providers/language_provider.dart';
import 'package:flutter_application_1/features/devices/data/repositories/devices_repository_impl.dart';
import 'package:flutter_application_1/features/devices/domain/entities/device.dart';
import 'package:flutter_application_1/core/widgets/sems_card.dart';
import 'package:flutter_application_1/core/widgets/sems_badge.dart';
import 'package:flutter_application_1/core/widgets/sems_button.dart';
import 'package:flutter_application_1/core/widgets/loading_widget.dart';
import 'package:flutter_application_1/core/widgets/error_widget.dart';
import 'package:flutter_application_1/core/config/theme.dart';

class DevicesScreen extends StatefulWidget {
  const DevicesScreen({super.key});

  @override
  State<DevicesScreen> createState() => _DevicesScreenState();
}

class _DevicesScreenState extends State<DevicesScreen> {
  List<Device>? _devices;
  bool _loading = true;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = false;
    });
    try {
      final devices = await DevicesRepositoryImpl.getDevices();
      setState(() {
        _devices = devices;
        _loading = false;
      });
    } catch (_) {
      setState(() {
        _loading = false;
        _error = true;
      });
    }
  }

  void _showDeviceModal([Device? device]) {
    final nameCtrl = TextEditingController(text: device?.deviceName ?? '');
    final brandCtrl = TextEditingController(text: device?.brand ?? '');
    final modelCtrl = TextEditingController(text: device?.model ?? '');
    final extCodeCtrl = TextEditingController(
      text: device?.externalDeviceCode ?? '',
    );
    String typeVal = device?.deviceType ?? 'SMART_PLUG';
    String connVal = device?.connectionProtocol ?? 'WIFI';
    DeviceStatus statusVal = device?.status ?? DeviceStatus.active;

    showDialog(
      context: context,
      builder: (ctx) {
        final lang = context.watch<LanguageProvider>();
        return StatefulBuilder(
          builder: (context, setStateModal) {
            return AlertDialog(
              title: Text(
                device == null
                    ? lang.t("Vincular dispositivo", "Link device")
                    : lang.t("Editar dispositivo", "Edit device"),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameCtrl,
                      decoration: InputDecoration(
                        hintText: lang.t("Nombre", "Name"),
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: typeVal,
                      decoration: InputDecoration(
                        labelText: lang.t("Tipo", "Type"),
                      ),
                      items:
                          [
                                'SMART_PLUG',
                                'HVAC',
                                'AIR_CONDITIONER',
                                'REFRIGERATOR',
                                'WATER_HEATER',
                                'TV',
                                'WASHING_MACHINE',
                                'MICROWAVE',
                                'LIGHTING',
                                'REFRIGERATION',
                                'MACHINERY',
                                'OTHER',
                              ]
                              .map(
                                (e) =>
                                    DropdownMenuItem(value: e, child: Text(e)),
                              )
                              .toList(),
                      onChanged: (v) => setStateModal(() => typeVal = v!),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: connVal,
                      decoration: InputDecoration(
                        labelText: lang.t("Conexión", "Connection"),
                      ),
                      items: ['WIFI', 'BLUETOOTH', 'ZIGBEE', 'MATTER']
                          .map(
                            (e) => DropdownMenuItem(value: e, child: Text(e)),
                          )
                          .toList(),
                      onChanged: (v) => setStateModal(() => connVal = v!),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<DeviceStatus>(
                      value: statusVal,
                      decoration: InputDecoration(
                        labelText: lang.t("Estado", "Status"),
                      ),
                      items: [
                        DropdownMenuItem(value: DeviceStatus.active, child: Text(lang.t("Activo", "Active"))),
                        DropdownMenuItem(value: DeviceStatus.inactive, child: Text(lang.t("Inactivo", "Inactive"))),
                        DropdownMenuItem(value: DeviceStatus.disconnected, child: Text(lang.t("Desconectado", "Disconnected"))),
                      ],
                      onChanged: (v) => setStateModal(() => statusVal = v!),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: brandCtrl,
                      decoration: InputDecoration(
                        hintText: lang.t("Marca", "Brand"),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: modelCtrl,
                      decoration: InputDecoration(
                        hintText: lang.t("Modelo", "Model"),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: extCodeCtrl,
                      decoration: InputDecoration(
                        hintText: lang.t("Código Externo", "External Code"),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(lang.t("Cancelar", "Cancel")),
                ),
                TextButton(
                  onPressed: () async {
                    Navigator.pop(ctx);
                    setState(() => _loading = true);
                    try {
                      if (device == null) {
                        await DevicesRepositoryImpl.createDevice(
                          Device(
                            deviceId: DateTime.now().millisecondsSinceEpoch
                                .toString(),
                            deviceName: nameCtrl.text,
                            deviceType: typeVal,
                            brand: brandCtrl.text.isEmpty
                                ? 'Generic'
                                : brandCtrl.text,
                            model: modelCtrl.text.isEmpty
                                ? 'M-1'
                                : modelCtrl.text,
                            externalDeviceCode: extCodeCtrl.text.isEmpty
                                ? 'EXT-${DateTime.now().millisecondsSinceEpoch}'
                                : extCodeCtrl.text,
                            userId: 'u-001',
                            status: statusVal,
                            connectionProtocol: connVal,
                          ),
                        );
                      } else {
                        await DevicesRepositoryImpl.updateDevice(
                          Device(
                            deviceId: device.deviceId,
                            deviceName: nameCtrl.text,
                            deviceType: typeVal,
                            brand: brandCtrl.text,
                            model: modelCtrl.text,
                            externalDeviceCode: extCodeCtrl.text,
                            userId: device.userId,
                            status: statusVal,
                            connectionProtocol: connVal,
                          ),
                        );
                      }
                      await _loadData();
                    } catch (e, stack) {
                      print('DEVICE SAVE ERROR: $e');
                      print('STACK TRACE: $stack');
                      if (mounted) {
                        try {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        } catch (_) {}
                      }
                      setState(() => _loading = false);
                    }
                  },
                  child: Text(lang.t("Guardar", "Save")),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _confirmDelete(Device device) {
    showDialog(
      context: context,
      builder: (ctx) {
        final lang = context.watch<LanguageProvider>();
        return AlertDialog(
          title: Text(lang.t("¿Eliminar dispositivo?", "Delete device?")),
          content: Text(
            lang.t(
              "¿Estás seguro de que deseas eliminar ${device.deviceName}? Perderás el historial.",
              "Are you sure you want to delete ${device.deviceName}? History will be lost.",
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(lang.t("Cancelar", "Cancel")),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(ctx);
                setState(() => _loading = true);
                try {
                  await DevicesRepositoryImpl.deleteDevice(device.deviceId);
                  await _loadData();
                } catch (_) {
                  setState(() => _loading = false);
                }
              },
              style: TextButton.styleFrom(foregroundColor: SemsColors.rose500),
              child: Text(lang.t("Eliminar", "Delete")),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_loading) return const LoadingWidget();
    if (_error) return ErrorWidgetDisplay(onRetry: _loadData);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          lang.t("Mis Dispositivos", "My Devices"),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showDeviceModal(),
          ),
        ],
      ),
      body: _devices == null || _devices!.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.devices,
                    size: 64,
                    color: SemsColors.slate400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    lang.t(
                      "No tienes dispositivos vinculados",
                      "No devices linked",
                    ),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SemsButton(
                    text: lang.t("Vincular dispositivo", "Link device"),
                    onPressed: () => _showDeviceModal(),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView.builder(
                padding: const EdgeInsets.all(16.0),
                itemCount: _devices!.length,
                itemBuilder: (context, index) {
                  final device = _devices![index];
                  SemsBadgeVariant bVar;
                  String sText;
                  if (device.status == DeviceStatus.active) {
                    bVar = SemsBadgeVariant.green;
                    sText = lang.t("ACTIVO", "ACTIVE");
                  } else if (device.status == DeviceStatus.disconnected) {
                    bVar = SemsBadgeVariant.amber;
                    sText = lang.t("DESCONECTADO", "DISCONNECTED");
                  } else {
                    bVar = SemsBadgeVariant.slate;
                    sText = lang.t("INACTIVO", "INACTIVE");
                  }

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: SemsCard(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  device.deviceName,
                                  style: const TextStyle(
                                    fontFamily: 'Sora',
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              SemsBadge(text: sText, variant: bVar),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                Icons.category_outlined,
                                size: 14,
                                color: isDark
                                    ? SemsColors.slate400
                                    : SemsColors.slate500,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                device.deviceType.replaceAll('_', ' '),
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isDark
                                      ? SemsColors.slate400
                                      : SemsColors.slate500,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Icon(
                                Icons.wifi,
                                size: 14,
                                color: isDark
                                    ? SemsColors.slate400
                                    : SemsColors.slate500,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                device.connectionProtocol,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isDark
                                      ? SemsColors.slate400
                                      : SemsColors.slate500,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Divider(),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton.icon(
                                onPressed: () => _showDeviceModal(device),
                                icon: const Icon(Icons.edit, size: 16),
                                label: Text(lang.t("Editar", "Edit")),
                              ),
                              TextButton.icon(
                                onPressed: () => _confirmDelete(device),
                                style: TextButton.styleFrom(
                                  foregroundColor: SemsColors.rose500,
                                ),
                                icon: const Icon(
                                  Icons.delete_outline,
                                  size: 16,
                                ),
                                label: Text(lang.t("Eliminar", "Delete")),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
