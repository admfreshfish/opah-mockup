import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../data/mock_data.dart';
import 'event_detail_screen.dart';

/// Scan a QR code to join an event (e.g. QR on party tables).
class ScanJoinEventScreen extends StatefulWidget {
  const ScanJoinEventScreen({super.key});

  @override
  State<ScanJoinEventScreen> createState() => _ScanJoinEventScreenState();
}

class _ScanJoinEventScreenState extends State<ScanJoinEventScreen> {
  bool _hasHandledScan = false;

  void _onDetect(BarcodeCapture capture, BuildContext context) {
    if (_hasHandledScan) return;
    final barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final code = barcodes.first.rawValue;
    if (code == null || code.isEmpty) return;

    final eventId = parseJoinEventIdFromUrl(code);
    if (eventId == null) return;

    _hasHandledScan = true;
    joinEventViaQr(eventId);

    final event = eventById(eventId);
    final eventName = event?.name ?? 'the event';

    if (!context.mounted) return;
    Navigator.of(context).popUntil((route) => route.isFirst);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('You\'ve joined $eventName'),
        action: SnackBarAction(
          label: 'Open',
          onPressed: () {
            if (event != null) {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (context) => EventDetailScreen(event: event),
                ),
              );
            }
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan to join event'),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(
            onDetect: (capture) => _onDetect(capture, context),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  Text(
                    'Point your camera at the event QR code',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          shadows: [
                            const Shadow(color: Colors.black87, offset: Offset(0, 1)),
                            const Shadow(color: Colors.black54, blurRadius: 4),
                          ],
                        ),
                    textAlign: TextAlign.center,
                  ),
                  Text(
                    'You\'ll join the event and see it under "Invited to"',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white70,
                          shadows: const [
                            Shadow(color: Colors.black87, offset: Offset(0, 1)),
                          ],
                        ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
