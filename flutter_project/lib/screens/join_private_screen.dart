import 'package:flutter/material.dart';
import '../services/api_service.dart';

// Join Private Screen - Enter code to join private election
class JoinPrivateScreen extends StatefulWidget {
  const JoinPrivateScreen({super.key});

  @override
  State<JoinPrivateScreen> createState() => _JoinPrivateScreenState();
}

class _JoinPrivateScreenState extends State<JoinPrivateScreen> {
  final _codeController = TextEditingController();
  final _apiService = ApiService();
  String? _errorMessage;
  bool _isLoading = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _joinWithCode() async {
    final code = _codeController.text.trim().toUpperCase();
    if (code.isEmpty) {
      setState(() => _errorMessage = 'Please enter a code');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final election = await _apiService.getElectionByCode(code);
      
      // Check if election is active (status = 0)
      if (election['status'] != 0) {
        setState(() {
          _errorMessage = 'This election has ended. You cannot join.';
          _isLoading = false;
        });
        return;
      }
      
      await _apiService.joinElection(election['id']);
      
      if (mounted) {
        Navigator.pushReplacementNamed(
          context,
          '/election/${election['id']}',
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Invalid code. Please try again.';
        _isLoading = false;
      });
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
              onPressed: _isLoading ? null : _joinWithCode,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
              ),
              child: _isLoading
                ? const CircularProgressIndicator()
                : const Text('Join Election'),
            ),
          ],
        ),
      ),
    );
  }
}
