import 'package:flutter/material.dart';
import 'package:medcare/features/auth/presentation/pages/login_page.dart';
import 'package:medcare/features/onboarding/presentation/pages/onboarding_page.dart';
import 'package:medcare/features/splash/presentation/pages/splash_page.dart';
import 'package:medcare/features/home/presentation/pages/home_page.dart';
import 'package:medcare/features/medications/presentation/pages/add_medication_page.dart';
import 'package:medcare/features/medications/presentation/pages/medication_details_page.dart';
import 'package:medcare/features/medications/data/medication_model.dart';
import 'package:medcare/features/profile/presentation/pages/profile_page.dart';

class AppRoutes {
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String home = '/home';
  static const String addMedication = '/add-medication';
  static const String medicationDetails = '/medication-details';
  static const String profile = '/profile';
}

class AppRouter {
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.splash:
        return _page(const SplashPage());
      case AppRoutes.onboarding:
        return _page(const OnboardingPage());
      case AppRoutes.login:
        return _page(const LoginPage());
      case AppRoutes.home:
        return _page(const HomePage());
      case AppRoutes.addMedication:
        return _page(const AddMedicationPage());
      case AppRoutes.medicationDetails:
        final args = settings.arguments;
        if (args is Medication) {
          return _page(MedicationDetailsPage(med: args));
        }
        if (args is Map && args['med'] is Medication) {
          return _page(MedicationDetailsPage(med: args['med'] as Medication));
        }
        return _page(const Scaffold(
          body: Center(child: Text('Medication not provided')),
        ));
      case AppRoutes.profile:
        return _page(const ProfilePage());
      default:
        return _page(const Scaffold(
          body: Center(child: Text('Route not found')),
        ));
    }
  }

  static PageRoute _page(Widget child) => MaterialPageRoute(builder: (_) => child);
}
