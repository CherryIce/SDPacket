import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:printing/printing.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../app.dart';
import '../models/box_record.dart';
import '../services/export_service.dart';
import '../services/qr_payload.dart';
import '../widgets/physical_mark_dialog.dart';

class QrLabelScreen extends StatefulWidget {
  const QrLabelScreen({super.key, required this.boxId});

  final String boxId;

  @override
  State<QrLabelScreen> createState() => _QrLabelScreenState();
}

class _QrLabelScreenState extends State<QrLabelScreen> {
  final _boundaryKey = GlobalKey();
  final _exportService = const ExportService();
  bool _busy = false;

  Future<void> _run(Future<void> Function() operation) async {
    setState(() => _busy = true);
    try {
      await operation();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(context.l10n.exportFailed)));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _sharePng(BoxRecord box) async {
    final boundary =
        _boundaryKey.currentContext!.findRenderObject()!
            as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 4);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    final bytes = data!.buffer.asUint8List();
    if (!mounted) return;
    final renderBox = context.findRenderObject() as RenderBox?;
    final result = await SharePlus.instance.share(
      ShareParams(
        files: [XFile.fromData(bytes, mimeType: 'image/png')],
        fileNameOverrides: ['${box.shortCode}.png'],
        sharePositionOrigin: renderBox == null
            ? null
            : renderBox.localToGlobal(Offset.zero) & renderBox.size,
      ),
    );
    if (mounted && result.status == ShareResultStatus.success) {
      await StoreScope.of(context).markLabelExported([box.id]);
    }
  }

  Future<Uint8List> _pdf(BoxRecord box) {
    final store = StoreScope.of(context);
    return _exportService.buildLabelPdf(
      store.projectById(box.projectId),
      [box],
      BoxLabelPdfLabels(
        documentTitle: context.l10n.labelDocumentTitle,
        brand: context.l10n.labelBrand,
        scanOrSearchCode: context.l10n.scanOrSearchCode,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final box = store.boxById(widget.boxId);
    if (box == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(child: Text(context.l10n.boxNotFound)),
      );
    }
    final payload = BoxQrPayload(
      projectId: box.projectId,
      boxId: box.id,
      code: box.shortCode,
    ).encode();
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.qrAndPrint)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: RepaintBoundary(
              key: _boundaryKey,
              child: ColoredBox(
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(22),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        box.shortCode,
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 34,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 12),
                      QrImageView(
                        data: payload,
                        version: QrVersions.auto,
                        errorCorrectionLevel: QrErrorCorrectLevel.M,
                        size: 240,
                        backgroundColor: Colors.white,
                        eyeStyle: const QrEyeStyle(color: Colors.black),
                        dataModuleStyle: const QrDataModuleStyle(
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(context.l10n.noPrinterHint(box.shortCode)),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: _busy ? null : () => _run(() => _sharePng(box)),
            icon: const Icon(Icons.image_outlined),
            label: Text(context.l10n.exportPng),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: _busy
                ? null
                : () => _run(() async {
                    final bytes = await _pdf(box);
                    final shared = await Printing.sharePdf(
                      bytes: bytes,
                      filename: '${box.shortCode}.pdf',
                    );
                    if (mounted && shared) {
                      await store.markLabelExported([box.id]);
                    }
                  }),
            icon: const Icon(Icons.picture_as_pdf_outlined),
            label: Text(context.l10n.exportSinglePdf),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: _busy
                ? null
                : () => _run(() async {
                    final bytes = await _pdf(box);
                    final printed = await Printing.layoutPdf(
                      onLayout: (_) async => bytes,
                    );
                    if (mounted && printed) {
                      await store.markLabelExported([box.id]);
                    }
                  }),
            icon: const Icon(Icons.print_outlined),
            label: Text(context.l10n.printLabel),
          ),
          const SizedBox(height: 14),
          if (box.labelExportedAt != null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline),
                    const SizedBox(width: 10),
                    Expanded(child: Text(context.l10n.labelExportedNotice)),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 10),
          FilledButton.tonalIcon(
            onPressed: () => showPhysicalMarkReminder(context, box),
            icon: const Icon(Icons.label_outline),
            label: Text(
              box.physicalMarkStatus == PhysicalMarkStatus.pending
                  ? context.l10n.markConfirmed
                  : context.l10n.marked,
            ),
          ),
        ],
      ),
    );
  }
}
