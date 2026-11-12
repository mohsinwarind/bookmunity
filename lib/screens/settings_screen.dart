import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controllers/auth_controller.dart';
import '../design/brutal_theme.dart';
import '../design/brutal_widgets.dart';
import '../providers/app_providers.dart';
import '../providers/settings_providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final user = AuthController().currentUser;
    return Scaffold(
      appBar: const BrutalAppBar(title: 'Settings'),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          BrutalCard(
            backgroundColor: BrutalColors.blue,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ACCOUNT',
                  style: Theme.of(context).textTheme.headlineSmall
                      ?.copyWith(color: BrutalColors.paper),
                ),
                const SizedBox(height: 8),
                Text(
                  user?.displayName?.isNotEmpty == true
                      ? user!.displayName!
                      : user?.email ?? 'LOCAL READER',
                  style: const TextStyle(
                    color: BrutalColors.paper,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'READER TEXT SIZE: ${settings.fontSize.round()}',
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
          Slider(
            min: 16,
            max: 30,
            divisions: 7,
            value: settings.fontSize,
            onChanged: (value) => ref
                .read(settingsProvider.notifier)
                .update(settings.copyWith(fontSize: value)),
          ),
          Text(
            'LINE SPACING: ${settings.lineHeight.toStringAsFixed(1)}',
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
          Slider(
            min: 1.3,
            max: 2.2,
            divisions: 9,
            value: settings.lineHeight,
            onChanged: (value) => ref
                .read(settingsProvider.notifier)
                .update(settings.copyWith(lineHeight: value)),
          ),
          const SizedBox(height: 12),
          BrutalPressable(
            onPressed: () async {
              try {
                final service = await ref.read(importServiceProvider.future);
                final count = await service.refreshAllMetadata();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('REFRESHED $count BOOK(S).')),
                  );
                }
              } catch (error) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('REFRESH FAILED: $error')),
                  );
                }
              }
            },
            backgroundColor: BrutalColors.yellow,
            child: const Text('REFRESH ALL METADATA'),
          ),
          const SizedBox(height: 20),
          BrutalPressable(
            onPressed: () async {
              await AuthController().logout();
              if (context.mounted) Navigator.of(context).pop();
            },
            backgroundColor: BrutalColors.red,
            foregroundColor: BrutalColors.paper,
            child: const Text('LOG OUT'),
          ),
        ],
      ),
    );
  }
}
