import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:odyssey/src/utils/widgets/animated_card.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          // Theme Selection
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: AnimatedCard(
              child: ExpansionTile(
                title: Row(
                  children: [
                    Icon(Icons.color_lens, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 16),
                    Text('Theme', style: Theme.of(context).textTheme.titleMedium),
                  ],
                ),
                children: [
                  RadioListTile<String>(
                    title: const Text('System Default'),
                    value: 'system',
                    groupValue: 'system', // This would be dynamic in real implementation
                    onChanged: (value) {},
                  ),
                  RadioListTile<String>(
                    title: const Text('Light Theme'),
                    value: 'light',
                    groupValue: 'system', // This would be dynamic in real implementation
                    onChanged: (value) {},
                  ),
                  RadioListTile<String>(
                    title: const Text('Dark Theme'),
                    value: 'dark',
                    groupValue: 'system', // This would be dynamic in real implementation
                    onChanged: (value) {},
                  ),
                ],
              ),
            ),
          ),
          
          // Export Options
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: AnimatedCard(
              child: ExpansionTile(
                title: Row(
                  children: [
                    Icon(Icons.import_export, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 16),
                    Text('Export Data', style: Theme.of(context).textTheme.titleMedium),
                  ],
                ),
                children: [
                  ListTile(
                    leading: Icon(Icons.table_rows, color: Theme.of(context).colorScheme.primary),
                    title: const Text('Export as CSV'),
                    onTap: () {
                      // Export functionality would go here
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('CSV export feature would go here'), backgroundColor: Theme.of(context).colorScheme.primary),
                      );
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.data_object, color: Theme.of(context).colorScheme.primary),
                    title: const Text('Export as JSON'),
                    onTap: () {
                      // Export functionality would go here
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('JSON export feature would go here'), backgroundColor: Theme.of(context).colorScheme.primary),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          
          // General Settings
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: AnimatedCard(
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text('Enable Notifications'),
                    value: true, // Would be dynamic in real implementation
                    onChanged: (value) {},
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    title: const Text('Auto Backup'),
                    value: false, // Would be dynamic in real implementation
                    onChanged: (value) {},
                  ),
                ],
              ),
            ),
          ),
          
          // About Section
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: AnimatedCard(
              child: Column(
                children: [
                  ListTile(
                    leading: Icon(Icons.info, color: Theme.of(context).colorScheme.primary),
                    title: const Text('About'),
                    onTap: () {
                      showAboutDialog(
                        context: context,
                        applicationName: 'Odyssey',
                        applicationVersion: '1.0.0',
                        applicationIcon: const FlutterLogo(size: 64),
                        children: const [
                          Text('A mood tracking and time management application.'),
                        ],
                      );
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: Icon(Icons.star, color: Theme.of(context).colorScheme.primary),
                    title: const Text('Rate this app'),
                    onTap: () {
                      // Rate app functionality
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
