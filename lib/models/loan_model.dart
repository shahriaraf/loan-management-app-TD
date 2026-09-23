class LoanProductModel {
  final String id;
  final String name;
  final String? description;
  final double minAmount;
  final double maxAmount;
  final int minTenureMonths;
  final int maxTenureMonths;
  final double interestRate;
  final String interestType;
  final double processingFeePercent;
  final double lateFeeFlat;
  final int gracePeriodDays;
  final bool isGroupLoan;
  final bool isActive;

  LoanProductModel({
    required this.id,
    required this.name,
    this.description,
    required this.minAmount,
    required this.maxAmount,
    required this.minTenureMonths,
    required this.maxTenureMonths,
    required this.interestRate,
    this.interestType = 'REDUCING_BALANCE',
    this.processingFeePercent = 0,
    this.lateFeeFlat = 0,
    this.gracePeriodDays = 0,
    this.isGroupLoan = false,
    this.isActive = true,
  });

  factory LoanProductModel.fromJson(Map<String, dynamic> json) {
    return LoanProductModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString(),
      minAmount: _toDouble(json['minAmount']),
      maxAmount: _toDouble(json['maxAmount']),
      minTenureMonths: _toInt(json['minTenureMonths']),
      maxTenureMonths: _toInt(json['maxTenureMonths']),
      interestRate: _toDouble(json['interestRate']),
      interestType: json['interestType']?.toString() ?? 'REDUCING_BALANCE',
      processingFeePercent: _toDouble(json['processingFeePercent']),
      lateFeeFlat: _toDouble(json['lateFeeFlat']),
      gracePeriodDays: _toInt(json['gracePeriodDays']),
      isGroupLoan: json['isGroupLoan'] == true,
      isActive: json['isActive'] != false,
    );
  }

  static double _toDouble(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0;
  }

  static int _toInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    return int.tryParse(v.toString()) ?? 0;
  }
}

class LoanPurposeModel {
  final String id;
  final String name;
  final String? description;
  final String icon;
  final bool isActive;

  LoanPurposeModel({
    required this.id,
    required this.name,
    this.description,
    this.icon = 'Target',
    this.isActive = true,
  });

  factory LoanPurposeModel.fromJson(Map<String, dynamic> json) {
    return LoanPurposeModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString(),
      icon: json['icon']?.toString() ?? 'Target',
      isActive: json['isActive'] != false,
    );
  }
}

class LoanApplicationModel {
  final String id;
  final String applicationNumber;
  final String? customerId;
  final String? customerName;
  final String? groupId;
  final String productId;
  final String? productName;
  final double requestedAmount;
  final int requestedTenureMonths;
  final String? purpose;
  final String status;
  final String? assignedOfficerId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  LoanApplicationModel({
    required this.id,
    required this.applicationNumber,
    this.customerId,
    this.customerName,
    this.groupId,
    required this.productId,
    this.productName,
    required this.requestedAmount,
    required this.requestedTenureMonths,
    this.purpose,
    required this.status,
    this.assignedOfficerId,
    this.createdAt,
    this.updatedAt,
  });

  factory LoanApplicationModel.fromJson(Map<String, dynamic> json) {
    final customer = json['customer'];
    final product = json['product'];
    return LoanApplicationModel(
      id: json['id']?.toString() ?? '',
      applicationNumber: json['applicationNumber']?.toString() ?? '',
      customerId: json['customerId']?.toString() ?? customer?['id']?.toString(),
      customerName: customer != null
          ? '${customer['firstName'] ?? ''} ${customer['lastName'] ?? ''}'.trim()
          : json['customerName']?.toString(),
      groupId: json['groupId']?.toString(),
      productId: json['productId']?.toString() ?? product?['id']?.toString() ?? '',
      productName: product?['name']?.toString() ?? json['productName']?.toString(),
      requestedAmount: _toDouble(json['requestedAmount']),
      requestedTenureMonths: _toInt(json['requestedTenureMonths']),
      purpose: json['purpose']?.toString(),
      status: json['status']?.toString() ?? 'DRAFT',
      assignedOfficerId: json['assignedOfficerId']?.toString(),
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'].toString()) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.tryParse(json['updatedAt'].toString()) : null,
    );
  }

  static double _toDouble(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0;
  }

  static int _toInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    return int.tryParse(v.toString()) ?? 0;
  }

  String get statusLabel {
    return status.replaceAll('_', ' ');
  }

  bool get isPending => [
        'DRAFT',
        'SUBMITTED',
        'DOCUMENT_PENDING',
        'UNDER_VERIFICATION',
        'VERIFICATION_COMPLETED',
        'CREDIT_REVIEW',
        'PENDING_APPROVAL',
      ].contains(status);

  bool get isApproved => ['APPROVED', 'SANCTIONED', 'READY_FOR_DISBURSEMENT', 'DISBURSED'].contains(status);
  bool get isRejected => status == 'REJECTED' || status == 'CANCELLED';
}

class GroupModel {
  final String id;
  final String groupName;
  final String? centerName;
  final String? leaderId;
  final String? leaderName;
  final int memberCount;
  final bool isActive;
  final DateTime? formationDate;

  GroupModel({
    required this.id,
    required this.groupName,
    this.centerName,
    this.leaderId,
    this.leaderName,
    this.memberCount = 0,
    this.isActive = true,
    this.formationDate,
  });

  factory GroupModel.fromJson(Map<String, dynamic> json) {
    final members = json['members'] as List?;
    final leader = json['leader'];
    return GroupModel(
      id: json['id']?.toString() ?? '',
      groupName: json['groupName']?.toString() ?? '',
      centerName: json['centerName']?.toString(),
      leaderId: json['leaderId']?.toString() ?? leader?['id']?.toString(),
      leaderName: leader != null
          ? '${leader['firstName'] ?? ''} ${leader['lastName'] ?? ''}'.trim()
          : null,
      memberCount: members?.length ?? json['memberCount'] ?? 0,
      isActive: json['isActive'] != false,
      formationDate: json['formationDate'] != null
          ? DateTime.tryParse(json['formationDate'].toString())
          : null,
    );
  }
}
