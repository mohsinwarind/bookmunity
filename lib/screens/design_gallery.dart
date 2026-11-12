import 'package:flutter/material.dart';

import '../design/brutal_theme.dart';
import '../design/brutal_widgets.dart';

class DesignGallery extends StatefulWidget {
  const DesignGallery({super.key});

  @override
  State<DesignGallery> createState() => _DesignGalleryState();
}

class _DesignGalleryState extends State<DesignGallery> {
  bool dark = false;
  bool enabled = true;
  double progress = .6;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: brutalTheme(dark: dark),
      child: Builder(
        builder: (context) => Scaffold(
          appBar: BrutalAppBar(
            title: 'Bookmunity / Gallery',
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: BrutalSwitch(
                  value: dark,
                  onChanged: (value) => setState(() => dark = value),
                ),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                'DESIGN SYSTEM',
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              const SizedBox(height: 8),
              const Text('PHASE 1 / FLAT. LOUD. DELIBERATE.'),
              const SizedBox(height: 24),
              BrutalCard(
                backgroundColor: BrutalColors.yellow,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'BUTTONS',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        BrutalPressable(
                          onPressed: () {},
                          child: const Text('IMPORT +'),
                        ),
                        BrutalPressable(
                          onPressed: enabled ? () {} : null,
                          backgroundColor: BrutalColors.red,
                          child: const Text('DELETE'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const Text('CHIPS'),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  BrutalChip(label: 'All', selected: true, onPressed: () {}),
                  BrutalChip(label: 'Reading', onPressed: () {}),
                  BrutalChip(label: 'Finished', onPressed: () {}),
                ],
              ),
              const SizedBox(height: 20),
              BrutalCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('PROGRESS'),
                    const SizedBox(height: 10),
                    BrutalProgressBar(value: progress),
                    Slider(
                      value: progress,
                      onChanged: (value) => setState(() => progress = value),
                      activeColor: BrutalColors.blue,
                      inactiveColor: Theme.of(context).colorScheme.onSurface,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const Text('INPUT'),
              const SizedBox(height: 10),
              const TextField(
                decoration: InputDecoration(
                  labelText: 'BOOK TITLE',
                  hintText: 'TYPE HERE',
                ),
              ),
              const SizedBox(height: 20),
              BrutalCard(
                backgroundColor: BrutalColors.pink,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('ENABLE READING MODE'),
                    BrutalSwitch(
                      value: enabled,
                      onChanged: (value) => setState(() => enabled = value),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
