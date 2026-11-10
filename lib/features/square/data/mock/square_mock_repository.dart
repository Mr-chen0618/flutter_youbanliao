import '../../../../core/storage/mock_json_store.dart';
import '../model/square_state.dart';
import '../repository/square_repository.dart';

class SquareMockRepository implements SquareRepository {
  const SquareMockRepository(this.store);
  final MockJsonStore store;
  static const _path = 'square/feed';

  SquareState _decode(Object? json) =>
      SquareState.fromJson(json as Map<String, dynamic>);

  @override
  Future<SquareState> load() => store.read(_path, _decode);

  @override
  Future<void> save(SquareState data) => store.write(_path, data.toJson());
}
