import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

import 'app.dart';
import 'core/permissions/permissions_controller.dart';
import 'features/auth/controller/auth_controller.dart';
import 'features/settings/controller/settings_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => AuthCubit()),
        BlocProvider(create: (_) => SettingsCubit()),
        BlocProvider(create: (_) => PermissionsCubit()),
      ],
      child: const EasaccApp(),
    ),
  );
}
