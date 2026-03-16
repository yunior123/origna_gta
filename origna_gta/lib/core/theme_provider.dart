import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Controls the app-wide theme mode (light / dark / system).
/// Defaults to [ThemeMode.dark] — OrignaGTA is a dark-first app.
/// The OS preference is intentionally overridden to guarantee consistent
/// dark backgrounds across all platforms (avoids white-text-on-white-bg on web).
final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.dark);
