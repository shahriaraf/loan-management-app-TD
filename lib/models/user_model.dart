class UserModel {
  final String id;
  final String email;
  final String name;
  final String? mobileNumber;
  final String? gender;
  final String? profilePhotoUrl;
  final String status;
  final String? roleId;
  final String? roleName;
  final bool isTwoFactorEnabled;

  UserModel({
    required this.id,
    required this.email,
    required this.name,
    this.mobileNumber,
    this.gender,
    this.profilePhotoUrl,
    required this.status,
    this.roleId,
    this.roleName,
    this.isTwoFactorEnabled = false,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      mobileNumber: json['mobileNumber']?.toString(),
      gender: json['gender']?.toString(),
      profilePhotoUrl: json['profilePhotoUrl']?.toString(),
      status: json['status']?.toString() ?? 'ACTIVE',
      roleId: json['roleId']?.toString() ?? json['role']?['id']?.toString(),
      roleName: json['role']?['name']?.toString() ?? json['roleName']?.toString(),
      isTwoFactorEnabled: json['isTwoFactorEnabled'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'name': name,
        'mobileNumber': mobileNumber,
        'gender': gender,
        'profilePhotoUrl': profilePhotoUrl,
        'status': status,
        'roleId': roleId,
        'roleName': roleName,
        'isTwoFactorEnabled': isTwoFactorEnabled,
      };

  String get initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : 'A';
  }
}
