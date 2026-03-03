import '../models/event.dart';
import '../models/person.dart';
import '../models/photo.dart';

/// Current user id (for "my events" vs "invited").
const String currentUserId = 'user_me';

/// A user that can be invited to an event (mock contact).
class InvitableUser {
  const InvitableUser({
    required this.id,
    required this.name,
    this.email,
  });
  final String id;
  final String name;
  final String? email;
}

/// How the user chose to send an invite (email, username, SMS, WhatsApp).
enum InviteMethod {
  email,
  username,
  sms,
  whatsapp,
}

extension InviteMethodX on InviteMethod {
  String get label {
    switch (this) {
      case InviteMethod.email:
        return 'Email';
      case InviteMethod.username:
        return 'Username';
      case InviteMethod.sms:
        return 'SMS';
      case InviteMethod.whatsapp:
        return 'WhatsApp';
    }
  }
}

/// Status of an event invitation.
enum InvitationStatus {
  pending,
  accepted,
}

/// Record of an invitation (value = email, username, or phone) with status.
class EventInvitation {
  const EventInvitation({
    required this.id,
    required this.value,
    required this.method,
    required this.status,
  });
  final String id;
  final String value;
  final InviteMethod method;
  final InvitationStatus status;
}

/// Invitations per event (mock storage).
final Map<String, List<EventInvitation>> _invitationsByEvent = {};

List<EventInvitation> getInvitationsForEvent(String eventId) {
  return List.from(_invitationsByEvent[eventId] ?? []);
}

List<EventInvitation> getPendingInvitations(String eventId) {
  return getInvitationsForEvent(eventId).where((i) => i.status == InvitationStatus.pending).toList();
}

List<EventInvitation> getAcceptedInvitations(String eventId) {
  return getInvitationsForEvent(eventId).where((i) => i.status == InvitationStatus.accepted).toList();
}

void addSentInvite(String eventId, String value, InviteMethod method) {
  _invitationsByEvent[eventId] ??= [];
  final id = '${eventId}_${DateTime.now().millisecondsSinceEpoch}_${value.hashCode}';
  _invitationsByEvent[eventId]!.add(EventInvitation(
    id: id,
    value: value.trim(),
    method: method,
    status: InvitationStatus.pending,
  ));
}

void removeInvitation(String eventId, String invitationId) {
  final list = _invitationsByEvent[eventId];
  if (list == null) return;
  list.removeWhere((i) => i.id == invitationId);
}

void markInvitationAccepted(String eventId, String invitationId) {
  final list = _invitationsByEvent[eventId];
  if (list == null) return;
  final idx = list.indexWhere((i) => i.id == invitationId);
  if (idx < 0) return;
  final inv = list[idx];
  list[idx] = EventInvitation(id: inv.id, value: inv.value, method: inv.method, status: InvitationStatus.accepted);
}

/// Default invitation message template (event name is filled when loading).
String defaultInviteMessageFor(String eventName) =>
    'You\'re invited to "$eventName" on Opah. Join to see and share photos!';

/// Per-event custom invitation message (optional; null = use default).
final Map<String, String> _eventInviteMessage = {};

String? getEventInviteMessage(String eventId) => _eventInviteMessage[eventId];

void setEventInviteMessage(String eventId, String? message) {
  if (message == null || message.trim().isEmpty) {
    _eventInviteMessage.remove(eventId);
  } else {
    _eventInviteMessage[eventId] = message.trim();
  }
}

/// URL guests scan to download the app and join the event (production: opens app store, then app deep-links to add user to event).
String eventJoinUrl(String eventId) => 'https://opah.app/join/$eventId';

/// Event IDs the current user has joined by scanning the QR (or via invite link) in the app.
final Set<String> _userJoinedEventIds = {};

void joinEventViaQr(String eventId) {
  _userJoinedEventIds.add(eventId);
}

bool hasUserJoinedEvent(String eventId) => _userJoinedEventIds.contains(eventId);

