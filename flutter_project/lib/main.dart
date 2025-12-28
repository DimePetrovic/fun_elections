import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/election_store.dart';
import 'screens/home_screen.dart';
import 'screens/join_screen.dart';
import 'screens/join_public_screen.dart';
import 'screens/join_private_screen.dart';
import 'screens/create_screen.dart';
import 'screens/create_settings_screen.dart';
import 'screens/election_screen_new.dart';
import 'screens/my_elections_screen.dart';
import 'screens/settings_screen.dart';
import 'services/user_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize user on app startup
  final userService = UserService();
  await userService.getOrCreateUser();
  
  runApp(const FunElectionsApp());
}

class FunElectionsApp extends StatelessWidget {
  const FunElectionsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ElectionStore(),
      child: MaterialApp(
        title: 'Fun Elections',
        theme: ThemeData(
          colorScheme: const ColorScheme.light(
            primary: Color(0xFF000000),
            onPrimary: Color(0xFFFFFFFF),
            secondary: Color(0xFF424242),
            onSecondary: Color(0xFFFFFFFF),
            surface: Color(0xFFFFFFFF),
            onSurface: Color(0xFF000000),
            surfaceContainerHighest: Color(0xFFF5F5F5),
            onSurfaceVariant: Color(0xFF757575),
            primaryContainer: Color(0xFFEEEEEE),
            onPrimaryContainer: Color(0xFF000000),
            secondaryContainer: Color(0xFFE0E0E0),
            onSecondaryContainer: Color(0xFF000000),
            tertiaryContainer: Color(0xFFF5F5F5),
            onTertiaryContainer: Color(0xFF000000),
          ),
          useMaterial3: true,
          scaffoldBackgroundColor: const Color(0xFFFFFFFF),
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFFFFFFFF),
            foregroundColor: Color(0xFF000000),
            elevation: 0,
          ),
          cardTheme: CardThemeData(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: Color(0xFFE0E0E0), width: 1),
            ),
            color: const Color(0xFFFFFFFF),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              elevation: 0,
              backgroundColor: const Color(0xFF000000),
              foregroundColor: const Color(0xFFFFFFFF),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          filledButtonTheme: FilledButtonThemeData(
            style: FilledButton.styleFrom(
              elevation: 0,
              backgroundColor: const Color(0xFF000000),
              foregroundColor: const Color(0xFFFFFFFF),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          outlinedButtonTheme: OutlinedButtonThemeData(
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF000000),
              side: const BorderSide(color: Color(0xFF000000), width: 1.5),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        initialRoute: '/',
        routes: {
          '/': (context) => const HomeScreen(),
          '/join': (context) => const JoinScreen(),
          '/join/public': (context) => const JoinPublicScreen(),
          '/join/private': (context) => const JoinPrivateScreen(),
          '/create': (context) => const CreateScreen(),
          '/create/settings': (context) => const CreateSettingsScreen(),
          '/my-elections': (context) => const MyElectionsScreen(),
          '/settings': (context) => const SettingsScreen(),
        },
        onGenerateRoute: (settings) {
          // Handle /election/:id route
          if (settings.name?.startsWith('/election/') ?? false) {
            final id = settings.name!.substring('/election/'.length);
            return MaterialPageRoute(
              settings: settings,
              builder: (context) => ElectionScreen(electionId: id),
            );
          }
          return null;
        },
      ),
    );
  }
}
