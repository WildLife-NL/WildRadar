import 'package:flutter/material.dart';
import 'pages/login_screen.dart';
import 'pages/mapping_page.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async{
  await dotenv.load(fileName: 'lib/assets/env/.env');
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: LoginPage(), //startpagina
      routes: {
        '/second': (context) => MappingPage(), //voeg een route toe naar de 2de pagina
      },
    );
  }
}