import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'canadian_moose.dart';

final mooseControllerProvider = Provider.autoDispose<MooseController>((ref) {
  final controller = MooseController();
  ref.onDispose(controller.dispose);
  return controller;
});
