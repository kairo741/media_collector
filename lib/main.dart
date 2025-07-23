import 'package:flutter/material.dart';
import 'package:media_collector/ui/pages/home_screen.dart' show HomeScreen;
import 'package:media_collector/ui/providers/media_provider.dart';
import 'package:media_collector/ui/theme/theme.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(const MediaCollectorApp());
}

class MediaCollectorApp extends StatelessWidget {
  const MediaCollectorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => MediaProvider(),
      child: MaterialApp(
        title: 'Media Collector',
        theme: MaterialTheme(ThemeData.dark().textTheme).dark(),
        home: const HomeScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
