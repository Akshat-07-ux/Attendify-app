import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserDetailsForm extends StatefulWidget {
  final String email;

  UserDetailsForm({required this.email});

  @override
  _UserDetailsFormState createState() => _UserDetailsFormState();
}

class _UserDetailsFormState extends State<UserDetailsForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _presentsController = TextEditingController();
  final _absentsController = TextEditingController();
  final _clController = TextEditingController();
  final _elController = TextEditingController();
  final _slController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUserDetails();
  }

  void _loadUserDetails() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        setState(() {
          _nameController.text = data['name'] ?? '';
          _emailController.text = data['email'] ?? '';
          _phoneController.text = data['phone'] ?? '';
          _addressController.text = data['address'] ?? '';
          _presentsController.text = data['presents']?.toString() ?? '';
          _absentsController.text = data['absents']?.toString() ?? '';
          _clController.text = data['cl']?.toString() ?? '';
          _elController.text = data['el']?.toString() ?? '';
          _slController.text = data['sl']?.toString() ?? '';
        });
      }
    }
  }

  void _saveUserDetails() async {
    if (_formKey.currentState!.validate()) {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
          'name': _nameController.text,
          'email': _emailController.text,
          'phone': _phoneController.text,
          'address': _addressController.text,
          'presents': int.tryParse(_presentsController.text) ?? 0,
          'absents': int.tryParse(_absentsController.text) ?? 0,
          'cl': int.tryParse(_clController.text) ?? 0,
          'el': int.tryParse(_elController.text) ?? 0,
          'sl': int.tryParse(_slController.text) ?? 0,
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('User details saved successfully')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          TextFormField(
            controller: _nameController,
            decoration: InputDecoration(labelText: 'Name'),
            validator: (value) => value!.isEmpty ? 'Please enter your name' : null,
          ),
          TextFormField(
            controller: _emailController,
            decoration: InputDecoration(labelText: 'Email'),
            validator: (value) => value!.isEmpty ? 'Please enter your email' : null,
          ),
          TextFormField(
            controller: _phoneController,
            decoration: InputDecoration(labelText: 'Phone'),
            validator: (value) => value!.isEmpty ? 'Please enter your phone number' : null,
          ),
          TextFormField(
            controller: _addressController,
            decoration: InputDecoration(labelText: 'Address'),
            validator: (value) => value!.isEmpty ? 'Please enter your address' : null,
          ),
          TextFormField(
            controller: _presentsController,
            decoration: InputDecoration(labelText: 'Present'),
            keyboardType: TextInputType.number,
          ),
          TextFormField(
            controller: _absentsController,
            decoration: InputDecoration(labelText: 'Absent'),
            keyboardType: TextInputType.number,
          ),
          Text('Leave', style: TextStyle(fontWeight: FontWeight.bold)),
          TextFormField(
            controller: _clController,
            decoration: InputDecoration(labelText: 'CL'),
            keyboardType: TextInputType.number,
          ),
          TextFormField(
            controller: _elController,
            decoration: InputDecoration(labelText: 'EL'),
            keyboardType: TextInputType.number,
          ),
          TextFormField(
            controller: _slController,
            decoration: InputDecoration(labelText: 'SL'),
            keyboardType: TextInputType.number,
          ),
          ElevatedButton(
            onPressed: _saveUserDetails,
            child: Text('Save Details'),
          ),
        ],
      ),
    );
  }
}