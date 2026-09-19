import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: NotificationTestPage(),
    );
  }
}

class NotificationTestPage extends StatefulWidget {
  const NotificationTestPage({super.key});

  @override
  State<NotificationTestPage> createState() => _NotificationTestPageState();
}

class _NotificationTestPageState extends State<NotificationTestPage> {
  final emailController =
      TextEditingController(text: 'demo_user@gritt.app');

  String token = 'Getting FCM token...';
  String status = 'Waiting...';

  @override
  void initState() {
    super.initState();
    setupFirebase();
  }

  Future<void> setupFirebase() async {
    // Ask for notification permission
    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Get the FCM token
    final fcmToken = await FirebaseMessaging.instance.getToken();

    setState(() {
      token = fcmToken ?? 'No token received';
    });
  }

  Future<void> registerToken() async {
    final email = emailController.text.trim();

    if (email.isEmpty || token == 'Getting FCM token...' || token.isEmpty) {
      setState(() {
        status = 'Please wait for the FCM token first.';
      });
      return;
    }

    try {
      final response = await http.post(
        Uri.parse(
          'http://10.71.64.103:8000/api/notifications/register-token',
        ),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'email': email,
          'token': token,
        }),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        setState(() {
          status = 'Token registered successfully!';
        });
      } else {
        setState(() {
          status = 'Registration failed: ${response.statusCode}\n'
              '${response.body}';
        });
      }
    } catch (e) {
      setState(() {
        status = 'Connection error: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gritt Notification Test'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'FCM Token',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            SelectableText(
              token,
              style: const TextStyle(fontSize: 12),
            ),

            const SizedBox(height: 30),

            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: registerToken,
                child: const Text('Register Device'),
              ),
            ),

            const SizedBox(height: 20),

            Text(
              status,
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    emailController.dispose();
    super.dispose();
  }
}