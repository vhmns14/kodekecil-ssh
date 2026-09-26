// KodeKecil SSH — main entry.
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/host_store.dart';
import 'screens/host_list_screen.dart';
import 'screens/snippets_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final store = HostStore();
  await store.load();
  runApp(
    ChangeNotifierProvider.value(
      value: store,
      child: const KodeKecilSSHApp(),
    ),
  );
}

class KodeKecilSSHApp extends StatelessWidget {
  const KodeKecilSSHApp({super.key});

  static const _bg = Color(0xFF0B0E14);
  static const _surface = Color(0xFF11151D);
  static const _accent = Color(0xFF2F81F7); // biru. 💙

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'KodeKecil SSH',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: _bg,
        cardColor: _surface,
        colorScheme: const ColorScheme.dark(
          primary: _accent,
          secondary: _accent,
          surface: _surface,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: _surface,
          elevation: 0,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: _bg,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFF232A36)),
          ),
        ),
        snackBarTheme: const SnackBarThemeData(
          backgroundColor: _surface,
        ),
      ),
      home: const AdaptiveShell(),
    );
  }
}

/// Desktop (wide): sidebar + content. Mobile: bottom nav.
class AdaptiveShell extends StatefulWidget {
  const AdaptiveShell({super.key});

  @override
  State<AdaptiveShell> createState() => _AdaptiveShellState();
}

class _AdaptiveShellState extends State<AdaptiveShell> {
  int _index = 0;

  static const _pages = [
    HostListScreen(),
    SnippetsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth > 720;
        if (wide) {
          return Scaffold(
            body: Row(
              children: [
                NavigationRail(
                  selectedIndex: _index,
                  onDestinationSelected: (i) => setState(() => _index = i),
                  labelType: NavigationRailLabelType.all,
                  destinations: const [
                    NavigationRailDestination(
                      icon: Icon(Icons.dns_outlined),
                      selectedIcon: Icon(Icons.dns),
                      label: Text('Hosts'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.terminal_outlined),
                      selectedIcon: Icon(Icons.terminal),
                      label: Text('Snippets'),
                    ),
                  ],
                  leading: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Icon(Icons.bolt, color: Color(0xFF2F81F7), size: 28),
                  ),
                ),
                const VerticalDivider(width: 1),
                Expanded(child: _pages[_index]),
              ],
            ),
          );
        }
        return Scaffold(
          body: _pages[_index],
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _index,
            onTap: (i) => setState(() => _index = i),
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.dns), label: 'Hosts'),
              BottomNavigationBarItem(icon: Icon(Icons.terminal), label: 'Snippets'),
            ],
          ),
        );
      },
    );
  }
}
