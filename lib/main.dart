import 'package:flutter/material.dart';
import 'package:media_collector/ui/pages/home_screen.dart' show HomeScreen;
import 'package:media_collector/ui/providers/media_provider.dart';
import 'package:media_collector/ui/theme/theme.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializa o MediaProvider que também inicializa o SettingsService
  final mediaProvider = MediaProvider();
  await mediaProvider.initialize();
  
  runApp(MediaCollectorApp(mediaProvider: mediaProvider));
}

class MediaCollectorApp extends StatelessWidget {
  final MediaProvider mediaProvider;
  
  const MediaCollectorApp({super.key, required this.mediaProvider});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: mediaProvider,
      child: MaterialApp(
        title: 'Media Collector',
        theme: MaterialTheme(ThemeData.dark().textTheme).dark(),
        home: const HomeScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
