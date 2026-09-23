import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';
import '../models/loan_model.dart';

class GroupService {
  final ApiClient _api = ApiClient();

  Future<List<GroupModel>> getAll() async {
    final response = await _api.get(ApiConstants.groups);
    final list = response.data is List ? response.data : (response.data['data'] ?? response.data['groups'] ?? []);
    return (list as List).map((e) => GroupModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<GroupModel> getById(String id) async {
    final response = await _api.get('${ApiConstants.groups}/$id');
    final data = response.data is Map && response.data['data'] != null
        ? response.data['data']
        : response.data;
    return GroupModel.fromJson(data as Map<String, dynamic>);
  }

  Future<GroupModel> create(Map<String, dynamic> payload) async {
    final response = await _api.post(ApiConstants.groups, data: payload);
    final data = response.data is Map && response.data['data'] != null
        ? response.data['data']
        : response.data;
    return GroupModel.fromJson(data as Map<String, dynamic>);
  }

  Future<void> addMember(String groupId, String customerId) async {
    await _api.post('${ApiConstants.groups}/$groupId/members', data: {
      'customerId': customerId,
    });
  }

  Future<void> removeMember(String groupId, String customerId) async {
    await _api.delete('${ApiConstants.groups}/$groupId/members/$customerId');
  }
}
