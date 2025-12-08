import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/election_store.dart';
import '../models/election.dart';

class CreateGroupScreen extends StatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  int _numberOfCompetitors = 8;
  int _numberOfGroups = 2;
  bool _hasWeightedGroups = false;
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

  void _create() {
    final names = _controllers.map((c) => c.text.trim()).where((n) => n.isNotEmpty).toList();
    final store = Provider.of<ElectionStore>(context, listen: false);
    final id = store.createElection(
      name: _args!['name'],
      description: _args!['description'],
      format: ElectionFormat.group,
      competitorNames: names,
      isPublic: _args!['isPublic'],
      numberOfGroups: _numberOfGroups,
      hasWeightedGroups: _hasWeightedGroups,
    );
    Navigator.pushReplacementNamed(context, '/election/$id');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Group Setup'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                DropdownButtonFormField<int>(
                  value: _numberOfCompetitors,
                  decoration: const InputDecoration(labelText: 'Competitors', border: OutlineInputBorder()),
                  items: [4, 8, 12, 16].map((n) => DropdownMenuItem(value: n, child: Text('$n'))).toList(),
                  onChanged: (value) => setState(() {
                    _numberOfCompetitors = value!;
                    _initializeControllers();
                  }),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<int>(
                  value: _numberOfGroups,
                  decoration: const InputDecoration(labelText: 'Groups', border: OutlineInputBorder()),
                  items: [1, 2, 4, 8].map((n) => DropdownMenuItem(value: n, child: Text('$n'))).toList(),
                  onChanged: (value) => setState(() => _numberOfGroups = value!),
                ),
                SwitchListTile(
                  title: const Text('Weighted Groups'),
                  value: _hasWeightedGroups,
                  onChanged: (value) => setState(() => _hasWeightedGroups = value),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _controllers.length,
              itemBuilder: (context, index) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(child: Text('${index + 1}')),
                  title: TextField(controller: _controllers[index], decoration: const InputDecoration(border: InputBorder.none)),
                ),
              ),
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
