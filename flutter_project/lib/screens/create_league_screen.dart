import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/election_store.dart';
import '../models/election.dart';

class CreateLeagueScreen extends StatefulWidget {
  const CreateLeagueScreen({super.key});

  @override
  State<CreateLeagueScreen> createState() => _CreateLeagueScreenState();
}

class _CreateLeagueScreenState extends State<CreateLeagueScreen> {
  int _numberOfCompetitors = 4;
  final List<TextEditingController> _controllers = [];
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
      _controllers.add(TextEditingController(text: 'Team ${i + 1}'));
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _create() {
    final names = _controllers.map((c) => c.text.trim()).where((n) => n.isNotEmpty).toList();
    final store = Provider.of<ElectionStore>(context, listen: false);
    final id = store.createElection(
      name: _args!['name'],
      description: _args!['description'],
      format: ElectionFormat.league,
      competitorNames: names,
      isPublic: _args!['isPublic'],
    );
    Navigator.pushReplacementNamed(context, '/election/$id');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('League Setup'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Number of Teams', border: OutlineInputBorder()),
              onChanged: (value) {
                final n = int.tryParse(value) ?? 4;
                if (n > 0 && n <= 20) {
                  setState(() {
                    _numberOfCompetitors = n;
                    _initializeControllers();
                  });
                }
              },
            ),
          ),
          Expanded(
            child: ReorderableListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _controllers.length,
              itemBuilder: (context, index) => Card(
                key: ValueKey(index),
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(child: Text('${index + 1}')),
                  title: TextField(controller: _controllers[index], decoration: const InputDecoration(border: InputBorder.none)),
                ),
              ),
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
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(16), minimumSize: const Size.fromHeight(50)),
              child: const Text('CREATE ELECTION'),
            ),
          ),
        ],
      ),
    );
  }
}
