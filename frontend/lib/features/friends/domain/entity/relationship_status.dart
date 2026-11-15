/// State of a friendship record. REMOVED is a past friendship, never a
/// current friend.
enum RelationshipStatus {
  pending,
  accepted,
  declined,
  cancelled,
  removed;

  bool get isPending => this == pending;
}
