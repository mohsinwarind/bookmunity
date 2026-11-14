import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../providers/settings_providers.dart';
import '../../domain/reader_palette.dart';

Future<void> showReaderSettingsSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => const _ReaderSettingsSheet(),
  );
}

class _ReaderSettingsSheet extends ConsumerWidget {
  const _ReaderSettingsSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);
    final theme = Theme.of(context);
    void update(ReaderSettings next) => notifier.update(next);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('Text size', style: theme.textTheme.titleSmall),
              ),
              IconButton.outlined(
                tooltip: 'Smaller text',
                onPressed: settings.fontSize > ReaderSettings.minFontSize
                    ? () => update(
                        settings.copyWith(fontSize: settings.fontSize - 1),
                      )
                    : null,
                icon: const Icon(Icons.text_decrease),
              ),
              SizedBox(
                width: 44,
                child: Text(
                  '${settings.fontSize.round()}',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium,
                ),
              ),
              IconButton.outlined(
                tooltip: 'Larger text',
                onPressed: settings.fontSize < ReaderSettings.maxFontSize
                    ? () => update(
                        settings.copyWith(fontSize: settings.fontSize + 1),
                      )
                    : null,
                icon: const Icon(Icons.text_increase),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _SliderRow(
            label: 'Line spacing',
            value: settings.lineHeight,
            min: ReaderSettings.minLineHeight,
            max: ReaderSettings.maxLineHeight,
            divisions: 10,
            display: settings.lineHeight.toStringAsFixed(1),
            onChanged: (value) => update(
              settings.copyWith(
                lineHeight: double.parse(value.toStringAsFixed(1)),
              ),
            ),
          ),
          _SliderRow(
            label: 'Margins',
            value: settings.margin,
            min: ReaderSettings.minMargin,
            max: ReaderSettings.maxMargin,
            divisions: 10,
            display: '${settings.margin.round()}',
            onChanged: (value) =>
                update(settings.copyWith(margin: value.roundToDouble())),
          ),
          const SizedBox(height: 8),
          Text('Page colour', style: theme.textTheme.titleSmall),
          const SizedBox(height: 10),
          Row(
            children: [
              for (final option in ReaderTheme.values)
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: _ThemeSwatch(
                    option: option,
                    selected: settings.theme == option,
                    onTap: () => update(settings.copyWith(theme: option)),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 18),
          Text('Reading mode', style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          SegmentedButton<ReaderFlow>(
            showSelectedIcon: false,
            segments: const [
              ButtonSegment(
                value: ReaderFlow.paginated,
                icon: Icon(Icons.auto_stories_outlined),
                label: Text('Pages'),
              ),
              ButtonSegment(
                value: ReaderFlow.scrolled,
                icon: Icon(Icons.swap_vert),
                label: Text('Scroll'),
              ),
            ],
            selected: {settings.flow},
            onSelectionChanged: (value) =>
                update(settings.copyWith(flow: value.first)),
          ),
          const SizedBox(height: 18),
          Text('Font', style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          SegmentedButton<ReaderFont>(
            showSelectedIcon: false,
            segments: const [
              ButtonSegment(
                value: ReaderFont.serif,
                label: Text('Serif', style: TextStyle(fontFamily: 'serif')),
              ),
              ButtonSegment(value: ReaderFont.sans, label: Text('Sans')),
            ],
            selected: {settings.font},
            onSelectionChanged: (value) =>
                update(settings.copyWith(font: value.first)),
          ),
          const SizedBox(height: 18),
          Text('Screen orientation', style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          SegmentedButton<ReaderOrientation>(
            showSelectedIcon: false,
            segments: const [
              ButtonSegment(
                value: ReaderOrientation.auto,
                icon: Icon(Icons.screen_rotation_outlined),
                label: Text('Auto'),
              ),
              ButtonSegment(
                value: ReaderOrientation.portrait,
                icon: Icon(Icons.stay_current_portrait),
                label: Text('Portrait'),
              ),
              ButtonSegment(
                value: ReaderOrientation.landscape,
                icon: Icon(Icons.stay_current_landscape),
                label: Text('Landscape'),
              ),
            ],
            selected: {settings.orientation},
            onSelectionChanged: (value) =>
                update(settings.copyWith(orientation: value.first)),
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Keep screen on while reading'),
            value: settings.keepScreenAwake,
            onChanged: (value) =>
                update(settings.copyWith(keepScreenAwake: value)),
          ),
        ],
      ),
    );
  }
}

class _SliderRow extends StatelessWidget {
  const _SliderRow({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.display,
    required this.onChanged,
  });

  final String label;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final String display;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        SizedBox(
          width: 104,
          child: Text(label, style: theme.textTheme.titleSmall),
        ),
        Expanded(
          child: Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            divisions: divisions,
            label: display,
            onChanged: onChanged,
          ),
        ),
        SizedBox(width: 32, child: Text(display, textAlign: TextAlign.end)),
      ],
    );
  }
}

class _ThemeSwatch extends StatelessWidget {
  const _ThemeSwatch({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final ReaderTheme option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = ReaderPalette.of(option);
    final scheme = Theme.of(context).colorScheme;
    final label = switch (option) {
      ReaderTheme.light => 'Light',
      ReaderTheme.sepia => 'Sepia',
      ReaderTheme.dark => 'Dark',
    };
    return Semantics(
      button: true,
      selected: selected,
      label: '$label page',
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 56,
              height: 40,
              decoration: BoxDecoration(
                color: palette.background,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: selected ? scheme.primary : scheme.outline,
                  width: selected ? 2.5 : 1,
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                'Aa',
                style: TextStyle(
                  color: palette.foreground,
                  fontFamily: 'serif',
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(label, style: Theme.of(context).textTheme.labelSmall),
          ],
        ),
      ),
    );
  }
}
