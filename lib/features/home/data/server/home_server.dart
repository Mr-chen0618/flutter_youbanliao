import '../model/home_model.dart';
import '../request-model/home_invite_request_model.dart';
import '../request-model/home_list_request_model.dart';

abstract interface class HomeServer {
  Future<HomeModel> getHome({required HomeListRequestModel params});
  Future<void> submitInvite({required HomeInviteRequestModel params});
}
