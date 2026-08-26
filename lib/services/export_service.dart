import 'dart:convert';
import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/box_record.dart';
import '../models/moving_project.dart';
import 'qr_payload.dart';

class ExportService {
  const ExportService();

  Uint8List buildCsv(MovingProject project, List<BoxRecord> boxes) {
    final rows = <List<String>>[
      const [
        'code',
        'title',
        'destination_room',
        'current_location',
        'memo',
        'tags',
        'items',
        'priority',
        'move_status',
        'physical_mark_status',
        'physical_mark_method',
        'issues',
        'created_at',
        'updated_at',
      ],
      ...boxes.map(
        (box) => [
          box.shortCode,
          box.title,
          box.destinationRoom,
          box.currentLocation,
          box.memo,
          box.tags.join('|'),
          box.items.map((item) => item.name).join('|'),
          box.isPriority.toString(),
          box.moveStatus.name,
          box.physicalMarkStatus.name,
          box.physicalMarkMethod?.name ?? '',
          box.issues.map((issue) => issue.name).join('|'),
          box.createdAt.toIso8601String(),
          box.updatedAt.toIso8601String(),
        ],
      ),
    ];
    final content = rows.map((row) => row.map(_csvCell).join(',')).join('\r\n');
    return Uint8List.fromList([0xEF, 0xBB, 0xBF, ...utf8.encode(content)]);
  }

  Future<Uint8List> buildLabelPdf(
    MovingProject project,
    List<BoxRecord> boxes,
  ) async {
    final document = pw.Document(
      title: 'Moving Box Labels',
      author: 'Moving Box',
    );
    final chunks = <List<BoxRecord>>[];
    for (var index = 0; index < boxes.length; index += 10) {
      chunks.add(boxes.sublist(index, (index + 10).clamp(0, boxes.length)));
    }
    for (final chunk in chunks) {
      document.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(20),
          build: (_) => pw.GridView(
            crossAxisCount: 2,
            childAspectRatio: 1.55,
            children: chunk
                .map((box) => _label(project: project, box: box))
                .toList(),
          ),
        ),
      );
    }
    return document.save();
  }

  pw.Widget _label({required MovingProject project, required BoxRecord box}) {
    final payload = BoxQrPayload(
      projectId: project.id,
      boxId: box.id,
      code: box.shortCode,
    ).encode();
    return pw.Container(
      margin: const pw.EdgeInsets.all(5),
      padding: const pw.EdgeInsets.all(9),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        border: pw.Border.all(color: PdfColors.black, width: 1.2),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              mainAxisAlignment: pw.MainAxisAlignment.center,
              children: [
                pw.Text('MOVE BOX', style: const pw.TextStyle(fontSize: 9)),
                pw.SizedBox(height: 8),
                pw.Text(
                  box.shortCode,
                  style: pw.TextStyle(
                    fontSize: 26,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 6),
                pw.Text(
                  'SCAN OR SEARCH CODE',
                  style: const pw.TextStyle(fontSize: 7),
                ),
              ],
            ),
          ),
          pw.BarcodeWidget(
            barcode: pw.Barcode.qrCode(),
            data: payload,
            width: 88,
            height: 88,
            drawText: false,
          ),
        ],
      ),
    );
  }
}

String _csvCell(String value) => '"${value.replaceAll('"', '""')}"';
