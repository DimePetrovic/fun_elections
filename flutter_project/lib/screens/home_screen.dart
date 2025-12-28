import 'package:flutter/material.dart';

// Home Screen - Entry point of the app
// Minimalist design with Options (top-left), My Elections (top-right), 
// and two large center buttons (Join/Create)
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            // Main content
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo/Icon area
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Colors.black,
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(
                        Icons.how_to_vote_rounded,
                        size: 50,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // App Title
                    const Text(
                      'Fun Elections',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w300,
                        letterSpacing: 2,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Create • Vote • Compete',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w300,
                        letterSpacing: 1.5,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 80),
                    
                    // Two large buttons side by side
                    Row(
                      children: [
                        Expanded(
                          child: _LargeActionButton(
                            icon: Icons.login_rounded,
                            label: 'Join',
                            onTap: () => Navigator.pushNamed(context, '/join'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _LargeActionButton(
                            icon: Icons.add_rounded,
                            label: 'Create',
                            onTap: () => Navigator.pushNamed(context, '/create'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            // Top-left: Settings button
            Positioned(
              top: 16,
              left: 16,
              child: IconButton(
                icon: const Icon(Icons.settings_outlined, size: 28),
                color: Colors.black,
                onPressed: () => Navigator.pushNamed(context, '/settings'),
              ),
            ),
            
            // Top-right: My Elections button
            Positioned(
              top: 16,
              right: 16,
              child: IconButton(
                icon: const Icon(Icons.ballot_outlined, size: 28),
                color: Colors.black,
                onPressed: () => Navigator.pushNamed(context, '/my-elections'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LargeActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _LargeActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 180,
        decoration: BoxDecoration(
          border: Border.all(
            color: Colors.black,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 64,
              color: Colors.black,
            ),
            const SizedBox(height: 16),
            Text(
              label,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w500,
                letterSpacing: 1,
                color: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
