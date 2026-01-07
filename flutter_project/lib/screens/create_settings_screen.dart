import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'create_screen.dart';

class CreateSettingsScreen extends StatefulWidget {
  const CreateSettingsScreen({super.key});

  @override
  State<CreateSettingsScreen> createState() => _CreateSettingsScreenState();
}

class _CreateSettingsScreenState extends State<CreateSettingsScreen> {
  final _apiService = ApiService();
  Map<String, dynamic>? _args;
  
  // Common fields
  final List<TextEditingController> _candidateControllers = [];
  int _numberOfCandidates = 4;
  final TextEditingController _numberOfCandidatesController = TextEditingController(text: '4');
  
  // Legacy specific
  int _voteCount = 3;
  
  // Group specific
  int _numberOfGroups = 2;
  
  bool _isLoading = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_args == null) {
      _args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
      _initializeCandidates();
    }
  }

  void _initializeCandidates() {
    _candidateControllers.clear();
    for (int i = 0; i < _numberOfCandidates; i++) {
      _candidateControllers.add(TextEditingController(text: ''));
    }
  }

  String? _validateCandidates() {
    final names = _candidateControllers.asMap().entries.map((entry) {
      final text = entry.value.text.trim();
      return text.isEmpty ? 'Candidate ${entry.key + 1}' : text;
    }).toList();
    
    // Check for duplicate names
    final uniqueNames = names.toSet();
    if (uniqueNames.length != names.length) {
      return 'All candidate names must be unique';
    }
    
    return null;
  }

  bool _isPowerOfTwo(int n) {
    return n > 0 && (n & (n - 1)) == 0;
  }

  int _getMaxCandidates() {
    final format = _args?['format'] as ElectionFormatOption?;
    if (format == ElectionFormatOption.knockout || 
        format == ElectionFormatOption.groupThenKnockout) {
      return 32; // Max power of 2
    }
    return 32;
  }

  int _getMinCandidates() {
    return 2;
  }

  bool _isValidCandidateCount(int count) {
    final format = _args?['format'] as ElectionFormatOption?;
    if (format == ElectionFormatOption.knockout || 
        format == ElectionFormatOption.groupThenKnockout) {
      return _isPowerOfTwo(count);
    }
    return count >= 2;
  }

  @override
  void dispose() {
    for (var controller in _candidateControllers) {
      controller.dispose();
    }
    _numberOfCandidatesController.dispose();
    super.dispose();
  }

  Future<void> _createElection() async {
    // Validate candidates
    final validationError = _validateCandidates();
    if (validationError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(validationError),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }

    final candidateNames = _candidateControllers.asMap().entries
        .map((entry) {
          final text = entry.value.text.trim();
          return text.isEmpty ? 'Candidate ${entry.key + 1}' : text;
        })
        .toList();

    if (candidateNames.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter at least 2 candidates')),
      );
      return;
    }

    final format = _args!['format'] as ElectionFormatOption;
    
    // Validate candidate count for knockout
    if ((format == ElectionFormatOption.knockout || 
         format == ElectionFormatOption.groupThenKnockout) && 
        !_isPowerOfTwo(candidateNames.length)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Knockout format requires power of 2 candidates (2, 4, 8, 16, 32)'),
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final format = _args!['format'] as ElectionFormatOption;
      int electionType;
      int? voteCount;
      int? numberOfGroups;

      switch (format) {
        case ElectionFormatOption.legacySingleVote:
          electionType = 0; // LegacySingleVote
          break;
        case ElectionFormatOption.legacyMultipleVotes:
          electionType = 1; // LegacyMultipleVotes
          voteCount = _voteCount;
          break;
        case ElectionFormatOption.legacyWeightedVotes:
          electionType = 2; // LegacyWeightedVotes
          voteCount = _voteCount;
          break;
        case ElectionFormatOption.knockout:
          electionType = 3; // Knockout
          break;
        case ElectionFormatOption.groupThenKnockout:
          electionType = 4; // GroupThenKnockout
          numberOfGroups = _numberOfGroups;
          break;
        case ElectionFormatOption.league:
          electionType = 5; // League
          break;
        case ElectionFormatOption.groupThenLeague:
          electionType = 6; // GroupThenLeague
          numberOfGroups = _numberOfGroups;
          break;
      }

      final electionData = {
        'name': _args!['name'],
        'description': _args!['description'],
        'isPublic': _args!['isPublic'],
        'electionType': electionType,
        'voteCount': voteCount,
        'numberOfGroups': numberOfGroups,
        'candidates': candidateNames.map((name) => {
          'name': name,
          'points': 0,
        }).toList(),
      };

      final result = await _apiService.createElection(electionData);

      if (mounted) {
        // Navigate to election screen (not replacementNamed, so back goes to home)
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/election/${result['id']}',
          (route) => route.settings.name == '/',
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating election: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_args == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final format = _args!['format'] as ElectionFormatOption;
    final isLegacy = format == ElectionFormatOption.legacyMultipleVotes ||
                     format == ElectionFormatOption.legacyWeightedVotes;
    final hasGroups = format == ElectionFormatOption.groupThenKnockout ||
                      format == ElectionFormatOption.groupThenLeague;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Election Settings'),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            format.title,
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            format.description,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Format-specific settings
                  if (isLegacy) ...[
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Voting Settings',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextField(
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Votes per user',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.how_to_vote),
                              ),
                              controller: TextEditingController(text: _voteCount.toString()),
                              onChanged: (value) {
                                final count = int.tryParse(value) ?? 3;
                                if (count > 0) {
                                  setState(() => _voteCount = count);
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  if (hasGroups) ...[
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Group Settings',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextField(
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Number of groups',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.group_work),
                              ),
                              controller: TextEditingController(text: _numberOfGroups.toString()),
                              onChanged: (value) {
                                final count = int.tryParse(value) ?? 2;
                                if (count > 0) {
                                  setState(() => _numberOfGroups = count);
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Candidates section
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Candidates',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if ((format == ElectionFormatOption.knockout || 
                                   format == ElectionFormatOption.groupThenKnockout))
                                DropdownButton<int>(
                                  value: _isPowerOfTwo(_numberOfCandidates) ? _numberOfCandidates : 4,
                                  items: [2, 4, 8, 16, 32].map((int value) {
                                    return DropdownMenuItem<int>(
                                      value: value,
                                      child: Text('$value candidates'),
                                    );
                                  }).toList(),
                                  onChanged: (int? newValue) {
                                    if (newValue != null) {
                                      setState(() {
                                        _numberOfCandidates = newValue;
                                        _initializeCandidates();
                                      });
                                    }
                                  },
                                )
                              else if (format == ElectionFormatOption.league)
                                SizedBox(
                                  width: 150,
                                  child: TextField(
                                    controller: _numberOfCandidatesController,
                                    keyboardType: TextInputType.number,
                                    decoration: const InputDecoration(
                                      labelText: 'Number of Teams',
                                      border: OutlineInputBorder(),
                                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    ),
                                    onSubmitted: (value) {
                                      final n = int.tryParse(value);
                                      if (n != null && n >= 2 && n <= 20) {
                                        setState(() {
                                          _numberOfCandidates = n;
                                          _numberOfCandidatesController.text = '$n';
                                          _initializeCandidates();
                                        });
                                      } else {
                                        // Revert to previous valid value
                                        _numberOfCandidatesController.text = '$_numberOfCandidates';
                                      }
                                    },
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // Show bracket visualization for knockout formats
                          if (format == ElectionFormatOption.knockout || 
                              format == ElectionFormatOption.groupThenKnockout)
                            _buildKnockoutBracket()
                          else
                            ...List.generate(
                              _candidateControllers.length,
                              (index) => Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: TextField(
                                  controller: _candidateControllers[index],
                                  decoration: InputDecoration(
                                    labelText: 'Candidate ${index + 1}',
                                    hintText: 'Candidate ${index + 1}',
                                    hintStyle: const TextStyle(color: Colors.grey),
                                    border: const OutlineInputBorder(),
                                    prefixIcon: CircleAvatar(
                                      child: Text('${index + 1}'),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Create button at bottom
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: FilledButton.icon(
              onPressed: _isLoading ? null : _createElection,
              icon: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.check),
              label: Text(_isLoading ? 'Creating...' : 'Create Election'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.all(16),
                minimumSize: const Size.fromHeight(50),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKnockoutBracket() {
    // Split candidates into left and right sides
    final leftCount = _numberOfCandidates ~/ 2;
    final rightCount = _numberOfCandidates - leftCount;
    
    // Calculate total height: top padding + bottom padding + (boxes * height) + (spaces between boxes)
    final inputBoxHeight = 50.0;
    final spacingBetweenBoxes = 20.0;
    final topPadding = 20.0;
    final bottomPadding = 20.0;
    final maxItemsPerSide = leftCount > rightCount ? leftCount : rightCount;
    final bracketHeight = topPadding + bottomPadding + 
                         (maxItemsPerSide * inputBoxHeight) + 
                         ((maxItemsPerSide - 1) * spacingBetweenBoxes);

    return SizedBox(
      height: bracketHeight,
      child: Row(
        children: [
          // Left bracket
          Expanded(
            child: Stack(
              children: [
                CustomPaint(
                  painter: BracketLinesPainter(
                    numberOfPairs: leftCount ~/ 2,
                    isLeft: true,
                    itemHeight: 70.0,
                  ),
                  child: Container(), // Empty container to give CustomPaint size
                ),
                _buildBracketSide(0, leftCount, isLeft: true),
              ],
            ),
          ),
          const SizedBox(width: 40),
          // Right bracket
          Expanded(
            child: Stack(
              children: [
                CustomPaint(
                  painter: BracketLinesPainter(
                    numberOfPairs: rightCount ~/ 2,
                    isLeft: false,
                    itemHeight: 70.0,
                  ),
                  child: Container(), // Empty container to give CustomPaint size
                ),
                _buildBracketSide(leftCount, leftCount + rightCount, isLeft: false),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBracketSide(int startIndex, int endIndex, {required bool isLeft}) {
    return Padding(
      padding: EdgeInsets.only(
        left: isLeft ? 40.0 : 0.0,
        right: isLeft ? 0.0 : 40.0,
        top: 20.0,
        bottom: 20.0,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: List.generate(
          endIndex - startIndex,
          (i) {
            final index = startIndex + i;
            final controller = _candidateControllers[index];
            
            return Padding(
              padding: EdgeInsets.only(bottom: i < (endIndex - startIndex - 1) ? 20.0 : 0.0),
              child: _buildCandidateInput(index, controller),
            );
          },
        ),
      ),
    );
  }

  Widget _buildCandidateInput(int index, TextEditingController controller) {
    return Container(
      height: 50,
      constraints: BoxConstraints(maxWidth: 220.0),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade400, width: 1.5),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: controller.text.isEmpty ? Colors.grey.shade600 : Colors.black,
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          hintText: controller.text.isEmpty ? 'Candidate ${index + 1}' : '',
          hintStyle: TextStyle(color: Colors.grey.shade600),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        ),
        onTap: () {
          // Clear placeholder text when user clicks
          if (controller.text.isEmpty) {
            setState(() {});
          }
        },
        onChanged: (_) => setState(() {}),
      ),
    );
  }
}

class BracketLinesPainter extends CustomPainter {
  final int numberOfPairs;
  final bool isLeft;
  final double itemHeight;

  BracketLinesPainter({
    required this.numberOfPairs,
    required this.isLeft,
    required this.itemHeight,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.shade600
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    final lineExtension = 50.0; // How far lines extend beyond boxes
    final inputBoxHeight = 50.0; // Height of each input box
    final spacingBetweenBoxes = 20.0; // Vertical spacing between boxes

    // Draw connecting lines for each pair
    for (int i = 0; i < numberOfPairs; i++) {
      final firstItemIndex = i * 2;
      final secondItemIndex = i * 2 + 1;

      // Calculate Y positions (vertical center of each input box)
      // top padding (20) + (index * (box height + spacing)) + half box height
      final firstBoxTopY = 20.0 + (firstItemIndex * (inputBoxHeight + spacingBetweenBoxes));
      final secondBoxTopY = 20.0 + (secondItemIndex * (inputBoxHeight + spacingBetweenBoxes));
      
      final firstY = firstBoxTopY + (inputBoxHeight / 2.0); // Center of first box
      final secondY = secondBoxTopY + (inputBoxHeight / 2.0); // Center of second box

      if (isLeft) {
        // Left side: lines extend to the right
        final boxEdgeX = size.width - 40.0; // Right edge of input boxes
        final lineEndX = boxEdgeX + lineExtension;

        // Horizontal line from first item
        canvas.drawLine(
          Offset(boxEdgeX, firstY),
          Offset(lineEndX, firstY),
          paint,
        );

        // Horizontal line from second item
        canvas.drawLine(
          Offset(boxEdgeX, secondY),
          Offset(lineEndX, secondY),
          paint,
        );

        // Vertical connecting line
        canvas.drawLine(
          Offset(lineEndX, firstY),
          Offset(lineEndX, secondY),
          paint,
        );
      } else {
        // Right side: lines extend to the left
        final boxEdgeX = 40.0; // Left edge of input boxes
        final lineEndX = boxEdgeX - lineExtension;

        // Horizontal line from first item
        canvas.drawLine(
          Offset(boxEdgeX, firstY),
          Offset(lineEndX, firstY),
          paint,
        );

        // Horizontal line from second item
        canvas.drawLine(
          Offset(boxEdgeX, secondY),
          Offset(lineEndX, secondY),
          paint,
        );

        // Vertical connecting line
        canvas.drawLine(
          Offset(lineEndX, firstY),
          Offset(lineEndX, secondY),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
