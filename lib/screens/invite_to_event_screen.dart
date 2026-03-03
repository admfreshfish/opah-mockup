import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/mock_data.dart';
import '../models/event.dart';
import 'event_qr_screen.dart';

/// Invite people to an event by email, username, SMS, or WhatsApp.
class InviteToEventScreen extends StatefulWidget {
  const InviteToEventScreen({super.key, required this.event});

  final Event event;

  @override
  State<InviteToEventScreen> createState() => _InviteToEventScreenState();
}

class _InviteToEventScreenState extends State<InviteToEventScreen> {
  InviteMethod _method = InviteMethod.email;
  final _controller = TextEditingController();
  final _messageController = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    final saved = getEventInviteMessage(widget.event.id);
    _messageController.text = saved ?? defaultInviteMessageFor(widget.event.name);
  }

  @override
  void dispose() {
    _controller.dispose();
    _messageController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  String get _hintText {
    switch (_method) {
      case InviteMethod.email:
        return 'e.g. friend@example.com';
      case InviteMethod.username:
        return 'e.g. julia or @julia';
      case InviteMethod.sms:
      case InviteMethod.whatsapp:
        return 'e.g. +1 555 123 4567';
    }
  }

  String get _label {
    switch (_method) {
      case InviteMethod.email:
        return 'Email address';
      case InviteMethod.username:
        return 'Username';
      case InviteMethod.sms:
        return 'Phone number (SMS)';
      case InviteMethod.whatsapp:
        return 'Phone number (WhatsApp)';
    }
  }

  Future<void> _sendInvite() async {
    final value = _controller.text.trim();
    if (value.isEmpty) return;

    final customMessage = _messageController.text.trim();
    final inviteMessage = customMessage.isEmpty
        ? defaultInviteMessageFor(widget.event.name)
        : customMessage;

    bool launched = false;
    switch (_method) {
      case InviteMethod.email:
        final uri = Uri(
          scheme: 'mailto',
          path: value,
          query: _encodeQuery({'subject': 'Invite: ${widget.event.name}', 'body': inviteMessage}),
        );
        launched = await launchUrl(uri);
        break;
      case InviteMethod.sms:
        final uri = Uri(
          scheme: 'sms',
          path: value.replaceAll(RegExp(r'[^\d+]'), ''),
          queryParameters: {'body': inviteMessage},
        );
        launched = await launchUrl(uri);
        break;
      case InviteMethod.whatsapp:
        final phone = value.replaceAll(RegExp(r'[^\d]'), '');
        final uri = Uri.parse(
          'https://wa.me/$phone?text=${Uri.encodeComponent(inviteMessage)}',
        );
        launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
        break;
      case InviteMethod.username:
        break;
    }

    if (!mounted) return;
    addSentInvite(widget.event.id, value, _method);
    if (customMessage.isNotEmpty) {
      setEventInviteMessage(widget.event.id, customMessage);
    }
    _controller.clear();
    setState(() {});

    if (_method == InviteMethod.username) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Invite sent to $value')),
      );
    } else if (launched) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Opened your app to send the invite')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open app. Invite saved.')),
      );
    }
  }

  static String _encodeQuery(Map<String, String> query) {
    return query.entries
        .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');
  }

  void _exclude(EventInvitation inv) {
    removeInvitation(widget.event.id, inv.id);
    setState(() {});
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${inv.value} removed from invitations')),
      );
    }
  }

  void _markAccepted(EventInvitation inv) {
    markInvitationAccepted(widget.event.id, inv.id);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final pending = getPendingInvitations(widget.event.id);
    final accepted = getAcceptedInvitations(widget.event.id);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Invite to event'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Done'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            widget.event.name,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            'Invite by email, username, SMS, or WhatsApp. They\'ll get a link to join.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                child: Icon(
                  Icons.qr_code_2,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
              title: const Text('QR code for tables'),
              subtitle: const Text(
                'Print & place on tables. Guests scan → download app → register → join event.',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (context) => EventQrScreen(event: widget.event),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Invitation message',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _messageController,
            decoration: const InputDecoration(
              hintText: 'Personalize the message they\'ll receive',
              border: OutlineInputBorder(),
              alignLabelWithHint: true,
            ),
            maxLines: 3,
            minLines: 2,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 24),
          Text(
            'Invite by',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: InviteMethod.values.map((m) {
              final selected = _method == m;
              return ChoiceChip(
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _iconForMethod(m),
                      size: 18,
                      color: selected ? Theme.of(context).colorScheme.onPrimary : Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 6),
                    Text(m.label),
                  ],
                ),
                selected: selected,
                onSelected: (v) {
                  setState(() {
                    _method = m;
                    _controller.clear();
                  });
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _controller,
            focusNode: _focusNode,
            decoration: InputDecoration(
              labelText: _label,
              hintText: _hintText,
              border: const OutlineInputBorder(),
              prefixIcon: Icon(
                _iconForMethod(_method),
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              suffixIcon: _controller.text.trim().isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.send),
                      onPressed: _sendInvite,
                    )
                  : null,
            ),
            keyboardType: _keyboardTypeForMethod(_method),
            textCapitalization: TextCapitalization.none,
            autocorrect: false,
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) => _sendInvite(),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _controller.text.trim().isEmpty ? null : _sendInvite,
              icon: const Icon(Icons.send, size: 20),
              label: const Text('Send invite'),
            ),
          ),
          if (pending.isNotEmpty || accepted.isNotEmpty) ...[
            const SizedBox(height: 32),
            if (pending.isNotEmpty) ...[
              Text(
                'Waiting acceptation',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 8),
              ...pending.map((inv) => _InvitationTile(
                    invitation: inv,
                    onExclude: () => _exclude(inv),
                    onMarkAccepted: () => _markAccepted(inv),
                    showMarkAccepted: true,
                    iconForMethod: _iconForMethod,
                  )),
              const SizedBox(height: 20),
            ],
            if (accepted.isNotEmpty) ...[
              Text(
                'Accepted',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 8),
              ...accepted.map((inv) => _InvitationTile(
                    invitation: inv,
                    onExclude: () => _exclude(inv),
                    onMarkAccepted: null,
                    showMarkAccepted: false,
                    iconForMethod: _iconForMethod,
                  )),
            ],
          ],
        ],
      ),
    );
  }

  IconData _iconForMethod(InviteMethod m) {
    switch (m) {
      case InviteMethod.email:
        return Icons.email_outlined;
      case InviteMethod.username:
        return Icons.person_outline;
      case InviteMethod.sms:
        return Icons.sms_outlined;
      case InviteMethod.whatsapp:
        return Icons.chat_outlined;
    }
  }

  TextInputType _keyboardTypeForMethod(InviteMethod m) {
    switch (m) {
      case InviteMethod.email:
        return TextInputType.emailAddress;
      case InviteMethod.username:
        return TextInputType.text;
      case InviteMethod.sms:
      case InviteMethod.whatsapp:
        return TextInputType.phone;
    }
  }
}

class _InvitationTile extends StatelessWidget {
  const _InvitationTile({
    required this.invitation,
    required this.onExclude,
    this.onMarkAccepted,
    required this.showMarkAccepted,
    required this.iconForMethod,
  });

  final EventInvitation invitation;
  final VoidCallback onExclude;
  final VoidCallback? onMarkAccepted;
  final bool showMarkAccepted;
  final IconData Function(InviteMethod) iconForMethod;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        child: Icon(
          iconForMethod(invitation.method),
          color: Colors.black,
          size: 22,
        ),
      ),
      title: Text(invitation.value),
      subtitle: Text(invitation.method.label),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showMarkAccepted && onMarkAccepted != null)
            TextButton(
              onPressed: onMarkAccepted,
              child: const Text('Mark accepted'),
            ),
          IconButton(
            icon: const Icon(Icons.person_remove_outlined),
            tooltip: 'Exclude',
            onPressed: onExclude,
          ),
        ],
      ),
      dense: true,
    );
  }
}
