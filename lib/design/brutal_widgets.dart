import 'package:flutter/material.dart';

import 'brutal_theme.dart';

class BrutalPressable extends StatefulWidget {
  const BrutalPressable({
    required this.child,
    required this.onPressed,
    this.backgroundColor = BrutalColors.yellow,
    this.foregroundColor = BrutalColors.ink,
    this.shadowColor = BrutalColors.ink,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    super.key,
  });

  final Widget child;
  final VoidCallback? onPressed;
  final Color backgroundColor;
  final Color foregroundColor;
  final Color shadowColor;
  final EdgeInsets padding;

  @override
  State<BrutalPressable> createState() => _BrutalPressableState();
}

class _BrutalPressableState extends State<BrutalPressable> {
  bool pressed = false;

  @override
  Widget build(BuildContext context) {
    final isEnabled = widget.onPressed != null;
    final offset = pressed && isEnabled ? 4.0 : 0.0;
    return GestureDetector(
      onTap: widget.onPressed,
      onTapDown: isEnabled ? (_) => setState(() => pressed = true) : null,
      onTapCancel: isEnabled ? () => setState(() => pressed = false) : null,
      onTapUp: isEnabled ? (_) => setState(() => pressed = false) : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 80),
        curve: Curves.linear,
        transform: Matrix4.translationValues(offset, offset, 0),
        padding: widget.padding,
        decoration: BoxDecoration(
          color: isEnabled ? widget.backgroundColor : Colors.grey,
          border: Border.all(color: widget.foregroundColor, width: 3),
          boxShadow: offset == 0
              ? [
                  BoxShadow(
                    color: widget.shadowColor,
                    offset: const Offset(4, 4),
                  ),
                ]
              : const [],
        ),
        child: DefaultTextStyle(
          style: TextStyle(
            color: widget.foregroundColor,
            fontWeight: FontWeight.w900,
            letterSpacing: 1,
          ),
          child: widget.child,
        ),
      ),
    );
  }
}

class BrutalCard extends StatelessWidget {
  const BrutalCard({
    required this.child,
    this.backgroundColor,
    this.padding = const EdgeInsets.all(16),
    super.key,
  });

  final Widget child;
  final Color? backgroundColor;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final foreground = Theme.of(context).colorScheme.onSurface;
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor ?? Theme.of(context).scaffoldBackgroundColor,
        border: Border.all(color: foreground, width: 3),
        boxShadow: [BoxShadow(color: foreground, offset: const Offset(4, 4))],
      ),
      child: child,
    );
  }
}

class BrutalChip extends StatelessWidget {
  const BrutalChip({
    required this.label,
    this.selected = false,
    this.onPressed,
    super.key,
  });

  final String label;
  final bool selected;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return BrutalPressable(
      onPressed: onPressed,
      backgroundColor: selected
          ? BrutalColors.blue
          : Theme.of(context).scaffoldBackgroundColor,
      foregroundColor: selected
          ? BrutalColors.paper
          : Theme.of(context).colorScheme.onSurface,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      child: Text(label.toUpperCase()),
    );
  }
}

class BrutalProgressBar extends StatelessWidget {
  const BrutalProgressBar({required this.value, super.key});

  final double value;

  @override
  Widget build(BuildContext context) {
    final foreground = Theme.of(context).colorScheme.onSurface;
    final segments = (value.clamp(0, 1) * 10).round();
    return Row(
      children: List.generate(
        10,
        (index) => Expanded(
          child: Container(
            height: 18,
            margin: EdgeInsets.only(right: index == 9 ? 0 : 2),
            decoration: BoxDecoration(
              color: index < segments ? BrutalColors.green : Colors.transparent,
              border: Border.all(color: foreground, width: 2),
            ),
          ),
        ),
      ),
    );
  }
}

class BrutalSwitch extends StatelessWidget {
  const BrutalSwitch({required this.value, required this.onChanged, super.key});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return BrutalPressable(
      onPressed: () => onChanged(!value),
      backgroundColor: value ? BrutalColors.green : BrutalColors.red,
      child: SizedBox(
        width: 48,
        child: Text(value ? 'ON' : 'OFF', textAlign: TextAlign.center),
      ),
    );
  }
}

class BrutalAppBar extends StatelessWidget implements PreferredSizeWidget {
  const BrutalAppBar({required this.title, this.actions = const [], super.key});

  final String title;
  final List<Widget> actions;

  @override
  Size get preferredSize => const Size.fromHeight(72);

  @override
  Widget build(BuildContext context) {
    final foreground = Theme.of(context).colorScheme.onSurface;
    return AppBar(
      title: Text(title.toUpperCase()),
      titleTextStyle: Theme.of(context).textTheme.headlineSmall,
      actions: actions,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(3),
        child: Container(color: foreground, height: 3),
      ),
    );
  }
}
