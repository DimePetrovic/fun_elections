import 'package:flutter/material.dart';

// Create Screen - Choose election format and enter basic info
class CreateScreen extends StatefulWidget {
  const CreateScreen({super.key});

  @override
  State<CreateScreen> createState() => _CreateScreenState();
}

enum ElectionFormatOption {
  legacySingleVote('Legacy - Single Vote', 'Each user votes once'),
  legacyMultipleVotes('Legacy - Multiple Votes', 'Each user can vote multiple times'),
  legacyWeightedVotes('Legacy - Weighted Votes', 'Each user votes with weighted points'),
  knockout('Knockout', 'Single elimination tournament'),
  groupThenKnockout('Group → Knockout', 'Group stage followed by knockout'),
  league('League', 'Round-robin tournament'),
  groupThenLeague('Group → League', 'Group stage followed by league');

  final String title;
  final String description;
  const ElectionFormatOption(this.title, this.description);
}

class _CreateScreenState extends State<CreateScreen> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  ElectionFormatOption? _selectedFormat;
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

    // Navigate to settings screen based on format
    Navigator.pushNamed(
      context,
      '/create/settings',
      arguments: {
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'isPublic': _isPublic,
        'format': _selectedFormat,
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
                    ...ElectionFormatOption.values.map((format) => RadioListTile<ElectionFormatOption>(
                          title: Text(format.title),
                          subtitle: Text(format.description),
                          value: format,
                          groupValue: _selectedFormat,
                          onChanged: (value) => setState(() => _selectedFormat = value),
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
}
