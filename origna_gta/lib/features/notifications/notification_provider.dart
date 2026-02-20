import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Tracks whether notification permission has been granted
final notificationPermissionProvider = StateProvider<bool>((ref) => false);
