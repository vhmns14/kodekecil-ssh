// KodeKecil SSH — main entry.
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/host_store.dart';
import 'theme.dart';
import 'screens/host_list_screen.dart';
import 'screens/snippets_screen.dart';
import 'screens/settings_screen.dart';

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

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'KodeKecil SSH',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: KKColors.bg,
        cardColor: KKColors.surface,
        dividerColor: KKColors.divider,
        colorScheme: const ColorScheme.dark(
          primary: KKColors.blue,
          secondary: KKColors.green,
          surface: KKColors.surface,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: KKColors.bg,
          elevation: 0,
          titleTextStyle: TextStyle(
            color: KKColors.text,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
          iconTheme: IconThemeData(color: KKColors.text),
        ),
        dialogTheme: const DialogThemeData(
          backgroundColor: KKColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(20)),
          ),
        ),
        popupMenuTheme: const PopupMenuThemeData(
          color: KKColors.surface2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(14)),
          ),
        ),
        snackBarTheme: const SnackBarThemeData(
          backgroundColor: KKColors.surface2,
          contentTextStyle: TextStyle(color: KKColors.text),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
          behavior: SnackBarBehavior.floating,
        ),
        progressIndicatorTheme: const ProgressIndicatorThemeData(
          color: KKColors.blue,
        ),
      ),
      home: const AdaptiveShell(),
    );
  }
}

/// Desktop (wide): Termius-style icon rail + content.
/// Mobile: bottom navigation bar.
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
    SettingsScreen(),
  ];

  static const _railItems = [
    (Icons.dns_rounded, Icons.dns, 'Hosts'),
    (Icons.code_rounded, Icons.code, 'Snippets'),
    (Icons.settings_outlined, Icons.settings, 'Settings'),
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth > 720;
        if (wide) return _buildRail();
        return Scaffold(
          body: _pages[_index],
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _index,
            onTap: (i) => setState(() => _index = i),
            backgroundColor: KKColors.rail,
            selectedItemColor: KKColors.blue,
            unselectedItemColor: KKColors.muted,
            type: BottomNavigationBarType.fixed,
            items: const [
              BottomNavigationBarItem(
                  icon: Icon(Icons.dns_rounded), label: 'Hosts'),
              BottomNavigationBarItem(
                  icon: Icon(Icons.code_rounded), label: 'Snippets'),
              BottomNavigationBarItem(
                  icon: Icon(Icons.settings_outlined), label: 'Settings'),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRail() {
    return Scaffold(
      body: Row(
        children: [
          Container(
            width: 76,
            color: KKColors.rail,
            child: Column(
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child:
                      Icon(Icons.bolt_rounded, color: KKColors.blue, size: 30),
                ),
                for (var i = 0; i < _railItems.length; i++) _railButton(i),
                const Spacer(),
                const Padding(
                  padding: EdgeInsets.only(bottom: 20),
                  child: Text(
                    'v0.1.0',
                    style: TextStyle(color: KKColors.muted, fontSize: 11),
                  ),
                ),
              ],
            ),
          ),
          const VerticalDivider(width: 1),
          Expanded(child: _pages[_index]),
        ],
      ),
    );
  }

  Widget _railButton(int i) {
    final selected = _index == i;
    final (outlined, filled, label) = _railItems[i];
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => setState(() => _index = i),
        child: Container(
          width: 60,
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? KKColors.surface2 : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            children: [
              Icon(
                selected ? filled : outlined,
                color: selected ? KKColors.blue : KKColors.muted,
                size: 24,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: selected ? KKColors.text : KKColors.muted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
