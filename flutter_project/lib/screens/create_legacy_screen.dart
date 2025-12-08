import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/election_store.dart';
import '../models/election.dart';

class CreateLegacyScreen extends StatefulWidget {
  const CreateLegacyScreen({super.key});

  @override
  State<CreateLegacyScreen> createState() => _CreateLegacyScreenState();
}

class _CreateLegacyScreenState extends State<CreateLegacyScreen> {
  LegacySubformat _subformat = LegacySubformat.voteForOne;
  int _numberOfCompetitors = 3;
  int _voteCount = 1;
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
      _controllers.add(TextEditingController(text: 'Option ${i + 1}'));
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
      format: ElectionFormat.legacy,
      competitorNames: names,
      isPublic: _args!['isPublic'],
      legacySubformat: _subformat,
      legacyVoteCount: _subformat == LegacySubformat.voteForOne ? null : _voteCount,
    );
    Navigator.pushReplacementNamed(context, '/election/$id');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Legacy Setup'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Voting Type:', style: TextStyle(fontWeight: FontWeight.bold)),
                RadioListTile(
                  title: const Text('Vote for 1'),
                  value: LegacySubformat.voteForOne,
                  groupValue: _subformat,
                  onChanged: (value) => setState(() => _subformat = value!),
                ),
                RadioListTile(
                  title: const Text('Vote for multiple'),
                  value: LegacySubformat.voteForMultiple,
                  groupValue: _subformat,
                  onChanged: (value) => setState(() => _subformat = value!),
                ),
                RadioListTile(
                  title: const Text('Vote for multiple (weighted)'),
                  value: LegacySubformat.voteForMultipleWeighted,
                  groupValue: _subformat,
                  onChanged: (value) => setState(() => _subformat = value!),
                ),
                if (_subformat != LegacySubformat.voteForOne)
                  TextField(
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Number of votes per person'),
                    onChanged: (value) => setState(() => _voteCount = int.tryParse(value) ?? 1),
                  ),
                const SizedBox(height: 16),
                TextField(
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Number of Options'),
                  onChanged: (value) {
                    final n = int.tryParse(value) ?? 3;
                    if (n > 0 && n <= 20) {
                      setState(() {
                        _numberOfCompetitors = n;
                        _initializeControllers();
                      });
                    }
                  },
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
