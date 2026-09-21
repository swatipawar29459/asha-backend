import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';

import 'theme/asha_theme.dart';

import 'services/notification_service.dart';
import 'services/health_profile_store.dart';

import 'screens/splash_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';

import 'screens/cycle_setup_screen.dart';
import 'screens/last_period_screen.dart';
import 'screens/sleep_screen.dart';
import 'screens/diet_screen.dart';
import 'screens/pcos_screen.dart';
import 'screens/symptoms_onboard_screen.dart';

import 'screens/root_shell.dart';

import 'screens/quick_log_screen.dart';
import 'screens/discharge_tracker_screen.dart';
import 'screens/why_prediction_screen.dart';
import 'screens/find_doctor_screen.dart';
import 'screens/reminders_screen.dart';
import 'screens/notification_screen.dart';
import 'screens/article_screen.dart';
import 'screens/update_last_period_screen.dart';

import 'screens/bmi_screen.dart';
import 'screens/exercise_screen.dart';


void main() async {

  WidgetsFlutterBinding.ensureInitialized();


  // ==========================================================
  // FIREBASE
  // ==========================================================

  await Firebase.initializeApp(
    options:
        DefaultFirebaseOptions.currentPlatform,
  );


  await HealthProfileStore.load();
  await NotificationService.init();
  await NotificationService.scheduleCycleNotification();


  // ==========================================================
  // START APP
  // ==========================================================

  runApp(
    const AshaApp(),
  );
}


class AshaApp
    extends StatelessWidget {

  const AshaApp({
    super.key,
  });


  @override
  Widget build(
    BuildContext context,
  ) {

    return MaterialApp(

      title: 'Asha',

      debugShowCheckedModeBanner:
          false,

      theme:
          AshaTheme.light(),


      // ======================================================
      // INITIAL SCREEN
      // ======================================================

      home:
          const SplashScreen(),


      // ======================================================
      // ROUTES
      // ======================================================

      routes: {

        '/onboarding':
            (_) =>
                const OnboardingScreen(),


        '/login':
            (_) =>
                const LoginScreen(),


        '/register':
            (_) =>
                const RegisterScreen(),


        // ----------------------------------------------------
        // ONBOARDING
        // ----------------------------------------------------

        '/cycle-setup':
            (_) =>
                const CycleSetupScreen(),


        '/onboard-last-period':
            (_) =>
                const LastPeriodScreen(),


        '/onboard-bmi':
            (_) =>
                const BmiScreen(),


        '/onboard-exercise':
            (_) =>
                const ExerciseScreen(),


        '/onboard-sleep':
            (_) =>
                const SleepScreen(),


        '/onboard-diet':
            (_) =>
                const DietScreen(),


        '/onboard-pcos':
            (_) =>
                const PcosScreen(),


        '/onboard-symptoms':
            (_) =>
                const SymptomsOnboardScreen(),


        // ----------------------------------------------------
        // MAIN APP
        // ----------------------------------------------------

        '/home':
            (_) =>
                const RootShell(),


        '/quick-log':
            (_) =>
                const QuickLogScreen(),


        '/discharge':
            (_) =>
                const DischargeTrackerScreen(),


        '/why-prediction':
            (_) =>
                const WhyPredictionScreen(),


        '/find-doctor':
            (_) =>
                const FindDoctorScreen(),


        '/reminders':
            (_) =>
                const RemindersScreen(),


        '/notifications':
            (_) =>
                const NotificationScreen(),


        '/article':
            (_) =>
                const ArticleScreen(),


        '/update-last-period':
            (_) =>
                const UpdateLastPeriodScreen(),
      },
    );
  }
}