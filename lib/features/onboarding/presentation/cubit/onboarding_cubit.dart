import 'package:flutter_bloc/flutter_bloc.dart';

class OnboardingState {
  final int index;
  final int total;
  const OnboardingState({required this.index, required this.total});

  bool get isLast => index == total - 1;

  OnboardingState copyWith({int? index, int? total}) =>
      OnboardingState(index: index ?? this.index, total: total ?? this.total);
}

class OnboardingCubit extends Cubit<OnboardingState> {
  OnboardingCubit(int total) : super(OnboardingState(index: 0, total: total));

  void setIndex(int i) => emit(state.copyWith(index: i));

  void next() {
    if (state.index < state.total - 1) {
      emit(state.copyWith(index: state.index + 1));
    }
  }
}
