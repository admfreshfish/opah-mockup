import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/mock_data.dart';
import '../models/event.dart';

/// Shows a QR code for the event so the organizer can print it and place on tables.
/// Guests scan → app store → download → register → automatically join the event.
class EventQrScreen extends StatelessWidget {
  const EventQrScreen({super.key, required this.event});

  final Event event;

  @override
  Widget build(BuildContext context) {
    final joinUrl = eventJoinUrl(event.id);
    final emailBody = _emailBody(joinUrl);

    return Scaffold(
      appBar: AppBar(
        title: const Text('QR code for tables'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            event.name,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Guests who don\'t have the app can scan this QR code. They\'ll be taken to the app store, then after they download and register they\'ll automatically join this event.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 24),
          Center(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: QrImageView(
                data: joinUrl,
                version: QrVersions.auto,
                size: 220,
                backgroundColor: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              'Print and place on party tables',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _copyLink(context, joinUrl),
              icon: const Icon(Icons.copy),
              label: const Text('Copy join link'),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => _emailLink(context, emailBody),
              icon: const Icon(Icons.email),
              label: const Text('Email me the QR link'),
            ),
          ),
        ],
      ),
    );
  }

  String _emailBody(String joinUrl) {
    return '''
Hi,

Here's the join link for "${event.name}" on Opah:

$joinUrl

You can print this link as a QR code from the Opah app (Invite → QR code for tables) and place it on the party tables. Guests scan the QR → download the app → register → they automatically join the event.

— Opah
''';
  }

  Future<void> _copyLink(BuildContext context, String joinUrl) async {
    await Clipboard.setData(ClipboardData(text: joinUrl));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Join link copied to clipboard')),
      );
    }
  }

  Future<void> _emailLink(BuildContext context, String body) async {
    final uri = Uri(
      scheme: 'mailto',
      path: '',
      query: _encodeQuery({
        'subject': 'Join link: ${event.name} (Opah)',
        'body': body,
      }),
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Opened your email app. Send to yourself to get the link.')),
        );
      }
    }
  }

  static String _encodeQuery(Map<String, String> query) {
    return query.entries
        .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');
  }
}
