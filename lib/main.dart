import 'package:flutter/material.dart';
import 'package:map_assessment/src/presentation/screens/map_screen.dart';
import 'package:map_assessment/src/services/map_service.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => MapService(),
      child: MaterialApp(
        title: 'Flutter Google Maps',
        darkTheme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        themeMode: ThemeMode.dark,
        home: const MapScreen(),
      ),
    );
  }
}
