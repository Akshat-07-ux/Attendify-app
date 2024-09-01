import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HomeScreen extends StatefulWidget {
  final double targetLatitude;
  final double targetLongitude;

  HomeScreen({
    required this.targetLatitude,
    required this.targetLongitude,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController nameController = TextEditingController();
  bool isLoading = true;
  String userName = '';

  @override
  void initState() {
    super.initState();
    _loadUserName();
  }

  Future<void> _loadUserName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists) {
        setState(() {
          userName = doc.data()?['name'] ?? '';
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  void _saveName() async {
    if (nameController.text.isNotEmpty) {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
          'name': nameController.text.trim(),
        });
        setState(() {
          userName = nameController.text.trim();
        });
      }
    }
  }

  void navigateToAttendancePage() {
  Navigator.pushNamed(
    context,
    '/attendance',
    arguments: {
      'targetLatitude': widget.targetLatitude,
      'targetLongitude': widget.targetLongitude,
      'name': userName,
      'email': FirebaseAuth.instance.currentUser?.email ?? '',
      'uid': FirebaseAuth.instance.currentUser?.uid ?? '', // Add this line
    },
  );
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home Page'),
        centerTitle: true,
        backgroundColor: Colors.grey[700],
        
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (userName.isEmpty)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            TextField(
                              controller: nameController,
                              decoration: const InputDecoration(
                                labelText: 'Enter your name',
                                border: OutlineInputBorder(),
                              ),
                            ),
                            const SizedBox(height: 20),
                            ElevatedButton(
                              onPressed: () {
                                _saveName();
                                navigateToAttendancePage();
                              },
                              child: const Text('Save and Proceed'),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    Column(
                      children: [
                        Text(
                          'Hello $userName, Welcome to Attendify App',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: navigateToAttendancePage,
                          child: const Text('Proceed to Attendance Page'),
                        ),
                      ],
                    ),
                ],
              ),
            ),
    );
  }
}