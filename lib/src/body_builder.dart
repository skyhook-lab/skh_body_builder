import 'dart:async';

import 'package:flutter/material.dart';
import 'package:skh_body_builder/src/ui/skh_load_more.dart';

abstract class StateProvider<T> extends ChangeNotifier {
  T? items() => null;

  bool hasData() => false;
}

typedef CustomBuilder<T> = Widget Function(
  bool isLoading,
  dynamic error,
  T? data,
);
typedef ChildBodyBuilder<T> = Widget Function(T data);
typedef CacheProvider<T> = Future<T?> Function();
typedef DataProvider<T> = Future<T> Function();
typedef PlaceHolderBuilder = Widget Function(
    Object? error, StackTrace? errorStack, VoidCallback onRetry);

Widget defaultProgressBuilder() => const Padding(
      padding: EdgeInsets.all(16),
      child: Center(child: CircularProgressIndicator()),
    );

Widget defaultPlaceHolderBuilder(
        Object? error, StackTrace? errorStack, VoidCallback onRetry) =>
    ScrollConfiguration(
      behavior: const MaterialScrollBehavior().copyWith(overscroll: false),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Builder(builder: (context) {
                return Center(
                  child: Text(
                    skhErrorMessage(context, error),
                    textAlign: TextAlign.center,
                  ),
                );
              }),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: onRetry,
                child: const Text('Try again'),
              ),
            ],
          ),
        ),
      ),
    );

class BodyBuilder<T> extends StatefulWidget {
  final ChildBodyBuilder<T>? builder;
  final CustomBuilder<T>? customBuilder;
  final StateProvider<T>? stateProvider;
  final CacheProvider<T>? cacheProvider;
  final DataProvider<T> dataProvider;
  final Widget? progressBuilder;
  final PlaceHolderBuilder placeHolderBuilder;
  final bool listenState;
  final bool fetchDataIfState;
  final Duration? animationDuration;

  const BodyBuilder({
    this.listenState = true,
    this.fetchDataIfState = false,
    this.animationDuration = const Duration(milliseconds: 150),
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
  BodyBuilderState<T> createState() => BodyBuilderState<T>();
}

class BodyBuilderState<T> extends State<BodyBuilder<T>> {
  StreamSubscription? _subscription;
  bool _isCache = false;
  T? _data;
  bool _isLoading = true;
  Object? _error;
  StackTrace? _errorStack;

  bool get isLoading => _isLoading;

  bool get hasData => _data != null;

  bool get hasError => _error != null;

  Object? get error => _error;

  StackTrace? get errorStack => _errorStack;

  @override
  void initState() {
    if (widget.listenState) {
      widget.stateProvider?.addListener(_onStateChanged);
    }
    _loadState();
    super.initState();
  }

  @override
  Widget build(BuildContext context) =>
      (widget.animationDuration?.inMilliseconds ?? 0) == 0
          ? _buildMainContent()
          : AnimatedSwitcher(
              duration: widget.animationDuration!,
              child: _buildMainContent(),
            );

  Widget _buildMainContent() {
    if (_data == null && widget.customBuilder == null) {
      if (_error != null) {
        return _buildError();
      }
      return _buildProgressIndicator();
    }

    return widget.customBuilder?.call(_isLoading, _error, _data) ??
        widget.builder!.call(_data as T);
  }

  Widget _buildProgressIndicator() =>
      widget.progressBuilder ?? defaultProgressBuilder();

  Widget _buildError() =>
      widget.placeHolderBuilder(_error!, _errorStack, retry);

  Future<void> _onStateChanged() async {
    return _loadState(fetchData: widget.fetchDataIfState);
  }

  Future<void> _loadState({bool fetchData = true}) async {
    if (fetchData && widget.stateProvider?.hasData() != true) {
      _loadCache();
      return;
    }
    setState(() {
      _error = null;
      _errorStack = null;
      _isCache = false;
      _isLoading = false;
      _data = widget.stateProvider?.items();
    });

    if (widget.fetchDataIfState) {
      _loadCache();
    }
  }

  Future<void> _loadCache() async {
    if (widget.cacheProvider == null) {
      _loadData();
      return;
    }
    _subscription?.cancel();
    _subscription = widget.cacheProvider!().asStream().listen(
      (data) {
        if (!mounted) return;
        setState(() {
          _error = null;
          _errorStack = null;
          _isCache = data != null;
          _data = data;
        });
        _loadData();
      },
      onError: (e, s) {
        if (!mounted) return;
        debugPrint('$e $s');
        setState(() {
          _error = e;
          _errorStack = s;
          _isLoading = false;
        });
      },
    );
  }

  Future<void> fetch({
    bool allowState = false,
    bool allowCache = false,
    bool clearData = false,
    bool ignoreLoading = false,
  }) async {
    if (!ignoreLoading && _isLoading) {
      // Use cases:
      // We want to ignore while loading more paginated datas
      // But we don't want to ignore if the search query changes while loading
      return;
    }

    // addPostFrameCallback is necessary here because before calling #fetch
    // we often do a setState in the parent widget that will modify the
    // values of the body builder providers.
    // We want to wait for the next frame to be sure to be up to date with
    // an eventual setState
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _isLoading = true;
          _isCache = false;
          _error = null;
          _errorStack = null;
          if (clearData) {
            _data = null;
          }
        });
        if (allowState) {
          _loadState();
        } else if (allowCache) {
          _loadCache();
        } else {
          _loadData();
        }
      }
    });
  }

  Future<void> retry() async {
    if (!_isCache && _data != null) {
      return;
    }
    setState(() {
      _isLoading = true;
      _error = null;
      _errorStack = null;
    });
    if (!_isCache) {
      _loadCache();
    } else {
      _loadData();
    }
  }

  Future<void> _loadData() async {
    _subscription?.cancel();
    _subscription = widget.dataProvider().asStream().listen(
      (data) {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
          _error = null;
          _errorStack = null;
          _isCache = false;
          _data = data;
        });
      },
      onError: (e, s) {
        if (!mounted) return;
        debugPrint('$e $s');
        setState(() {
          _error = e;
          _errorStack = s;
          _isLoading = false;
        });
      },
    );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    if (widget.listenState) {
      widget.stateProvider?.removeListener(_onStateChanged);
    }
    super.dispose();
  }
}
