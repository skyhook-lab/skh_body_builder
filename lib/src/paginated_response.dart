abstract mixin class PaginatedResponse<T> {
  List<T>? items;

  bool isEmpty() => items?.isNotEmpty != true;

  bool isNextPageOf(PaginatedResponse<T> other);

  bool hasMore();

  // This class is intended to be used as a mixin, and should not be
  // extended directly.
  factory PaginatedResponse._() => throw Exception('No');
}
