/// A rectangular region representing a face in a photo (for tap-to-filter).
class FaceRegion {
  const FaceRegion({
    required this.personId,
    required this.relativeRect,
  });

  /// Id of the [Person] this face corresponds to.
  final String personId;
  /// Fractional rect (0–1) within the image: left, top, width, height.
  final (double, double, double, double) relativeRect;
}

/// A photo in an event, possibly with tagged faces.
class Photo {
  const Photo({
    required this.id,
    required this.eventId,
    required this.imageUrl,
    required this.uploadedByUserId,
    this.faceRegions = const [],
    this.takenAt,
  });

  final String id;
  final String eventId;
  /// Asset path or network URL.
  final String imageUrl;
  final String uploadedByUserId;
  final List<FaceRegion> faceRegions;
  final DateTime? takenAt;

  /// Person ids that appear in this photo.
  List<String> get personIds =>
      faceRegions.map((r) => r.personId).toSet().toList();
}
