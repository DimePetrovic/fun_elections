import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/election_store.dart';
import '../models/election.dart';

// Election Screen - View and interact with an election
// Shows election details, current match, voting options, and admin controls
class ElectionScreen extends StatelessWidget {
  final String electionId;

  const ElectionScreen({super.key, required this.electionId});

  @override
  Widget build(BuildContext context) {
    final store = Provider.of<ElectionStore>(context);
    final election = store.getElectionById(electionId);

    if (election == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Election Not Found')),
        body: const Center(child: Text('Election not found')),
      );
    }

    final isCreator = election.creatorId == store.currentUserId;

    return Scaffold(
      appBar: AppBar(
        title: Text(election.name),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          if (!election.isPublic)
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: election.code));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Code ${election.code} copied!')),
                );
              },
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Election Info Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      election.name,
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    if (election.description.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(election.description),
                    ],
                    const SizedBox(height: 8),
                    Text(
                      'Format: ${election.format.name.toUpperCase()}',
                      style: TextStyle(color: Theme.of(context).colorScheme.primary),
                    ),
                    if (!election.isPublic) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.lock, size: 16),
                          const SizedBox(width: 4),
                          Text('Code: ${election.code}'),
                        ],
                      ),
                    ],
                    if (!election.isActive) ...[
                      const SizedBox(height: 8),
                      const Chip(
                        label: Text('ENDED'),
                        backgroundColor: Colors.grey,
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Format-specific view
            if (election.isActive) ...[
              _buildFormatView(context, election, store),
            ] else ...[
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('This election has ended.', textAlign: TextAlign.center),
                ),
              ),
            ],

            const SizedBox(height: 16),

            // Admin controls
            if (isCreator && election.isActive) ...[
              ElevatedButton.icon(
                onPressed: () {
                  store.nextMatch(electionId);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Moved to next match')),
                  );
                },
                icon: const Icon(Icons.skip_next),
                label: const Text('Next Match'),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () {
                  store.endElection(electionId);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Election ended')),
                  );
                },
                icon: const Icon(Icons.stop),
                label: const Text('End Election'),
                style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
              ),
            ],

            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () => Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false),
              icon: const Icon(Icons.home),
              label: const Text('Back to Home'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormatView(BuildContext context, Election election, ElectionStore store) {
    switch (election.format) {
      case ElectionFormat.knockout:
        return _buildKnockoutView(context, election, store);
      case ElectionFormat.group:
        return _buildGroupView(context, election);
      case ElectionFormat.league:
        return _buildLeagueView(context, election);
      case ElectionFormat.legacy:
        return _buildLegacyView(context, election, store);
    }
  }

  Widget _buildKnockoutView(BuildContext context, Election election, ElectionStore store) {
    if (election.rounds.isEmpty) {
      return const Card(child: Padding(padding: EdgeInsets.all(16), child: Text('No rounds available')));
    }

    final currentMatch = election.currentMatch;
    if (currentMatch == null) {
      return const Card(child: Padding(padding: EdgeInsets.all(16), child: Text('Tournament completed!')));
    }

    final competitor1 = election.competitors.firstWhere((c) => c.id == currentMatch.competitorIds[0]);
    final competitor2 = election.competitors.firstWhere((c) => c.id == currentMatch.competitorIds[1]);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              'Round ${election.currentRoundIndex + 1}',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildVoteOption(context, competitor1, currentMatch, store, election.id),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text('VS', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            _buildVoteOption(context, competitor2, currentMatch, store, election.id),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupView(BuildContext context, Election election) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: election.groups.map((group) {
            final competitors = election.competitors
                .where((c) => group.competitorIds.contains(c.id))
                .toList();
            return Column(
              children: [
                Text(group.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                ...competitors.map((c) => ListTile(title: Text(c.name), trailing: Text('${c.points} pts'))),
                const Divider(),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildLeagueView(BuildContext context, Election election) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text('League Standings', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ...election.competitors.map((c) => ListTile(
                  title: Text(c.name),
                  trailing: Text('${c.points} pts'),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildLegacyView(BuildContext context, Election election, ElectionStore store) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text('Cast Your Vote', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ...election.competitors.map((competitor) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    title: Text(competitor.name),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('${competitor.points} votes'),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: election.legacyVotedUserIds.contains(store.currentUserId)
                              ? null // Disable button if user already voted
                              : () {
                                  final success = store.vote(election.id, competitor.id);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        success
                                            ? 'Voted for ${competitor.name}!'
                                            : 'You have already voted',
                                      ),
                                      backgroundColor: success ? null : Colors.orange,
                                    ),
                                  );
                                },
                          child: Text(
                            election.legacyVotedUserIds.contains(store.currentUserId)
                                ? 'Voted'
                                : 'Vote',
                          ),
                        ),
                      ],
                    ),
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildVoteOption(BuildContext context, Competitor competitor, Match match, ElectionStore store, String electionId) {
    final votes = match.votes[competitor.id] ?? 0;
    final hasVoted = match.votedUserIds.contains(store.currentUserId);
    
    return Card(
      elevation: hasVoted ? 0 : 2,
      color: hasVoted 
          ? Theme.of(context).colorScheme.surfaceContainerHighest
          : Theme.of(context).colorScheme.primaryContainer,
      child: ListTile(
        title: Text(competitor.name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('$votes votes'),
        trailing: FilledButton(
          onPressed: hasVoted
              ? null
              : () {
                  final success = store.vote(electionId, competitor.id);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        success
                            ? 'Voted for ${competitor.name}!'
                            : 'You have already voted',
                      ),
                      backgroundColor: success ? null : Colors.orange,
                    ),
                  );
                },
          child: Text(hasVoted ? 'Voted' : 'Vote'),
        ),
      ),
    );
  }
}
