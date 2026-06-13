import 'package:flutter_bloc/flutter_bloc.dart';

class SettingsCubit extends Cubit<double> {
  SettingsCubit() : super(1.0); // 1.0 is the default text scale

  void updateFontSize(double scale) => emit(scale);
}