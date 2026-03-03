import 'dart:io';

import 'package:flutter/material.dart';

import '../data/mock_data.dart';
import '../data/profile_repository.dart';
import '../models/event.dart';
import 'create_event_screen.dart';
import 'event_detail_screen.dart';
import 'profile_screen.dart';
import 'scan_join_event_screen.dart';

String _formatSchedule(DateTime dt) {
  const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  final h = dt.hour;
  final m = dt.minute.toString().padLeft(2, '0');
  final ampm = h >= 12 ? 'PM' : 'AM';
  final h12 = h > 12 ? h - 12 : (h == 0 ? 12 : h);
  return '${dt.day} ${months[dt.month - 1]} ${dt.year}, $h12:$m $ampm';
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<Event> _createdEvents = [];
  String? _profileImagePath;

  @override
  void initState() {
    super.initState();
    _loadProfileImage();
  }

  Future<void> _loadProfileImage() async {
    final path = await ProfileRepository.instance.getProfileImagePath();
    if (mounted) setState(() => _profileImagePath = path);
  }

  Future<void> _openProfile(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => const ProfileScreen(),
      ),
    );
    if (mounted) {
      setState(() {});
      _loadProfileImage();
    }
  }

  @override
  Widget build(BuildContext context) {
    final myEvents = [
      ...mockEvents.where((e) => e.isOwner),
      ..._createdEvents,
    ];
    final invitedEvents = mockEvents
        .where((e) =>
            !e.isOwner &&
            (e.invitedUserIds.contains(currentUserId) || hasUserJoinedEvent(e.id)))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Opah'),
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 2,
        actions: [
          IconButton(
            icon: _profileImagePath != null
                ? CircleAvatar(
                    radius: 18,
                    backgroundImage: FileImage(File(_profileImagePath!)),
                  )
                : const Icon(Icons.person_outline),
            onPressed: () => _openProfile(context),
            tooltip: 'My profile',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {},
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: Text(
                  'My events',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
            ),
            if (myEvents.isEmpty)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(
                    child: Text('No events yet. Create one!'),
                  ),
                ),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _EventCard(
                    event: myEvents[index],
                    onTap: () => _openEvent(context, myEvents[index]),
                  ),
                  childCount: myEvents.length,
                ),
              ),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: Text(
                  'Invited to',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
            ),
            if (invitedEvents.isEmpty)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'Events you\'re invited to will appear here.',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _EventCard(
                    event: invitedEvents[index],
                    onTap: () => _openEvent(context, invitedEvents[index]),
                  ),
                  childCount: invitedEvents.length,
                ),
              ),
            const SliverToBoxAdapter(child: SizedBox(height: 80)),
          ],
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(right: 16, bottom: 16),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            FloatingActionButton.extended(
              heroTag: 'join-by-qr-fab',
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (context) => const ScanJoinEventScreen(),
                ),
              ),
              foregroundColor: Colors.black,
              icon: const Icon(Icons.qr_code_scanner),
              label: const Text('Join by QR'),
            ),
            const SizedBox(width: 12),
            FloatingActionButton.extended(
              heroTag: 'new-event-fab',
              onPressed: () => _createEvent(context),
              foregroundColor: Colors.black,
              icon: const Icon(Icons.add),
              label: const Text('New event'),
            ),
          ],
        ),
      ),
    );
  }

  void _openEvent(BuildContext context, Event event) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => EventDetailScreen(event: event),
      ),
    );
  }

  void _createEvent(BuildContext context) async {
    final event = await Navigator.of(context).push<Event>(
      MaterialPageRoute<Event>(
        builder: (context) => const CreateEventScreen(),
      ),
    );
    if (event != null && mounted) {
      setState(() => _createdEvents.add(event));
    }
  }
}

class _EventCard extends StatelessWidget {
  const _EventCard({required this.event, required this.onTap});

  final Event event;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final photos = photosForEvent(event.id);
    final coverUrl = event.coverPhotoId != null
        ? photos
            .where((p) => p.id == event.coverPhotoId)
            .map((p) => p.imageUrl)
            .firstOrNull
        : null;
    final photoCount = photos.length;
    final hasLocalCover = event.coverImagePath != null;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: 100,
          child: Row(
            children: [
              SizedBox(
                width: 100,
                child: hasLocalCover
                    ? Image.file(
                        File(event.coverImagePath!),
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _placeholder(context),
                      )
                    : coverUrl != null
                        ? Image.network(
                            coverUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _placeholder(context),
                          )
                        : _placeholder(context),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        event.name,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            '${event.type.emoji} ${event.type.label}',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '$photoCount photo${photoCount == 1 ? '' : 's'}',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                          ),
                        ],
                      ),
                      if (event.scheduledAt != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          _formatSchedule(event.scheduledAt!),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.w500,
                              ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(right: 8),
                child: Icon(Icons.chevron_right),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _placeholder(BuildContext context) {
    return ColoredBox(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Center(
        child: Text(
          event.type.emoji,
          style: const TextStyle(fontSize: 32),
        ),
      ),
    );
  }
}

extension _FirstOrNull<E> on Iterable<E> {
  E? get firstOrNull {
    for (final e in this) return e;
    return null;
  }
}
