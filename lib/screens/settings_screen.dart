// KodeKecil SSH — Settings / about screen.
import 'package:flutter/material.dart';
import '../theme.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: [
            const Text(
              'Settings',
              style: TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.w800,
                color: KKColors.text,
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(4, 20, 4, 12),
              child: Text('About',
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: KKColors.text)),
            ),
            _card(
              children: [
                _row(Icons.bolt_rounded, KKColors.blue, 'KodeKecil SSH',
                    'v0.1.0'),
                _row(Icons.balance_rounded, KKColors.green, 'License',
                    'MIT — free forever'),
                _row(Icons.code_rounded, KKColors.tilePalette[4], 'Source',
                    'github.com/vhmns14/kodekecil-ssh'),
              ],
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(4, 20, 4, 12),
              child: Text('Security',
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: KKColors.text)),
            ),
            _card(
              children: [
                _row(Icons.key_rounded, KKColors.tilePalette[6], 'Passwords',
                    'Asked on connect, never stored'),
                _row(Icons.vpn_key_outlined, KKColors.tilePalette[3],
                    'Private keys', 'Kept in the OS keyring only'),
                _row(Icons.cloud_off_outlined, KKColors.muted, 'Telemetry',
                    'None. Local-first by design'),
              ],
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(4, 24, 4, 0),
              child: Text(
                'Termius, but cheapest.',
                style: TextStyle(color: KKColors.muted, fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _card({required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: KKColors.surface,
        borderRadius: BorderRadius.circular(18),
      ),
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(children: children),
    );
  }

  Widget _row(IconData icon, Color color, String title, String sub) {
    return ListTile(
      leading: HostTile(color: color, icon: icon, size: 44),
      title: Text(title,
          style: const TextStyle(
              fontWeight: FontWeight.w700, color: KKColors.text)),
      subtitle: Text(sub,
          style: const TextStyle(color: KKColors.muted, fontSize: 13)),
    );
  }
}
