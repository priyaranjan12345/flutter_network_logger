import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_network_logger/flutter_network_logger.dart';

import 'flutter_network_logger_example.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // initialize the logger
  HttpOverrides.global = NetworkLoggerHttpOverrides();

  runApp(const ExampleApp());
}

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(colorScheme: .fromSeed(seedColor: Colors.deepPurple)),
      home: const NetworkLoggerExample(),
    );
  }
}
