import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../data/mock_data.dart';
import '../data/profile_repository.dart';
import '../models/event.dart';
import '../models/photo.dart';
import '../models/person.dart';
import 'camera_placeholder_screen.dart';
import 'invite_to_event_screen.dart';
import 'photo_viewer_screen.dart';

class EventDetailScreen extends StatefulWidget {
  const EventDetailScreen({super.key, required this.event});

  final Event event;

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

enum EventViewMode { timeline, grid }

class _EventDetailScreenState extends State<EventDetailScreen> {
  String? _filterByPersonId;
  bool _filterByLikedByMe = false;
  EventViewMode _viewMode = EventViewMode.timeline;
  final Set<String> _likedPhotoIds = {};
  String? _currentUserDisplayName;
  String? _currentUserImagePath;

  @override
  void initState() {
    super.initState();
    _loadCurrentUserProfile();
  }

  Future<void> _loadCurrentUserProfile() async {
    final nickname = await ProfileRepository.instance.getNickname();
    final imagePath = await ProfileRepository.instance.getProfileImagePath();
    if (mounted) {
      setState(() {
        _currentUserDisplayName = (nickname != null && nickname.trim().isNotEmpty)
            ? nickname.trim()
            : null;
        _currentUserImagePath = imagePath;
      });
    }
  }

  List<Photo> get _photos {
    List<Photo> list = _filterByPersonId != null
        ? photosForEventFilteredByPerson(widget.event.id, _filterByPersonId!)
        : photosForEvent(widget.event.id);
    if (_filterByLikedByMe) {
      list = list.where((p) => _likedPhotoIds.contains(p.id)).toList();
    }
    return list;
  }

  Person? get _filterPerson =>
      _filterByPersonId != null ? personById(_filterByPersonId!) : null;

  Event get _event => getEventWithInvites(widget.event.id) ?? widget.event;

  Future<void> _openInvite() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (context) => InviteToEventScreen(event: _event),
      ),
    );
    if (mounted && result == true) setState(() {});
  }

  bool _isLiked(Photo photo) => _likedPhotoIds.contains(photo.id);

  void _toggleLike(Photo photo) {
    setState(() {
      if (_likedPhotoIds.contains(photo.id)) {
        _likedPhotoIds.remove(photo.id);
        decrementPhotoLikes(photo.id);
      } else {
        _likedPhotoIds.add(photo.id);
        incrementPhotoLikes(photo.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final photos = _photos;
    final event = _event;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _filterPerson != null
              ? '${event.name} · ${_filterPerson!.name}'
              : event.name,
        ),
        actions: [
          IconButton(
            tooltip: _filterByLikedByMe ? 'Show all photos' : 'Only photos I liked',
            icon: Icon(
              Icons.favorite,
              color: _filterByLikedByMe
                  ? Theme.of(context).colorScheme.primary
                  : null,
            ),
            onPressed: () => setState(() => _filterByLikedByMe = !_filterByLikedByMe),
          ),
          IconButton(
            tooltip: _viewMode == EventViewMode.timeline ? 'Switch to grid' : 'Switch to timeline',
            icon: Icon(
              _viewMode == EventViewMode.timeline ? Icons.grid_view : Icons.view_list,
            ),
            onPressed: () => setState(() {
              _viewMode = _viewMode == EventViewMode.timeline
                  ? EventViewMode.grid
                  : EventViewMode.timeline;
            }),
          ),
          if (_filterByPersonId != null)
            IconButton(
              tooltip: 'Clear person filter',
              icon: const Icon(Icons.filter_alt_off),
              onPressed: () => setState(() => _filterByPersonId = null),
            ),
          if (event.isOwner)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: TextButton.icon(
                onPressed: _openInvite,
                icon: const Icon(Icons.person_add, size: 20),
                label: const Text('Invite'),
              ),
            ),
        ],
      ),
      body: photos.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _filterByLikedByMe ? Icons.favorite_border : Icons.photo_library_outlined,
                    size: 64,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _filterByLikedByMe
                        ? 'No photos you liked in this event'
                        : _filterByPersonId != null
                            ? 'No photos with ${_filterPerson?.name} in this event'
                            : 'No photos yet. Take the first one!',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          : _viewMode == EventViewMode.timeline
              ? ListView.builder(
                  padding: const EdgeInsets.only(bottom: 80),
                  itemCount: photos.length,
                  itemBuilder: (context, index) {
                    final photo = photos[index];
                    final isCurrentUser = photo.uploadedByUserId == currentUserId;
                    final uploaderName = isCurrentUser
                        ? (_currentUserDisplayName ?? 'You')
                        : userNameForUserId(photo.uploadedByUserId);
                    final uploaderImagePath = isCurrentUser ? _currentUserImagePath : null;
                    final uploaderImageUrl = uploaderImagePath == null
                        ? userAvatarUrl(photo.uploadedByUserId)
                        : null;
                    return _TimelinePhotoCard(
                      photo: photo,
                      uploaderName: uploaderName,
                      uploaderImagePath: uploaderImagePath,
                      uploaderImageUrl: uploaderImageUrl,
                      isLiked: _isLiked(photo),
                      likeCount: getPhotoLikeCount(photo.id),
                      onLike: () => _toggleLike(photo),
                      onPhotoTap: () => _openPhotoViewer(context, photo),
                    );
                  },
                )
              : GridView.builder(
                  padding: const EdgeInsets.fromLTRB(8, 8, 8, 80),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    childAspectRatio: 1,
                  ),
                  itemCount: photos.length,
                  itemBuilder: (context, index) {
                    final photo = photos[index];
                    return _GridPhotoTile(
                      photo: photo,
                      isLiked: _isLiked(photo),
                      likeCount: getPhotoLikeCount(photo.id),
                      onLike: () => _toggleLike(photo),
                      onPhotoTap: () => _openPhotoViewer(context, photo),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _takePhoto(context),
        tooltip: 'Take a photo',
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.black,
        child: const Icon(Icons.camera_alt),
      ),
    );
  }

  void _openPhotoViewer(BuildContext context, Photo photo) async {
    final selectedPersonId = await Navigator.of(context).push<String>(
      MaterialPageRoute<String>(
        builder: (context) => PhotoViewerScreen(
          photo: photo,
          people: mockPeople,
        ),
      ),
    );
    if (!mounted) return;
    if (selectedPersonId != null) {
      setState(() => _filterByPersonId = selectedPersonId);
    }
  }

  void _takePhoto(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => CameraPlaceholderScreen(eventId: widget.event.id),
      ),
    );
  }
}

