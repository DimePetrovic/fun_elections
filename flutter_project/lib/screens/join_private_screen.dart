import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/election_store.dart';

// Join Private Screen - Enter code to join private election
// Hardcoded code "AAAA" for testing
class JoinPrivateScreen extends StatefulWidget {
  const JoinPrivateScreen({super.key});

  @override
  State<JoinPrivateScreen> createState() => _JoinPrivateScreenState();
}

class _JoinPrivateScreenState extends State<JoinPrivateScreen> {
  final _codeController = TextEditingController();
  String? _errorMessage;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  void _joinWithCode() {
    final code = _codeController.text.trim().toUpperCase();
    if (code.isEmpty) {
      setState(() => _errorMessage = 'Please enter a code');
      return;
    }

    final store = Provider.of<ElectionStore>(context, listen: false);
    final electionId = store.joinPrivateElection(code);

    if (electionId != null) {
      Navigator.pushReplacementNamed(
        context,
        '/election/$electionId',
      );
    } else {
      setState(() => _errorMessage = 'Invalid code. Please try again.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Join Private Election'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Enter Election Code',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            TextField(
              controller: _codeController,
              decoration: InputDecoration(
                labelText: 'Code',
                hintText: 'e.g., AAAA',
                border: const OutlineInputBorder(),
                errorText: _errorMessage,
                prefixIcon: const Icon(Icons.key),
              ),
              textCapitalization: TextCapitalization.characters,
              onSubmitted: (_) => _joinWithCode(),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _joinWithCode,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
              ),
              child: const Text('Join Election'),
            ),
            const SizedBox(height: 16),
            Text(
              'Tip: Try code "AAAA" for testing',
              style: TextStyle(
                color: Theme.of(context).colorScheme.secondary,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
