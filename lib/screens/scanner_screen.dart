import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../app.dart';
import '../services/qr_payload.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  bool _handled = false;
  String? _message;

  void _onDetect(BarcodeCapture capture) {
    if (_handled || capture.barcodes.isEmpty) return;
    final payload = BoxQrPayload.tryParse(capture.barcodes.first.rawValue);
    if (payload == null) {
      setState(() => _message = context.l10n.unsupportedQr);
      return;
    }
    final box = StoreScope.of(context).boxById(payload.boxId);
    if (box == null || box.projectId != payload.projectId) {
      setState(() => _message = context.l10n.boxNotFound);
      return;
    }
    _handled = true;
    Navigator.pop(context, box.id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.scan)),
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(
            onDetect: _onDetect,
            scanWindow: Rect.fromCenter(
              center: MediaQuery.sizeOf(context).center(Offset.zero),
              width: 260,
              height: 260,
            ),
          ),
          Center(
            child: IgnorePointer(
              child: Container(
                width: 260,
                height: 260,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white, width: 3),
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ),
          if (_message != null)
            Positioned(
              left: 20,
              right: 20,
              bottom: 32,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(_message!, textAlign: TextAlign.center),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