class _TimelinePhotoCard extends StatelessWidget {
  const _TimelinePhotoCard({
    required this.photo,
    required this.uploaderName,
    this.uploaderImagePath,
    this.uploaderImageUrl,
    required this.isLiked,
    required this.likeCount,
    required this.onLike,
    required this.onPhotoTap,
  });

  final Photo photo;
  final String uploaderName;
  final String? uploaderImagePath;
  final String? uploaderImageUrl;
  final bool isLiked;
  final int likeCount;
  final VoidCallback onLike;
  final VoidCallback onPhotoTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                  backgroundImage: uploaderImagePath != null
                      ? FileImage(File(uploaderImagePath!))
                      : uploaderImageUrl != null
                          ? NetworkImage(uploaderImageUrl!)
                          : null,
                  child: uploaderImagePath == null && uploaderImageUrl == null
                      ? Text(
                          uploaderName.isNotEmpty ? uploaderName[0].toUpperCase() : '?',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.onPrimaryContainer,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        uploaderName,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      if (photo.takenAt != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          DateFormat('MMM d, y · HH:mm').format(photo.takenAt!),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onPhotoTap,
            child: AspectRatio(
              aspectRatio: 1,
              child: Image.network(
                photo.imageUrl,
                fit: BoxFit.cover,
                width: double.infinity,
                errorBuilder: (_, __, ___) => ColoredBox(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  child: const Center(
                    child: Icon(Icons.broken_image_outlined, size: 48),
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 6, 12, 10),
            child: Row(
              children: [
                IconButton(
                  onPressed: onLike,
                  icon: Icon(
                    isLiked ? Icons.favorite : Icons.favorite_border,
                    color: isLiked
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.onSurface,
                  ),
                  style: IconButton.styleFrom(
                    foregroundColor: isLiked
                        ? Theme.of(context).colorScheme.primary
                        : null,
                  ),
                ),
                Text(
                  likeCount > 0 ? '$likeCount' : '',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GridPhotoTile extends StatelessWidget {
  const _GridPhotoTile({
    required this.photo,
    required this.isLiked,
    required this.likeCount,
    required this.onLike,
    required this.onPhotoTap,
  });

  final Photo photo;
  final bool isLiked;
  final int likeCount;
  final VoidCallback onLike;
  final VoidCallback onPhotoTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPhotoTap,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              photo.imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => ColoredBox(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: const Center(
                  child: Icon(Icons.broken_image_outlined, size: 32),
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black54,
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: onLike,
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Icon(
                          isLiked ? Icons.favorite : Icons.favorite_border,
                          color: isLiked
                              ? Theme.of(context).colorScheme.primary
                              : Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                    if (likeCount > 0)
                      Text(
                        '$likeCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
