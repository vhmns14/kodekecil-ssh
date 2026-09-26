// KodeKecil SSH — Termius-inspired design tokens and shared widgets.
import 'package:flutter/material.dart';

/// Dark navy palette modeled after the Termius look:
//  deep background, lifted cards, one strong blue accent.
class KKColors {
  static const bg = Color(0xFF141724);
  static const rail = Color(0xFF191D2B);
  static const surface = Color(0xFF222839);
  static const surface2 = Color(0xFF2A3042);
  static const divider = Color(0xFF2E3448);
  static const blue = Color(0xFF2E9BFF);
  static const green = Color(0xFF3ED598);
  static const red = Color(0xFFFF6B6B);
  static const text = Color(0xFFFFFFFF);
  static const muted = Color(0xFF9AA1B5);
  static const terminalBg = Color(0xFF0B0D13);

  /// Brand-ish tile colors (Termius paints one OS tile per host).
  static const tilePalette = [
    Color(0xFF3B82F6), // blue
    Color(0xFFF97316), // orange
    Color(0xFFEC4899), // pink
    Color(0xFF14B8A6), // teal
    Color(0xFF8B5CF6), // purple
    Color(0xFF22C55E), // green
    Color(0xFFF59E0B), // amber
    Color(0xFF06B6D4), // cyan
  ];

  /// Deterministic tile color from any string (stable across restarts).
  static Color tileColorFor(String seed) {
    var h = 0;
    for (final c in seed.codeUnits) {
      h = (h * 31 + c) & 0x7fffffff;
    }
    return tilePalette[h % tilePalette.length];
  }
}

/// Big bold section header, e.g. "Groups", "Hosts".
class SectionTitle extends StatelessWidget {
  final String text;
  const SectionTitle(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: KKColors.text,
        ),
      ),
    );
  }
}

/// Rounded-square icon tile, Termius host style.
class HostTile extends StatelessWidget {
  final Color color;
  final IconData icon;
  final double size;

  const HostTile({
    super.key,
    required this.color,
    this.icon = Icons.dns_rounded,
    this.size = 52,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(size * 0.28),
      ),
      child: Icon(icon, color: Colors.white, size: size * 0.52),
    );
  }
}

/// Rounded search field.
class KKSearchField extends StatelessWidget {
  final ValueChanged<String> onChanged;
  final String hint;

  const KKSearchField({
    super.key,
    required this.onChanged,
    this.hint = 'Search',
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
      child: TextField(
        onChanged: onChanged,
        style: const TextStyle(color: KKColors.text),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: KKColors.muted),
          prefixIcon: const Icon(Icons.search, color: KKColors.muted),
          filled: true,
          fillColor: KKColors.surface,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}

/// Termius-style Date/Name segmented sort control.
class SortSegmented extends StatelessWidget {
  final bool sortByName;
  final ValueChanged<bool> onChanged;

  const SortSegmented({
    super.key,
    required this.sortByName,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    Widget seg(String label, bool active) {
      return GestureDetector(
        onTap: () => onChanged(label == 'Name'),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
          decoration: BoxDecoration(
            color: active ? KKColors.green : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: active ? KKColors.bg : KKColors.green,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        border: Border.all(color: KKColors.green, width: 1.5),
        borderRadius: BorderRadius.circular(11),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [seg('Date', !sortByName), seg('Name', sortByName)],
      ),
    );
  }
}

/// Full-width blue button (Termius "Connect").
class WideBlueButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;

  const WideBlueButton({super.key, required this.label, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: KKColors.blue,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
        ),
        child: Text(label),
      ),
    );
  }
}

/// Labeled section card used by the host editor.
class EditorSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const EditorSection({super.key, required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 18, 4, 8),
          child: Text(
            title,
            style: const TextStyle(fontSize: 15, color: KKColors.muted),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: KKColors.surface,
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(children: children),
        ),
      ],
    );
  }
}

/// Rounded text field for the host editor.
class EditorField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final TextInputType keyboardType;
  final int maxLines;
  final bool obscure;

  const EditorField({
    super.key,
    required this.controller,
    required this.label,
    this.keyboardType = TextInputType.text,
    this.maxLines = 1,
    this.obscure = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        obscureText: obscure,
        style: const TextStyle(color: KKColors.text),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: KKColors.muted),
          filled: true,
          fillColor: KKColors.surface2,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
      ),
    );
  }
}
