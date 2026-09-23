class CustomerModel {
  final String id;
  final String customerNumber;
  final String firstName;
  final String lastName;
  final String? fatherName;
  final String? motherName;
  final DateTime? dob;
  final String gender;
  final String? maritalStatus;
  final String email;
  final String phone;
  final String currentAddress;
  final String? permanentAddress;
  final String city;
  final String state;
  final String pincode;
  final String country;
  final String employmentType;
  final String? employerName;
  final String? designation;
  final int? workExperienceYears;
  final double monthlyIncome;
  final double existingEmi;
  final String panNumber;
  final String aadhaarNumber;
  final String? profilePhotoUrl;
  final String? panCardUrl;
  final String? aadhaarCardUrl;
  final String? incomeProofUrl;
  final String? bankStatementUrl;
  final String status;
  final String? groupId;
  final DateTime? createdAt;

  CustomerModel({
    required this.id,
    required this.customerNumber,
    required this.firstName,
    required this.lastName,
    this.fatherName,
    this.motherName,
    this.dob,
    required this.gender,
    this.maritalStatus,
    required this.email,
    required this.phone,
    required this.currentAddress,
    this.permanentAddress,
    required this.city,
    required this.state,
    required this.pincode,
    this.country = 'India',
    required this.employmentType,
    this.employerName,
    this.designation,
    this.workExperienceYears,
    required this.monthlyIncome,
    this.existingEmi = 0,
    required this.panNumber,
    required this.aadhaarNumber,
    this.profilePhotoUrl,
    this.panCardUrl,
    this.aadhaarCardUrl,
    this.incomeProofUrl,
    this.bankStatementUrl,
    this.status = 'ACTIVE',
    this.groupId,
    this.createdAt,
  });

  String get fullName => '$firstName $lastName'.trim();

  String get initials {
    return '${firstName.isNotEmpty ? firstName[0] : ''}${lastName.isNotEmpty ? lastName[0] : ''}'.toUpperCase();
  }

  factory CustomerModel.fromJson(Map<String, dynamic> json) {
    return CustomerModel(
      id: json['id']?.toString() ?? '',
      customerNumber: json['customerNumber']?.toString() ?? '',
      firstName: json['firstName']?.toString() ?? '',
      lastName: json['lastName']?.toString() ?? '',
      fatherName: json['fatherName']?.toString(),
      motherName: json['motherName']?.toString(),
      dob: json['dob'] != null ? DateTime.tryParse(json['dob'].toString()) : null,
      gender: json['gender']?.toString() ?? '',
      maritalStatus: json['maritalStatus']?.toString(),
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      currentAddress: json['currentAddress']?.toString() ?? '',
      permanentAddress: json['permanentAddress']?.toString(),
      city: json['city']?.toString() ?? '',
      state: json['state']?.toString() ?? '',
      pincode: json['pincode']?.toString() ?? '',
      country: json['country']?.toString() ?? 'India',
      employmentType: json['employmentType']?.toString() ?? '',
      employerName: json['employerName']?.toString(),
      designation: json['designation']?.toString(),
      workExperienceYears: json['workExperienceYears'] is int
          ? json['workExperienceYears']
          : int.tryParse(json['workExperienceYears']?.toString() ?? ''),
      monthlyIncome: _toDouble(json['monthlyIncome']),
      existingEmi: _toDouble(json['existingEmi']),
      panNumber: json['panNumber']?.toString() ?? '',
      aadhaarNumber: json['aadhaarNumber']?.toString() ?? '',
      profilePhotoUrl: json['profilePhotoUrl']?.toString(),
      panCardUrl: json['panCardUrl']?.toString(),
      aadhaarCardUrl: json['aadhaarCardUrl']?.toString(),
      incomeProofUrl: json['incomeProofUrl']?.toString(),
      bankStatementUrl: json['bankStatementUrl']?.toString(),
      status: json['status']?.toString() ?? 'ACTIVE',
      groupId: json['groupId']?.toString(),
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'].toString()) : null,
    );
  }

  Map<String, dynamic> toCreateJson() {
    return {
      'firstName': firstName,
      'lastName': lastName,
      if (fatherName != null) 'fatherName': fatherName,
      if (motherName != null) 'motherName': motherName,
      if (dob != null) 'dob': dob!.toIso8601String().split('T').first,
      'gender': gender,
      if (maritalStatus != null) 'maritalStatus': maritalStatus,
      'email': email,
      'phone': phone,
      'currentAddress': currentAddress,
      if (permanentAddress != null) 'permanentAddress': permanentAddress,
      'city': city,
      'state': state,
      'pincode': pincode,
      'country': country,
      'employmentType': employmentType,
      if (employerName != null) 'employerName': employerName,
      if (designation != null) 'designation': designation,
      if (workExperienceYears != null) 'workExperienceYears': workExperienceYears,
      'monthlyIncome': monthlyIncome,
      'existingEmi': existingEmi,
      'panNumber': panNumber,
      'aadhaarNumber': aadhaarNumber,
      if (profilePhotoUrl != null) 'profilePhotoUrl': profilePhotoUrl,
      if (panCardUrl != null) 'panCardUrl': panCardUrl,
      if (aadhaarCardUrl != null) 'aadhaarCardUrl': aadhaarCardUrl,
      if (incomeProofUrl != null) 'incomeProofUrl': incomeProofUrl,
      if (bankStatementUrl != null) 'bankStatementUrl': bankStatementUrl,
    };
  }

  static double _toDouble(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0;
  }
}
