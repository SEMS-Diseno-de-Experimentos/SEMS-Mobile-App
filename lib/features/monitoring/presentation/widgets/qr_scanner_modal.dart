import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import 'package:flutter_application_1/core/providers/language_provider.dart';
import 'package:flutter_application_1/core/widgets/sems_button.dart';
import 'package:flutter_application_1/core/config/theme.dart';

class QRScannerModal extends StatefulWidget {
  final Function(String) onScan;

  const QRScannerModal({super.key, required this.onScan});

  @override
  State<QRScannerModal> createState() => _QRScannerModalState();
}

class _QRScannerModalState extends State<QRScannerModal> {
  bool _scanned = false;
  
  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: isDark ? SemsColors.navy900 : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? SemsColors.navy700 : SemsColors.slate300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            lang.t("Escanear Medidor", "Scan Meter"),
            style: const TextStyle(
              fontFamily: 'Sora',
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            lang.t("Apunta la cámara al código QR de tu medidor EOS.", "Point the camera at your EOS meter QR code."),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? SemsColors.slate400 : SemsColors.slate600,
            ),
          ),
          const SizedBox(height: 32),
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 32),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: SemsColors.blue500, width: 2),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: MobileScanner(
                  onDetect: (capture) {
                    if (_scanned) return;
                    final List<Barcode> barcodes = capture.barcodes;
                    if (barcodes.isNotEmpty && barcodes.first.rawValue != null) {
                      setState(() => _scanned = true);
                      widget.onScan(barcodes.first.rawValue!);
                      Navigator.pop(context);
                    }
                  },
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: SemsButton(
              text: lang.t("Cancelar", "Cancel"),
              variant: SemsButtonVariant.outline,
              isFullWidth: true,
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ],
      ),
    );
  }
}
