import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/election_store.dart';

// Join Public Screen - Shows list of all public elections
class JoinPublicScreen extends StatelessWidget {
  const JoinPublicScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = Provider.of<ElectionStore>(context);
    final publicElections = store.publicElections;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Public Elections'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: publicElections.isEmpty
          ? const Center(
              child: Text('No public elections available'),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: publicElections.length,
              itemBuilder: (context, index) {
                final election = publicElections[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    title: Text(
                      election.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (election.description.isNotEmpty)
                          Text(election.description),
                        const SizedBox(height: 4),
                        Text(
                          'Format: ${election.format.name.toUpperCase()}',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    trailing: const Icon(Icons.arrow_forward),
                    onTap: () {
                      store.joinPublicElection(election.id);
                      Navigator.pushNamed(
                        context,
                        '/election/${election.id}',
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}
