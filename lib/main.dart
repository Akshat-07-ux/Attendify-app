import 'package:flutter/material.dart';
import 'package:attendance/responsive/mobile_screen.dart';
import 'package:attendance/responsive/web_screen.dart';
import 'package:attendance/responsive/responsive.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:attendance/features/attendance_page.dart';
import 'package:attendance/screens/home_screen.dart';
import 'package:attendance/screens/auth/login_screen.dart';
import 'package:attendance/screens/auth/signup_screen.dart';
import 'package:attendance/screens/auth/admin_login_screen.dart';
import 'package:attendance/screens/admin_dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  static const  targetLatitude = 25.596802;
  static const  targetLongitude =  85.088756;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Attendance App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => Responsive(
              mobileScreen: MobileScreen(),
              webScreen: WebScreen(),
            ),
        '/login': (context) => LoginScreen(
              targetLatitude: targetLatitude,
              targetLongitude: targetLongitude,
            ),
        '/signup': (context) => const SignUpScreen(),
        '/home': (context) => HomeScreen(
              targetLatitude: targetLatitude,
              targetLongitude: targetLongitude,
            ),
        '/attendance': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
          return AttendancePage(
            targetLatitude: args['targetLatitude'],
            targetLongitude: args['targetLongitude'],
            name: args['name'] ?? 'User Name',
            email: args['email'] ?? 'example@example.com',
            uid: args['uid'] ?? '', 
          );
        },
        '/attendanceRecord': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
          return AttendancePage(  // Changed from AttendanceRecordPage to AttendancePage
            targetLatitude: args['targetLatitude'],
            targetLongitude: args['targetLongitude'],
            name: args['name'] ?? 'User Name',
            email: args['email'] ?? 'example@example.com',
            uid: args['uid'] ?? '',
          );
        },
        '/adminLogin': (context) => AdminLoginScreen(),
        '/adminDashboard': (context) => AdminDashboardScreen(),
      },
    );
  }
}