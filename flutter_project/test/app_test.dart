import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:fun_elections/main.dart';
import 'package:fun_elections/providers/election_store.dart';
import 'package:fun_elections/models/election.dart';

void main() {
  testWidgets('App loads home screen', (WidgetTester tester) async {
    await tester.pumpWidget(const FunElectionsApp());
    expect(find.text('Fun Elections'), findsOneWidget);
    expect(find.text('Join'), findsOneWidget);
    expect(find.text('Create'), findsOneWidget);
  });

  testWidgets('Can navigate to join screen', (WidgetTester tester) async {
    await tester.pumpWidget(const FunElectionsApp());
    await tester.tap(find.text('Join'));
    await tester.pumpAndSettle();
    expect(find.text('Join Public Election'), findsOneWidget);
    expect(find.text('Join Private Election'), findsOneWidget);
  });

  testWidgets('Join private with code AAAA works', (WidgetTester tester) async {
    await tester.pumpWidget(const FunElectionsApp());
    
    // Navigate to join private
    await tester.tap(find.text('Join'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Join Private Election'));
    await tester.pumpAndSettle();
    
    // Enter code
    await tester.enterText(find.byType(TextField), 'AAAA');
    await tester.tap(find.text('Join Election'));
    await tester.pumpAndSettle();
    
    // Should navigate to election screen
    expect(find.text('Secret Tournament'), findsWidgets);
  });

  testWidgets('Can navigate to create screen', (WidgetTester tester) async {
    await tester.pumpWidget(const FunElectionsApp());
    await tester.tap(find.text('Create'));
    await tester.pumpAndSettle();
    expect(find.text('Create Election'), findsWidgets);
    expect(find.text('Election Name *'), findsOneWidget);
  });

  testWidgets('ElectionStore creates elections correctly', (WidgetTester tester) async {
    final store = ElectionStore();
    
    // Check initial mock data
    expect(store.publicElections.length, greaterThan(0));
    
    // Create new election
    final id = store.createElection(
      name: 'Test Election',
      description: 'Test Description',
      format: ElectionFormat.knockout,
      competitorNames: ['A', 'B', 'C', 'D'],
      isPublic: true,
    );
    
    final election = store.getElectionById(id);
    expect(election, isNotNull);
    expect(election!.name, 'Test Election');
    expect(election.competitors.length, 4);
  });

  testWidgets('Randomize works', (WidgetTester tester) async {
    final store = ElectionStore();
    final id = store.createElection(
      name: 'Test',
      description: '',
      format: ElectionFormat.knockout,
      competitorNames: ['A', 'B', 'C', 'D'],
      isPublic: true,
    );
    
    final election = store.getElectionById(id)!;
    final originalOrder = election.competitors.map((c) => c.name).toList();
    
    // Randomize multiple times - at least one should be different
    bool orderChanged = false;
    for (int i = 0; i < 10; i++) {
      store.randomizeCompetitors(id);
      final newElection = store.getElectionById(id)!;
      final newOrder = newElection.competitors.map((c) => c.name).toList();
      if (originalOrder.toString() != newOrder.toString()) {
        orderChanged = true;
        break;
      }
    }
    
    expect(orderChanged, isTrue);
  });
}
