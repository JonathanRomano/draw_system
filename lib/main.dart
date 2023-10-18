import "package:flutter/material.dart";
import "package:draw_system/screens/home_page.dart";
import "package:flutter_dotenv/flutter_dotenv.dart";

void main() async {
  await dotenv.load();
  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "XMAS WINDOW",
      home: const HomePage(),
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueGrey),
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}
