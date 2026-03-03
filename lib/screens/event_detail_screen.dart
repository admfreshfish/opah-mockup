import 'dart:io';

import 'package:flutter/material.dart';

import '../data/mock_data.dart';
import '../data/profile_repository.dart';
import '../models/event.dart';
import '../models/photo.dart';
import '../models/person.dart';
import 'camera_placeholder_screen.dart';
import 'photo_viewer_screen.dart';

class EventDetailScreen extends StatefulWidget {
  const EventDetailScreen({super.key, required this.event});

  final Event event;

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  String? _filterByPersonId;
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
    if (_filterByPersonId != null) {
      return photosForEventFilteredByPerson(widget.event.id, _filterByPersonId!);
    }
    return photosForEvent(widget.event.id);
  }

  Person? get _filterPerson =>
      _filterByPersonId != null ? personById(_filterByPersonId!) : null;

  bool _isLiked(Photo photo) => _likedPhotoIds.contains(photo.id);

  void _toggleLike(Photo photo) {
    setState(() {
      if (_likedPhotoIds.contains(photo.id)) {
        _likedPhotoIds.remove(photo.id);
      } else {
        _likedPhotoIds.add(photo.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final photos = _photos;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _filterPerson != null
              ? '${widget.event.name} · ${_filterPerson!.name}'
              : widget.event.name,
        ),
        actions: [
          if (_filterByPersonId != null)
            IconButton(
              tooltip: 'Clear filter',
              icon: const Icon(Icons.filter_alt_off),
              onPressed: () => setState(() => _filterByPersonId = null),
            ),
        ],
      ),
      body: photos.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.photo_library_outlined,
                    size: 64,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _filterByPersonId != null
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
          : ListView.builder(
              padding: const EdgeInsets.only(bottom: 80),
              itemCount: photos.length,
              itemBuilder: (context, index) {
                final photo = photos[index];
                final isCurrentUser = photo.uploadedByUserId == currentUserId;
                final uploaderName = isCurrentUser
                    ? (_currentUserDisplayName ?? 'You')
                    : userNameForUserId(photo.uploadedByUserId);
                final uploaderImagePath = isCurrentUser ? _currentUserImagePath : null;
                return _TimelinePhotoCard(
                  photo: photo,
                  uploaderName: uploaderName,
                  uploaderImagePath: uploaderImagePath,
                  isLiked: _isLiked(photo),
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
    required this.isLiked,
    required this.onLike,
    required this.onPhotoTap,
  });

  final Photo photo;
  final String uploaderName;
  final String? uploaderImagePath;
  final bool isLiked;
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
                      : null,
                  child: uploaderImagePath == null
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
                Text(
                  uploaderName,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
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
              ],
            ),
          ),
        ],
      ),
    );
  }
}
