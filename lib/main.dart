import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'features/game/board_screen.dart';

void main() => runApp(const ProviderScope(child: SuperChessApp()));

class SuperChessApp extends StatelessWidget {
  const SuperChessApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Super Chess',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF6E8C57)),
        useMaterial3: true,
      ),
      home: const BoardScreen(),
    );
  }
}