/// Parses an Opah join URL and returns the event ID, or null if not valid.
String? parseJoinEventIdFromUrl(String url) {
  final uri = Uri.tryParse(url);
  if (uri == null) return null;
  if (uri.host == 'opah.app' && uri.pathSegments.length >= 2 && uri.pathSegments[0] == 'join') {
    return uri.pathSegments[1];
  }
  return null;
}

/// Invite overrides per event (so we can update invites in the mockup).
final Map<String, List<String>> _eventInviteOverrides = {};

List<String> getEffectiveInvitedUserIds(String eventId) {
  final e = eventById(eventId);
  if (e == null) return [];
  return _eventInviteOverrides[eventId] ?? e.invitedUserIds;
}

void setEventInvitedUserIds(String eventId, List<String> userIds) {
  _eventInviteOverrides[eventId] = List.from(userIds);
}

Event? getEventWithInvites(String eventId) {
  final e = eventById(eventId);
  if (e == null) return null;
  return e.copyWith(invitedUserIds: getEffectiveInvitedUserIds(eventId));
}

List<InvitableUser> get mockInvitableUsers => const [
      InvitableUser(id: 'user_2', name: 'Alex', email: 'alex@example.com'),
      InvitableUser(id: 'user_3', name: 'Sam', email: 'sam@example.com'),
      InvitableUser(id: 'user_4', name: 'Jordan', email: 'jordan@example.com'),
      InvitableUser(id: 'user_5', name: 'Taylor', email: 'taylor@example.com'),
      InvitableUser(id: 'user_6', name: 'Morgan', email: 'morgan@example.com'),
    ];

/// Display names for timeline (who took the photo).
String userNameForUserId(String userId) {
  const names = {
    'user_me': 'You',
    'user_2': 'Alex',
    'user_3': 'Sam',
    'user_4': 'Jordan',
  };
  return names[userId] ?? 'Someone';
}

/// Mock avatar URL per user (stable placeholder image).
String userAvatarUrl(String userId) =>
    'https://i.pravatar.cc/150?u=$userId';

/// Mock events: mix of owned and invited.
List<Event> get mockEvents => [
      Event(
        id: 'evt_1',
        name: 'Sarah & Mike\'s Wedding',
        type: EventType.wedding,
        isOwner: true,
        coverPhotoId: 'photo_1',
        description: 'Summer wedding at the vineyard',
        scheduledAt: DateTime(2025, 8, 16, 14, 0),
        invitedUserIds: ['user_2', 'user_3'],
      ),
      Event(
        id: 'evt_2',
        name: 'Julia\'s 30th',
        type: EventType.birthday,
        isOwner: false,
        coverPhotoId: 'photo_4',
        scheduledAt: DateTime(2025, 5, 10, 19, 0),
        invitedUserIds: ['user_me'],
      ),
      Event(
        id: 'evt_3',
        name: 'Tokyo Trip 2025',
        type: EventType.trip,
        isOwner: true,
        coverPhotoId: 'photo_7',
        scheduledAt: DateTime(2025, 3, 20, 9, 0),
        invitedUserIds: ['user_2', 'user_4'],
      ),
    ];

/// Mock people (for face filtering).
List<Person> get mockPeople => const [
      Person(id: 'person_1', name: 'Sarah'),
      Person(id: 'person_2', name: 'Mike'),
      Person(id: 'person_3', name: 'Julia'),
      Person(id: 'person_4', name: 'Alex'),
    ];

