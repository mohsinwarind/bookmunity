import 'package:flutter/material.dart';

import 'brutal_theme.dart';

/// A flat block with an outline and a small offset shadow that settles into
/// place when pressed.
class BrutalPressable extends StatefulWidget {
  const BrutalPressable({
    required this.child,
    required this.onPressed,
    this.backgroundColor = BrutalColors.yellow,
    this.foregroundColor = BrutalColors.ink,
    this.shadowColor,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    this.borderRadius = BrutalTokens.smallBorderRadius,
    super.key,
  });

  final Widget child;
  final VoidCallback? onPressed;
  final Color backgroundColor;
  final Color foregroundColor;
  final Color? shadowColor;
  final EdgeInsets padding;
  final BorderRadius borderRadius;

  @override
  State<BrutalPressable> createState() => _BrutalPressableState();
}

class _BrutalPressableState extends State<BrutalPressable> {
  bool pressed = false;

  void _setPressed(bool value) {
    if (pressed != value) setState(() => pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final isEnabled = widget.onPressed != null;
    final outline = Theme.of(context).colorScheme.outline;
    final offset = pressed && isEnabled ? BrutalTokens.shadowOffset.dx : 0.0;
    final background = isEnabled
        ? widget.backgroundColor
        : Theme.of(context).colorScheme.surfaceContainerHighest;
    return Semantics(
      button: true,
      enabled: isEnabled,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onPressed,
        onTapDown: isEnabled ? (_) => _setPressed(true) : null,
        onTapCancel: isEnabled ? () => _setPressed(false) : null,
        onTapUp: isEnabled ? (_) => _setPressed(false) : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 90),
          curve: Curves.easeOut,
          transform: Matrix4.translationValues(offset, offset, 0),
          padding: widget.padding,
          decoration: BoxDecoration(
            color: background,
            borderRadius: widget.borderRadius,
            border: Border.all(
              color: outline,
              width: BrutalTokens.borderWidth,
            ),
            boxShadow: offset == 0 && isEnabled
                ? [
                    BoxShadow(
                      color: widget.shadowColor ?? outline,
                      offset: BrutalTokens.shadowOffset,
                    ),
                  ]
                : const [],
          ),
          child: DefaultTextStyle.merge(
            style: TextStyle(
              color: isEnabled
                  ? widget.foregroundColor
                  : Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
            child: IconTheme.merge(
              data: IconThemeData(color: widget.foregroundColor, size: 18),
              child: widget.child,
            ),
          ),
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
    this.onTap,
    super.key,
  });

  final Widget child;
  final Color? backgroundColor;
  final EdgeInsets padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final background = backgroundColor ?? scheme.surfaceContainerLow;
    // Accent cards always carry dark text so they stay legible in dark mode.
    final onAccent = backgroundColor != null;
    final card = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BrutalTokens.borderRadius,
        border: Border.all(
          color: scheme.outline,
          width: BrutalTokens.borderWidth,
        ),
        boxShadow: [
          BoxShadow(color: scheme.outline, offset: BrutalTokens.shadowOffset),
        ],
      ),
      child: onAccent
          ? DefaultTextStyle.merge(
              style: const TextStyle(color: BrutalColors.ink),
              child: IconTheme.merge(
                data: const IconThemeData(color: BrutalColors.ink),
                child: child,
              ),
            )
          : child,
    );
    if (onTap == null) return card;
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        borderRadius: BrutalTokens.borderRadius,
        onTap: onTap,
        child: card,
      ),
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
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      selected: selected,
      button: true,
      child: GestureDetector(
        onTap: onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? scheme.onSurface : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected ? scheme.onSurface : scheme.outline,
              width: 1.2,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? scheme.surface : scheme.onSurface,
              fontWeight: FontWeight.w600,
              fontSize: 13.5,
            ),
          ),
        ),
      ),
    );
  }
}

class BrutalProgressBar extends StatelessWidget {
  const BrutalProgressBar({
    required this.value,
    this.color = BrutalColors.green,
    this.height = 8,
    super.key,
  });

  final double value;
  final Color color;
  final double height;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final clamped = value.isNaN ? 0.0 : value.clamp(0.0, 1.0);
    return Semantics(
      value: '${(clamped * 100).round()}%',
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(height),
          border: Border.all(color: scheme.outline, width: 1),
        ),
        clipBehavior: Clip.antiAlias,
        alignment: Alignment.centerLeft,
        child: FractionallySizedBox(
          widthFactor: clamped,
          heightFactor: 1,
          child: ColoredBox(color: color),
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
    return Switch(value: value, onChanged: onChanged);
  }
}

class BrutalAppBar extends StatelessWidget implements PreferredSizeWidget {
  const BrutalAppBar({
    required this.title,
    this.actions = const [],
    this.bottom,
    super.key,
  });

  final String title;
  final List<Widget> actions;
  final PreferredSizeWidget? bottom;

  @override
  Size get preferredSize =>
      Size.fromHeight(60 + (bottom?.preferredSize.height ?? 1));

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AppBar(
      toolbarHeight: 60,
      title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
      actions: [...actions, const SizedBox(width: 4)],
      bottom:
          bottom ??
          PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(color: scheme.outlineVariant, height: 1),
          ),
    );
  }
}

/// Section heading used across screens.
class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {this.trailing, super.key});

  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(text, style: Theme.of(context).textTheme.titleMedium),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

/// Friendly empty state with an optional action.
class EmptyState extends StatelessWidget {
  const EmptyState({
    required this.icon,
    required this.title,
    this.message,
    this.action,
    super.key,
  });

  final IconData icon;
  final String title;
  final String? message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 44, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(height: 14),
            Text(
              title,
              style: theme.textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            if (message != null) ...[
              const SizedBox(height: 6),
              Text(
                message!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (action != null) ...[const SizedBox(height: 20), action!],
          ],
        ),
      ),
    );
  }
}
