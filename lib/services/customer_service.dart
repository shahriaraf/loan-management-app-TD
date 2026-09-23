import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';
import '../models/customer_model.dart';

class CustomerService {
  final ApiClient _api = ApiClient();

  Future<List<CustomerModel>> getAll({String? search}) async {
    final response = await _api.get(
      ApiConstants.customers,
      queryParameters: search != null && search.isNotEmpty ? {'search': search} : null,
    );
    final list = response.data is List ? response.data : (response.data['data'] ?? response.data['customers'] ?? []);
    return (list as List).map((e) => CustomerModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<CustomerModel> getById(String id) async {
    final response = await _api.get('${ApiConstants.customers}/$id');
    final data = response.data is Map && response.data['data'] != null
        ? response.data['data']
        : response.data;
    return CustomerModel.fromJson(data as Map<String, dynamic>);
  }

  Future<CustomerModel> create(Map<String, dynamic> payload) async {
    final response = await _api.post(ApiConstants.customers, data: payload);
    final data = response.data is Map && response.data['data'] != null
        ? response.data['data']
        : response.data;
    return CustomerModel.fromJson(data as Map<String, dynamic>);
  }

  Future<CustomerModel> update(String id, Map<String, dynamic> payload) async {
    final response = await _api.patch('${ApiConstants.customers}/$id', data: payload);
    final data = response.data is Map && response.data['data'] != null
        ? response.data['data']
        : response.data;
    return CustomerModel.fromJson(data as Map<String, dynamic>);
  }

  Future<String> uploadDocument(String filePath) async {
    final response = await _api.uploadFile(ApiConstants.upload, filePath);
    final data = response.data;
    // Expect { url: "..." } or { data: { url: "..." } }
    if (data is Map) {
      return (data['url'] ?? data['data']?['url'] ?? data['path'] ?? '').toString();
    }
    return data.toString();
  }
}
