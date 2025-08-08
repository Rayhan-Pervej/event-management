import 'package:event_management/core/theme/theme_provider.dart';
import 'package:event_management/ui/widgets/default_appbar.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class HomePage extends StatefulWidget {
  final String pageName;
  const HomePage({super.key, required this.pageName});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _counter = 0;

  void _incrementCounter() => setState(() => _counter++);

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: DefaultAppBar(
        title: widget.pageName,
        elevation: 0,
        isShowBackButton: false,
      ),

      body: Center(child: Text('Home')),
    );
  }
}
