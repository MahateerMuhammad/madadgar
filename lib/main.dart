import 'package:flutter/material.dart';
import 'package:***REMOVED***/config/theme.dart';

import 'package:***REMOVED***/screens/auth/login_screen.dart';
import 'package:***REMOVED***/screens/auth/register_screen.dart';
import 'package:***REMOVED***/config/routes.dart';
import 'package:***REMOVED***/screens/home/home_screen.dart';

import 'package:provider/provider.dart';
import 'package:***REMOVED***/services/auth_service.dart';
import 'package:***REMOVED***/services/post_service.dart';
import 'package:***REMOVED***/services/edu_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:***REMOVED***/firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthService>(create: (_) => AuthService()),
        Provider<PostService>(create: (_) => PostService()),
         Provider<EducationalResourceService>(
          create: (_) => EducationalResourceService())
      ],
      child: MaterialApp(
        title: 'Madadgar',
        debugShowCheckedModeBanner: false,
        theme: MadadgarTheme.lightTheme,
        initialRoute: AppRoutes.login,
        routes: {
          AppRoutes.login: (context) => const LoginScreen(),
          AppRoutes.register: (context) => const RegisterScreen(),
          AppRoutes.home: (context) => HomeScreen(),
        },
      ),
    );
  }
}
