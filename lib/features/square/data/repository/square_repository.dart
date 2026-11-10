import '../model/square_state.dart';

abstract interface class SquareRepository {
  Future<SquareState> load();
  Future<void> save(SquareState data);
}
