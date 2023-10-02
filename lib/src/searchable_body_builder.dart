import 'dart:async';

import 'package:flutter/material.dart';
import 'package:skh_body_builder/src/body_builder.dart';

abstract class SearchableStateProvider<T> extends StateProvider<T> {
  @override
  T? items([String? query]) => null;

  @override
  bool hasData([String? query]) => false;

  bool hasMore([String? query]) => false;
}

class _StateProviderWrapper<T> extends StateProvider<T> {
  final TextEditingController? searchController;
  final SearchableStateProvider<T> stateProvider;

  _StateProviderWrapper({
    required this.searchController,
    required this.stateProvider,
  });

  @override
  void addListener(VoidCallback listener) {
    searchController?.addListener(listener);
    stateProvider.addListener(listener);
    super.addListener(listener);
  }

  @override
  void removeListener(VoidCallback listener) {
    searchController?.removeListener(listener);
    stateProvider.removeListener(listener);
    super.removeListener(listener);
  }

  @override
  T? items() => stateProvider.items(searchController?.text);

  @override
  bool hasData() => stateProvider.hasData(searchController?.text) == true;
}

typedef SearchableCacheProvider<T> = Future<T?> Function(String query);
typedef SearchableDataProvider<T> = Future<T> Function(String query);

class PaginatedBodyBuilder<T> extends StatefulWidget {
  final TextEditingController? searchController;
  final ChildBodyBuilder<T>? builder;
  final CustomBuilder<T>? customBuilder;
  final SearchableStateProvider<T>? stateProvider;
  final SearchableCacheProvider<T>? cacheProvider;
  final SearchableDataProvider<T> dataProvider;
  final Widget? progressBuilder;
  final PlaceHolderBuilder placeHolderBuilder;
  final bool toastEnabled;
  final Duration? animationDuration;
  final Duration searchDelay;

  const PaginatedBodyBuilder({
    this.searchController,
    this.toastEnabled = false,
    this.animationDuration = const Duration(milliseconds: 150),
    this.searchDelay = const Duration(milliseconds: 400),
    this.stateProvider,
    this.cacheProvider,
    required this.dataProvider,
    this.progressBuilder,
    this.placeHolderBuilder = defaultPlaceHolderBuilder,
    this.customBuilder,
    this.builder,
    super.key,
  })  : assert(
          builder == null || customBuilder == null,
          'Both builders have been provided, but only one can be supported',
        ),
        assert(
          builder != null || customBuilder != null,
          'A valid builder is required',
        );

  @override
  State<PaginatedBodyBuilder<T>> createState() =>
      PaginatedBodyBuilderState<T>();
}

class PaginatedBodyBuilderState<T> extends State<PaginatedBodyBuilder<T>> {
  final GlobalKey<BodyBuilderState<T>> _key = GlobalKey();
  StreamSubscription? _subscription;

  String get _query => widget.searchController?.text ?? '';

  bool get hasError => _key.currentState?.hasError == true;

  Object? get error => _key.currentState?.error;

  StackTrace? get errorStack => _key.currentState?.errorStack;

  bool get hasData => _key.currentState?.hasData == true;

  bool get isLoading => _key.currentState?.isLoading == true;

  @override
  Widget build(BuildContext context) {
    return BodyBuilder<T>(
      key: _key,
      animationDuration: widget.animationDuration,
      stateProvider: widget.stateProvider == null
          ? null
          : _StateProviderWrapper<T>(
              searchController: widget.searchController,
              stateProvider: widget.stateProvider!,
            ),
      cacheProvider: widget.cacheProvider == null
          ? null
          : () => widget.cacheProvider!(_query),
      dataProvider: () => widget.dataProvider(_query),
      placeHolderBuilder: widget.placeHolderBuilder,
      progressBuilder: widget.progressBuilder,
      customBuilder: widget.customBuilder,
      builder: widget.builder,
    );
  }

  Future<void>? fetch({
    bool allowState = false,
    bool allowCache = false,
    bool clearData = false,
    bool ignoreLoading = false,
  }) =>
      _key.currentState?.fetch(
        allowState: allowState,
        allowCache: allowCache,
        clearData: clearData,
        ignoreLoading: ignoreLoading,
      );

  Future<void>? retry() => _key.currentState?.retry();

  @override
  void initState() {
    widget.searchController?.addListener(delayedFetch);
    super.initState();
  }

  @override
  void dispose() {
    widget.searchController?.removeListener(delayedFetch);
    _subscription?.cancel();
    super.dispose();
  }

  void loadMoreIfNeeded() {
    if (_hasMore()) {
      _loadNextPage();
    }
  }

  bool _hasMore() =>
      widget.stateProvider?.hasMore(widget.searchController?.text) == true;

  void _loadNextPage() => WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          fetch();
        }
      });

  void delayedFetch({
    bool allowState = true,
    bool allowCache = true,
    bool clearData = true,
  }) {
    _subscription?.cancel();
    _subscription =
        Future.delayed(widget.searchDelay).asStream().listen((event) {
      if (mounted) {
        fetch(
          allowState: allowState,
          allowCache: allowCache,
          clearData: clearData,
          ignoreLoading: true,
        );
      }
    });
  }
}
