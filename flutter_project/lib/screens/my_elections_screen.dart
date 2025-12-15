import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/election_store.dart';
import '../models/election.dart';

// My Elections Screen - Shows user's elections in 3 tabs
// Created, Participating, and Ended elections
class MyElectionsScreen extends StatelessWidget {
  const MyElectionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('My Elections'),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.create), text: 'Created'),
              Tab(icon: Icon(Icons.people), text: 'Participating'),
              Tab(icon: Icon(Icons.archive), text: 'Ended'),
            ],
          ),
        ),
        body: Consumer<ElectionStore>(
          builder: (context, store, child) {
            return TabBarView(
              children: [
                _buildElectionList(context, store.createdElections),
                _buildElectionList(context, store.participatingElections),
                _buildElectionList(context, store.endedElections),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildElectionList(BuildContext context, List<Election> elections) {
    if (elections.isEmpty) {
      return const Center(
        child: Text('No elections found'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: elections.length,
      itemBuilder: (context, index) {
        final election = elections[index];
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
                Text(election.format.name.toUpperCase()),
                Text(
                  '${election.competitors.length} competitors',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (!election.isActive)
                  const Icon(Icons.check_circle, color: Colors.grey)
                else
                  const Icon(Icons.play_circle, color: Colors.green),
              ],
            ),
            onTap: () {
              Navigator.pushNamed(
                context,
                '/election/${election.id}',
              );
            },
          ),
        );
      },
    );
  }
}
