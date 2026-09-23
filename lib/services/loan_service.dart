import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';
import '../models/loan_model.dart';

class LoanService {
  final ApiClient _api = ApiClient();

  Future<List<LoanProductModel>> getProducts() async {
    final response = await _api.get(ApiConstants.loanProducts);
    final list = response.data is List ? response.data : (response.data['data'] ?? []);
    return (list as List)
        .map((e) => LoanProductModel.fromJson(e as Map<String, dynamic>))
        .where((p) => p.isActive)
        .toList();
  }

  Future<List<LoanPurposeModel>> getPurposes() async {
    final response = await _api.get(ApiConstants.loanPurposes);
    final list = response.data is List ? response.data : (response.data['data'] ?? []);
    return (list as List)
        .map((e) => LoanPurposeModel.fromJson(e as Map<String, dynamic>))
        .where((p) => p.isActive)
        .toList();
  }

  Future<List<LoanApplicationModel>> getApplications({String? status}) async {
    final response = await _api.get(
      ApiConstants.loanApplications,
      queryParameters: status != null ? {'status': status} : null,
    );
    final list = response.data is List ? response.data : (response.data['data'] ?? response.data['applications'] ?? []);
    return (list as List).map((e) => LoanApplicationModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<LoanApplicationModel> getApplicationById(String id) async {
    final response = await _api.get('${ApiConstants.loanApplications}/$id');
    final data = response.data is Map && response.data['data'] != null
        ? response.data['data']
        : response.data;
    return LoanApplicationModel.fromJson(data as Map<String, dynamic>);
  }

  Future<LoanApplicationModel> createApplication(Map<String, dynamic> payload) async {
    final response = await _api.post(ApiConstants.loanApplications, data: payload);
    final data = response.data is Map && response.data['data'] != null
        ? response.data['data']
        : response.data;
    return LoanApplicationModel.fromJson(data as Map<String, dynamic>);
  }

  Future<LoanApplicationModel> updateStatus(String id, String status, {String? remarks}) async {
    final response = await _api.patch(
      '${ApiConstants.loanApplications}/$id/status',
      data: {'status': status, if (remarks != null) 'remarks': remarks},
    );
    final data = response.data is Map && response.data['data'] != null
        ? response.data['data']
        : response.data;
    return LoanApplicationModel.fromJson(data as Map<String, dynamic>);
  }

  /// Calculate EMI locally (same formula as backend)
  double calculateEMI(double principal, double annualRate, int tenureMonths) {
    if (annualRate == 0) return principal / tenureMonths;
    if (tenureMonths <= 0) return 0;
    final monthlyRate = annualRate / 12 / 100;
    final pow = _pow(1 + monthlyRate, tenureMonths);
    final emi = (principal * monthlyRate * pow) / (pow - 1);
    return (emi * 100).round() / 100;
  }

  /// FOIR eligibility
  Map<String, dynamic> evaluateEligibility({
    required double monthlyIncome,
    required double existingEmi,
    required double requestedEmi,
  }) {
    final totalObligations = existingEmi + requestedEmi;
    final foir = monthlyIncome > 0 ? (totalObligations / monthlyIncome) * 100 : 100;
    final eligible = foir <= 50; // 50% FOIR threshold
    return {
      'foir': (foir * 100).round() / 100,
      'eligible': eligible,
      'totalObligations': totalObligations,
      'availableIncome': monthlyIncome - existingEmi,
    };
  }

  double _pow(double base, int exp) {
    double result = 1;
    for (int i = 0; i < exp; i++) {
      result *= base;
    }
    return result;
  }
}