/// Mock photos with face regions (relative rect: left, top, width, height).
List<Photo> get mockPhotos {
  final now = DateTime.now();
  final list = [
    Photo(
      id: 'photo_1',
      eventId: 'evt_1',
      imageUrl: 'https://picsum.photos/800/600?random=1',
      uploadedByUserId: currentUserId,
      takenAt: now.subtract(const Duration(hours: 2)),
      faceRegions: [
        const FaceRegion(personId: 'person_1', relativeRect: (0.2, 0.3, 0.25, 0.4)),
        const FaceRegion(personId: 'person_2', relativeRect: (0.55, 0.35, 0.25, 0.35)),
      ],
    ),
    Photo(
      id: 'photo_2',
      eventId: 'evt_1',
      imageUrl: 'https://picsum.photos/800/600?random=2',
      uploadedByUserId: 'user_2',
      takenAt: now.subtract(const Duration(hours: 5)),
      faceRegions: [
        const FaceRegion(personId: 'person_1', relativeRect: (0.4, 0.25, 0.3, 0.5)),
      ],
    ),
    Photo(
      id: 'photo_3',
      eventId: 'evt_1',
      imageUrl: 'https://picsum.photos/800/600?random=3',
      uploadedByUserId: currentUserId,
      takenAt: now.subtract(const Duration(days: 1)),
      faceRegions: [
        const FaceRegion(personId: 'person_2', relativeRect: (0.3, 0.4, 0.4, 0.4)),
      ],
    ),
    Photo(
      id: 'photo_4',
      eventId: 'evt_2',
      imageUrl: 'https://picsum.photos/800/600?random=4',
      uploadedByUserId: 'user_2',
      takenAt: now.subtract(const Duration(days: 2, hours: 3)),
      faceRegions: [
        const FaceRegion(personId: 'person_3', relativeRect: (0.35, 0.3, 0.3, 0.45)),
      ],
    ),
    Photo(
      id: 'photo_5',
      eventId: 'evt_2',
      imageUrl: 'https://picsum.photos/800/600?random=5',
      uploadedByUserId: currentUserId,
      takenAt: now.subtract(const Duration(days: 3)),
      faceRegions: [
        const FaceRegion(personId: 'person_3', relativeRect: (0.25, 0.2, 0.5, 0.5)),
        const FaceRegion(personId: 'person_4', relativeRect: (0.6, 0.35, 0.25, 0.35)),
      ],
    ),
    Photo(
      id: 'photo_6',
      eventId: 'evt_2',
      imageUrl: 'https://picsum.photos/800/600?random=6',
      uploadedByUserId: 'user_2',
      takenAt: now.subtract(const Duration(days: 4, hours: 12)),
      faceRegions: [
        const FaceRegion(personId: 'person_4', relativeRect: (0.4, 0.35, 0.35, 0.4)),
      ],
    ),
    Photo(
      id: 'photo_7',
      eventId: 'evt_3',
      imageUrl: 'https://picsum.photos/800/600?random=7',
      uploadedByUserId: currentUserId,
      takenAt: now.subtract(const Duration(days: 5)),
      faceRegions: [
        const FaceRegion(personId: 'person_4', relativeRect: (0.3, 0.4, 0.35, 0.4)),
      ],
    ),
    Photo(
      id: 'photo_8',
      eventId: 'evt_3',
      imageUrl: 'https://picsum.photos/800/600?random=8',
      uploadedByUserId: 'user_2',
      takenAt: now.subtract(const Duration(days: 6)),
      faceRegions: const [],
    ),
  ];
  for (final p in list) {
    photoLikeCounts[p.id] ??= 0;
  }
  return list;
}

/// Like counts per photo (mutable; updated when user likes/unlikes).
final Map<String, int> photoLikeCounts = {};

int getPhotoLikeCount(String photoId) => photoLikeCounts[photoId] ?? 0;

void incrementPhotoLikes(String photoId) {
  photoLikeCounts[photoId] = getPhotoLikeCount(photoId) + 1;
}

void decrementPhotoLikes(String photoId) {
  final v = getPhotoLikeCount(photoId);
  if (v > 0) photoLikeCounts[photoId] = v - 1;
}

List<Photo> photosForEvent(String eventId) =>
    mockPhotos.where((p) => p.eventId == eventId).toList();

List<Photo> photosForEventFilteredByPerson(String eventId, String personId) =>
    mockPhotos
        .where((p) => p.eventId == eventId && p.personIds.contains(personId))
        .toList();

Person? personById(String id) {
  for (final p in mockPeople) {
    if (p.id == id) return p;
  }
  return null;
}

Event? eventById(String id) {
  for (final e in mockEvents) {
    if (e.id == id) return e;
  }
  return null;
}

List<Event> get eventsWithInvites =>
    mockEvents
        .map((e) => e.copyWith(invitedUserIds: getEffectiveInvitedUserIds(e.id)))
        .toList();
