import '../models/event.dart';
import '../models/person.dart';
import '../models/photo.dart';

/// Current user id (for "my events" vs "invited").
const String currentUserId = 'user_me';

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
List<Photo> get mockPhotos => [
      Photo(
        id: 'photo_1',
        eventId: 'evt_1',
        imageUrl: 'https://picsum.photos/800/600?random=1',
        uploadedByUserId: currentUserId,
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
        faceRegions: [
          const FaceRegion(personId: 'person_1', relativeRect: (0.4, 0.25, 0.3, 0.5)),
        ],
      ),
      Photo(
        id: 'photo_3',
        eventId: 'evt_1',
        imageUrl: 'https://picsum.photos/800/600?random=3',
        uploadedByUserId: currentUserId,
        faceRegions: [
          const FaceRegion(personId: 'person_2', relativeRect: (0.3, 0.4, 0.4, 0.4)),
        ],
      ),
      Photo(
        id: 'photo_4',
        eventId: 'evt_2',
        imageUrl: 'https://picsum.photos/800/600?random=4',
        uploadedByUserId: 'user_2',
        faceRegions: [
          const FaceRegion(personId: 'person_3', relativeRect: (0.35, 0.3, 0.3, 0.45)),
        ],
      ),
      Photo(
        id: 'photo_5',
        eventId: 'evt_2',
        imageUrl: 'https://picsum.photos/800/600?random=5',
        uploadedByUserId: currentUserId,
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
        faceRegions: [
          const FaceRegion(personId: 'person_4', relativeRect: (0.4, 0.35, 0.35, 0.4)),
        ],
      ),
      Photo(
        id: 'photo_7',
        eventId: 'evt_3',
        imageUrl: 'https://picsum.photos/800/600?random=7',
        uploadedByUserId: currentUserId,
        faceRegions: [
          const FaceRegion(personId: 'person_4', relativeRect: (0.3, 0.4, 0.35, 0.4)),
        ],
      ),
      Photo(
        id: 'photo_8',
        eventId: 'evt_3',
        imageUrl: 'https://picsum.photos/800/600?random=8',
        uploadedByUserId: 'user_2',
        faceRegions: [],
      ),
    ];

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
