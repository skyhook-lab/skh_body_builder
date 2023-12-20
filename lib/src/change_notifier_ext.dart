import 'package:flutter/cupertino.dart';
import 'package:skh_body_builder/skh_body_builder.dart';

typedef StateConvertor<T, C extends ChangeNotifier> = T? Function(
  C changeNotifier,
);

class CustomStateProvider<T, C extends ChangeNotifier>
    extends SearchableStateProvider<T> {
  final C changeNotifier;
  final StateConvertor<T, C> convertor;

  CustomStateProvider({required this.changeNotifier, required this.convertor});

  @override
  void addListener(VoidCallback listener) =>
      changeNotifier.addListener(listener);

  @override
  void removeListener(VoidCallback listener) =>
      changeNotifier.removeListener(listener);

  @override
  T? items([String? query]) => convertor(changeNotifier);

  @override
  bool hasData([String? query]) => convertor(changeNotifier) != null;

  @override
  bool hasMore([String? query]) => false;
}

extension ChangeNotifierExt<C extends ChangeNotifier> on C {
  SearchableStateProvider<T> map<T>(StateConvertor<T, C> state) =>
      CustomStateProvider<T, C>(changeNotifier: this, convertor: state);
}
