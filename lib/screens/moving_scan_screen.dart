import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../app.dart';
import '../models/box_record.dart';
import '../services/qr_payload.dart';
import '../widgets/adaptive_action_layout.dart';
import '../widgets/ios_modal.dart';
import '../widgets/localized_values.dart';

class MovingScanScreen extends StatefulWidget {
  const MovingScanScreen({super.key, required this.projectId});

  final String projectId;

  @override
  State<MovingScanScreen> createState() => _MovingScanScreenState();
}

class _MovingScanScreenState extends State<MovingScanScreen> {
  final _sessionScans = <String>{};
  MoveStatus _targetStatus = MoveStatus.loaded;
  bool _processing = false;
  String? _message;
  bool _messageIsError = false;

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_processing || capture.barcodes.isEmpty) return;
    _processing = true;
    try {
      final payload = BoxQrPayload.tryParse(capture.barcodes.first.rawValue);
      if (payload == null) {
        await _feedback(context.l10n.unsupportedQr, error: true);
        return;
      }
      final store = StoreScope.of(context);
      final box = store.boxById(payload.boxId);
      final targetStatus = _targetStatus;
      if (box == null || box.projectId != widget.projectId) {
        await _feedback(context.l10n.boxNotFound, error: true);
        return;
      }
      if (_sessionScans.contains(box.id) ||
          box.moveStatus.index >= targetStatus.index) {
        await _feedback(
          context.l10n.repeatedScan(
            box.shortCode,
            box.moveStatus.label(context),
          ),
          error: true,
        );
        return;
      }
      await store.updateBox(
        box.copyWith(moveStatus: targetStatus),
        statusSource: StatusChangeSource.scanner,
      );
      await HapticFeedback.mediumImpact();
      if (mounted) {
        setState(() {
          if (_targetStatus == targetStatus) _sessionScans.add(box.id);
          _message = context.l10n.scanUpdated(
            box.shortCode,
            targetStatus.label(context),
          );
          _messageIsError = false;
        });
      }
      await Future<void>.delayed(const Duration(milliseconds: 700));
    } finally {
      _processing = false;
    }
  }

  Future<void> _feedback(String message, {required bool error}) async {
    await HapticFeedback.heavyImpact();
    if (mounted) {
      setState(() {
        _message = message;
        _messageIsError = error;
      });
    }
    await Future<void>.delayed(const Duration(milliseconds: 900));
  }

  void _showUnscanned(List<BoxRecord> boxes) {
    final maxHeight = MediaQuery.sizeOf(context).height * 0.72;
    final contentHeight = boxes.isEmpty
        ? 120.0
        : (boxes.length * 72.0 + 24).clamp(160.0, maxHeight);
    unawaited(
      showIosBottomSheet<void>(
        context: context,
        builder: (context) => SizedBox(
          height: contentHeight,
          child: boxes.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(32),
                  child: Center(child: Text(context.l10n.allScanned)),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  itemCount: boxes.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final box = boxes[index];
                    return ListTile(
                      leading: const Icon(Icons.inventory_2_outlined),
                      title: Text(box.shortCode),
                      subtitle: Text(
                        [
                          box.destinationRoom,
                          box.memo,
                        ].where((value) => value.isNotEmpty).join(' · '),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  },
                ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final unscanned = store
        .boxesForProject(widget.projectId)
        .where((box) => box.moveStatus.index < _targetStatus.index)
        .toList();
    final scanSize = (MediaQuery.sizeOf(context).shortestSide - 64).clamp(
      180.0,
      250.0,
    );
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.movingScanMode)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: IosSelectionField<MoveStatus>(
              label: context.l10n.scanTargetStatus,
              value: _targetStatus,
              valueLabel: _targetStatus.label(context),
              cancelLabel: context.l10n.cancel,
              options: MoveStatus.values
                  .where((status) => status != MoveStatus.draft)
                  .map(
                    (status) => IosActionSheetOption(
                      label: status.label(context),
                      value: status,
                    ),
                  )
                  .toList(growable: false),
              onSelected: (status) {
                setState(() {
                  _targetStatus = status;
                  _sessionScans.clear();
                  _message = null;
                });
              },
            ),
          ),
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                MobileScanner(
                  onDetect: (capture) => unawaited(_onDetect(capture)),
                ),
                Center(
                  child: IgnorePointer(
                    child: Container(
                      width: scanSize,
                      height: scanSize,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.white, width: 3),
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                  ),
                ),
                if (_message != null)
                  Positioned(
                    left: 16,
                    right: 16,
                    bottom: 16,
                    child: Card(
                      color: _messageIsError
                          ? Theme.of(context).colorScheme.errorContainer
                          : Theme.of(context).colorScheme.primaryContainer,
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Text(_message!, textAlign: TextAlign.center),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.all(16),
        child: AdaptiveActionLayout(
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(context.l10n.scannedCount(_sessionScans.length)),
                Text(context.l10n.unscannedCount(unscanned.length)),
              ],
            ),
            OutlinedButton.icon(
              onPressed: () => _showUnscanned(unscanned),
              icon: const Icon(Icons.checklist),
              label: Text(context.l10n.viewUnscanned),
            ),
          ],
        ),
      ),
    );
  }
}
