import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:skh_body_builder/skh_body_builder.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  static final _router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (BuildContext _, GoRouterState __) => const HomeScreen(),
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Flutter Demo',
      theme: ThemeData(primarySwatch: Colors.blue),
      routeInformationParser: _router.routeInformationParser,
      routerDelegate: _router.routerDelegate,
      debugShowCheckedModeBanner: false,
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('BodyBuilder')),
      body: BodyBuilder(
        cacheProvider: _cacheProvider,
        dataProvider: _dataProvider,
        builder: (value) => Center(child: Text('Value: $value')),
      ),
    );
  }

  Future<int> _cacheProvider() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return 39;
  }

  Future<int> _dataProvider() async {
    await Future.delayed(const Duration(seconds: 3));
    return 42;
  }
}
