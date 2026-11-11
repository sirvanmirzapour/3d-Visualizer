import 'package:flutter_riverpod/flutter_riverpod.dart';

class NavController extends StateNotifier<int> {
  NavController() : super(0);

  void goTo(int index) => state = index;
}

final navControllerProvider =
    StateNotifierProvider<NavController, int>((ref) => NavController());
