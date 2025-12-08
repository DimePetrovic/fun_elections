import 'package:flutter/material.dart';
import '../models/election.dart';

// Create Screen - Choose election format and enter basic info
class CreateScreen extends StatefulWidget {
  const CreateScreen({super.key});

  @override
  State<CreateScreen> createState() => _CreateScreenState();
}

class _CreateScreenState extends State<CreateScreen> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  ElectionFormat? _selectedFormat;
  bool _isPublic = true;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _next() {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter election name')),
      );
      return;
    }

    if (_selectedFormat == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a format')),
      );
      return;
    }

    // Navigate to specific format screen
    final route = switch (_selectedFormat!) {
      ElectionFormat.knockout => '/create/knockout',
      ElectionFormat.group => '/create/group',
      ElectionFormat.league => '/create/league',
      ElectionFormat.legacy => '/create/legacy',
    };

    Navigator.pushNamed(
      context,
      route,
      arguments: {
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'isPublic': _isPublic,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Election'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Basic Information',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Election Name *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.title_rounded),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description (optional)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.description_rounded),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      title: const Text('Public Election'),
                      subtitle: const Text('Allow anyone to join'),
                      value: _isPublic,
                      onChanged: (value) => setState(() => _isPublic = value),
                      secondary: Icon(_isPublic ? Icons.public_rounded : Icons.lock_rounded),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Select Format',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...ElectionFormat.values.map((format) => _FormatTile(
                          format: format,
                          isSelected: _selectedFormat == format,
                          onTap: () => setState(() => _selectedFormat = format),
                        )),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _next,
              icon: const Icon(Icons.arrow_forward_rounded),
              label: const Text('Next'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.all(16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getFormatDescription(ElectionFormat format) {
    return switch (format) {
      ElectionFormat.knockout => 'Single elimination tournament',
      ElectionFormat.group => 'Group stage competition',
      ElectionFormat.league => 'Round-robin matches',
      ElectionFormat.legacy => 'Voting-based election',
    };
  }
}

class _FormatTile extends StatelessWidget {
  final ElectionFormat format;
  final bool isSelected;
  final VoidCallback onTap;

  const _FormatTile({
    required this.format,
    required this.isSelected,
    required this.onTap,
  });

  IconData _getIcon() {
    return switch (format) {
      ElectionFormat.knockout => Icons.emoji_events_rounded,
      ElectionFormat.group => Icons.groups_rounded,
      ElectionFormat.league => Icons.sports_rounded,
      ElectionFormat.legacy => Icons.how_to_vote_rounded,
    };
  }

  String _getDescription() {
    return switch (format) {
      ElectionFormat.knockout => 'Single elimination tournament',
      ElectionFormat.group => 'Group stage competition',
      ElectionFormat.league => 'Round-robin matches',
      ElectionFormat.legacy => 'Voting-based election',
    };
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Card(
      elevation: isSelected ? 4 : 0,
      color: isSelected ? colorScheme.primaryContainer : colorScheme.surface,
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              Icon(
                _getIcon(),
                size: 32,
                color: isSelected ? colorScheme.onPrimaryContainer : colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      format.name.toUpperCase(),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isSelected ? colorScheme.onPrimaryContainer : null,
                      ),
                    ),
                    Text(
                      _getDescription(),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: isSelected 
                            ? colorScheme.onPrimaryContainer 
                            : colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Icon(
                  Icons.check_circle_rounded,
                  color: colorScheme.primary,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
