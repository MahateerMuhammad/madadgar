import 'package:flutter/material.dart';
import 'package:madadgar/config/theme.dart';

import 'package:madadgar/screens/auth/login_screen.dart';
import 'package:madadgar/screens/auth/register_screen.dart';
import 'package:madadgar/config/routes.dart';
import 'package:madadgar/screens/home/home_screen.dart';

import 'package:provider/provider.dart';
import 'package:madadgar/services/auth_service.dart';
import 'package:madadgar/services/post_service.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:madadgar/firebase_options.dart';

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
