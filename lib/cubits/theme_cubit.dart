import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supa/cubits/profile_cubit.dart';

class ThemeCubit extends Cubit<bool> {
  final ProfileCubit profileCubit;

  ThemeCubit(this.profileCubit) : super(false) {
    // Initial state from profile if available
    final state = profileCubit.state;
    if (state is ProfileLoaded) {
      emit(state.profile.isLightMode);
    }
  }

  void toggleTheme() {
    final newMode = !state;
    emit(newMode);
    profileCubit.updateProfile(isLightMode: newMode);
  }

  void updateTheme(bool isLightMode) {
    if (state != isLightMode) {
      emit(isLightMode);
    }
  }
}
