/// Event types for Opah (weddings, birthdays, trips, etc.)
enum EventType {
  wedding,
  birthday,
  trip,
  other,
}

extension EventTypeX on EventType {
  String get label {
    switch (this) {
      case EventType.wedding:
        return 'Wedding';
      case EventType.birthday:
        return 'Birthday';
      case EventType.trip:
        return 'Trip';
      case EventType.other:
        return 'Other';
    }
  }

  String get emoji {
    switch (this) {
      case EventType.wedding:
        return '💒';
      case EventType.birthday:
        return '🎂';
      case EventType.trip:
        return '✈️';
      case EventType.other:
        return '📷';
    }
  }
}

/// An event (wedding, birthday, trip) that has a shared photo album.
class Event {
  const Event({
    required this.id,
    required this.name,
    required this.type,
    required this.isOwner,
    this.coverPhotoId,
    this.coverImagePath,
    this.description,
    this.scheduledAt,
    this.invitedUserIds = const [],
  });

  final String id;
  final String name;
  final EventType type;
  /// True if the current user created this event.
  final bool isOwner;
  final String? coverPhotoId;
  /// Local file path for a cover image (e.g. from event creation).
  final String? coverImagePath;
  final String? description;
  /// Date and time of the event.
  final DateTime? scheduledAt;
  final List<String> invitedUserIds;

  Event copyWith({
    String? id,
    String? name,
    EventType? type,
    bool? isOwner,
    String? coverPhotoId,
    String? coverImagePath,
    String? description,
    DateTime? scheduledAt,
    List<String>? invitedUserIds,
  }) {
    return Event(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      isOwner: isOwner ?? this.isOwner,
      coverPhotoId: coverPhotoId ?? this.coverPhotoId,
      coverImagePath: coverImagePath ?? this.coverImagePath,
      description: description ?? this.description,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      invitedUserIds: invitedUserIds ?? this.invitedUserIds,
    );
  }
}
