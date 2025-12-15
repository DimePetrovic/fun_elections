import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/election_store.dart';
import '../models/election.dart';

// Knockout Screen - Enter competitors (must be power of 2)
// Supports ReorderableListView, Randomize, and manual input
class CreateKnockoutScreen extends StatefulWidget {
  const CreateKnockoutScreen({super.key});

  @override
  State<CreateKnockoutScreen> createState() => _CreateKnockoutScreenState();
}

class _CreateKnockoutScreenState extends State<CreateKnockoutScreen> {
  final List<TextEditingController> _controllers = [];
  int _numberOfCompetitors = 4; // Default
  Map<String, dynamic>? _args;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_args == null) {
      _args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
      _initializeControllers();
    }
  }

  void _initializeControllers() {
    _controllers.clear();
    for (int i = 0; i < _numberOfCompetitors; i++) {
      _controllers.add(TextEditingController(text: 'Competitor ${i + 1}'));
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _randomize() {
    final values = _controllers.map((c) => c.text).toList()..shuffle();
    for (int i = 0; i < _controllers.length; i++) {
      _controllers[i].text = values[i];
    }
    setState(() {});
  }

  void _create() {
    final names = _controllers.map((c) => c.text.trim()).where((n) => n.isNotEmpty).toList();
    if (names.length != _numberOfCompetitors) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all competitor names')),
      );
      return;
    }

    final store = Provider.of<ElectionStore>(context, listen: false);
    final id = store.createElection(
      name: _args!['name'],
      description: _args!['description'],
      format: ElectionFormat.knockout,
      competitorNames: names,
      isPublic: _args!['isPublic'],
    );

    Navigator.pushReplacementNamed(context, '/election/$id');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Knockout Setup'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.shuffle),
            onPressed: _randomize,
            tooltip: 'Randomize',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: DropdownButtonFormField<int>(
              value: _numberOfCompetitors,
              decoration: const InputDecoration(
                labelText: 'Number of Competitors',
                border: OutlineInputBorder(),
              ),
              items: [2, 4, 8, 16, 32]
                  .map((n) => DropdownMenuItem(value: n, child: Text('$n')))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _numberOfCompetitors = value!;
                  _initializeControllers();
                });
              },
            ),
          ),
          Expanded(
            child: ReorderableListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _controllers.length,
              itemBuilder: (context, index) {
                return Card(
                  key: ValueKey(index),
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(child: Text('${index + 1}')),
                    title: TextField(
                      controller: _controllers[index],
                      decoration: const InputDecoration(
                        hintText: 'Enter name',
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                );
              },
              onReorder: (oldIndex, newIndex) {
                setState(() {
                  if (newIndex > oldIndex) newIndex--;
                  final controller = _controllers.removeAt(oldIndex);
                  _controllers.insert(newIndex, controller);
                });
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: _create,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
                minimumSize: const Size.fromHeight(50),
              ),
              child: const Text('CREATE ELECTION'),
            ),
          ),
        ],
      ),
    );
  }
}
