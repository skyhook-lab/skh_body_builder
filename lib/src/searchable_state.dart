import 'package:flutter/material.dart';
import 'package:skh_body_builder/skh_body_builder.dart';
import 'package:skh_body_builder/src/utils/tools.dart';

abstract class RelatedSearchableStates<K, T> extends ChangeNotifier {
  final Map<K, SearchableState<T>> _states = {};

  RelatedSearchableStates();

  SearchableState<T> byId(K id) {
    if (!_states.containsKey(id)) {
      _states[id] = SearchableState<T>();
    }
    return _states[id]!;
  }

  void clear() {
    _states.clear();
    notifyListeners();
  }
}

abstract class RelatedValueStates<K, T> extends ChangeNotifier {
  final Map<K, ValueStateProvider<T>> _values = {};

  RelatedValueStates();

  ValueStateProvider<T> byId(K id) {
    if (!_values.containsKey(id)) {
      _values[id] = ValueStateProvider<T>();
    }
    return _values[id]!;
  }

  void clear() {
    _values.clear();
    notifyListeners();
  }
}

class ValueStateProvider<T> extends StateProvider<T> {
  T? _value;

  @override
  T? items() => _value;

  @override
  bool hasData() => _value != null;

  ValueStateProvider();

  T onValue(T value) {
    _value = value;
    notifyListeners();
    return value;
  }

  void clear() {
    _value = null;
    notifyListeners();
  }
}

class SearchableState<T> extends SearchableStateProvider<Iterable<T>> {
  SearchableState();

  final Map<String, DataState<T>> _states = {};

  @override
  Iterable<T> items([String? query]) => get(_toKey(query)).items;

  @override
  bool hasData([String? query]) => get(_toKey(query)).hasData;

  @override
  bool hasMore([String? query]) => get(_toKey(query)).hasMore;

  DataState<T> get(String query) => _states[_toKey(query)] ??= DataState();

  Iterable<T> onFetch(PaginatedResponse<T> response, {String? query}) =>
      get(query ?? '').onFetch(response);

  String _toKey(String? query) => query?.toLowerCase() ?? '';

  void clear() => _states.clear();

  void remove([String? query]) => _states.remove(_toKey(query));

  T? where(bool Function(T) test) =>
      _states.values.expand((element) => element.items).firstWhereOrNull(test);
}

class DataState<T> {
  DataState();

  List<T>? _items;
  PaginatedResponse<T>? _pagination;

  Iterable<T> get items => _items ?? [];

  bool get hasData => _items != null;

  bool get hasMore => _pagination == null || _pagination?.hasMore() == true;

  PaginatedResponse<T>? get pagination => _pagination;

  T add(T item) {
    _items ??= [];
    _items!.add(item);
    return item;
  }

  void remove(T item) => _items?.remove(item);

  void removeWhere(bool Function(T element) test) => _items?.removeWhere(test);

  void updateOrAdd(T item) {
    _items?.remove(item);
    add(item);
  }

  void update(T item) {
    final int index = _items?.indexWhere((element) => element == item) ?? -1;

    if (index >= 0) {
      _items![index] = item;
    }
  }

  Iterable<T> onFetch(PaginatedResponse<T> response) {
    _items ??= [];
    if (response.isEmpty()) {
      if (_pagination?.hasMore() == true) {
        debugPrint(
          'Inconsistent pagination of $T detected. Page $response'
          ' is empty but we expected more data. ',
        );
      }
      _pagination = response;
      return _items!;
    }
    if (_pagination != null && !response.isNextPageOf(_pagination!)) {
      // We have received a page that we already got or that is not the next one, skip.
      debugPrint('Inconsistent pagination of $T detected. '
          'The current page is $_pagination, we just received $response. '
          'But the #isNextPageOf validation failed.');
      return _items!;
    }
    _items!.removeWhere((e) => response.items!.contains(e));
    _items!.addAll(response.items!);
    _pagination = response;
    return _items!;
  }
}
