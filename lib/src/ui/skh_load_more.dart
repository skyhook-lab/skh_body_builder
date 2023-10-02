import 'package:flutter/material.dart';
import 'package:skh_body_builder/src/searchable_body_builder.dart';

typedef SkhErrorLoadMoreMessage = String Function(
  BuildContext context,
  Object? error,
);

SkhErrorLoadMoreMessage skhErrorMessage =
    (context, error) => error?.toString() ?? 'Failed to load more, try again';

class SkhLoadMore extends StatefulWidget {
  final GlobalKey<PaginatedBodyBuilderState>? bodyBuilderKey;
  final bool showSpinner;
  final Widget Function(BuildContext, PaginatedBodyBuilderState) errorBuilder;
  final Widget Function() loadingBuilder;

  const SkhLoadMore(
    this.bodyBuilderKey, {
    super.key,
    this.showSpinner = true,
    this.errorBuilder = defaultSkhPlaceholderBuilder,
    this.loadingBuilder = defaultSkhLoadingBuilder,
  });

  @override
  State<SkhLoadMore> createState() => _SkhLoadMoreState();
}

class _SkhLoadMoreState extends State<SkhLoadMore> {
  @override
  void initState() {
    widget.bodyBuilderKey?.currentState?.loadMoreIfNeeded();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    PaginatedBodyBuilderState? state = widget.bodyBuilderKey?.currentState;
    if (state == null) {
      return const SizedBox.shrink();
    }
    if (state.hasError == true) {
      return widget.errorBuilder(context, state);
    }
    if (state.isLoading == true && widget.showSpinner) {
      return widget.loadingBuilder();
    }
    return const SizedBox.shrink();
  }
}

Widget defaultSkhLoadingBuilder() {
  return const Center(
    child: Padding(
      padding: EdgeInsets.all(16),
      child: CircularProgressIndicator(),
    ),
  );
}

Widget defaultSkhPlaceholderBuilder(
  BuildContext context,
  PaginatedBodyBuilderState state,
) {
  return GestureDetector(
    onTap: state.loadMoreIfNeeded,
    child: Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  skhErrorMessage(context, state.error),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const Icon(Icons.refresh_rounded, size: 20),
          ],
        ),
      ),
    ),
  );
}
