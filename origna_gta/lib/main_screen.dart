import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:origna_gta/home_screen.dart';
import 'package:origna_gta/utils.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  UserModel? _userModel;
  bool _isLoadingUser = true;

  @override
  Widget build(BuildContext context) {
    if (_isLoadingUser) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF6B35)))),
      );
    }
    return HomeScreen(userModel: _userModel);
  }

  @override
  void initState() {
    super.initState();
    _loadUserModel();
  }

  Future<void> _loadUserModel() async {
    final user = FirebaseAuth.instance.currentUser;
    
    // If no user, just set loading to false and continue with null userModel
    if (user == null) {
      setState(() => _isLoadingUser = false);
      return;
    }
    
    try {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();

      if (!userDoc.exists) {
        setState(() => _isLoadingUser = false);
        return;
      }

      final userData = userDoc.data();

      setState(() {
        if (userData != null) {
          _userModel = UserModel.fromMap(userData);
        }
        _isLoadingUser = false;
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error loading user: $e');
      }
      setState(() => _isLoadingUser = false);
    }
  }
}
