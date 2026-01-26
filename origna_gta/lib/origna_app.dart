import 'package:flutter/material.dart';
import 'package:origna_gta/authwrapper_screen.dart';
import 'package:origna_gta/ordersuccess_screen.dart';

class OrignaApp extends StatelessWidget {
  const OrignaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OrignaGta',
      debugShowCheckedModeBanner: false,
      onGenerateRoute: (settings) {
        //TODO: check payment success
          Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => OrderSuccessScreen(orderId: "orderId")), (route) => route.isFirst);
        
      },
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFFF6B35), brightness: Brightness.light),
        scaffoldBackgroundColor: const Color(0xFFF8F9FA),
        fontFamily: 'Roboto',
        appBarTheme: const AppBarTheme(centerTitle: false, elevation: 0, scrolledUnderElevation: 2),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFFF6B35), width: 2),
          ),
        ),
      ),
      home: const AuthWrapper(),
    );
  }
}


