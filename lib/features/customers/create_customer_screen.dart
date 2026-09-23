import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/theme/app_theme.dart';
import '../../services/customer_service.dart';
import '../../widgets/common_widgets.dart';

class CreateCustomerScreen extends StatefulWidget {
  const CreateCustomerScreen({super.key});

  @override
  State<CreateCustomerScreen> createState() => _CreateCustomerScreenState();
}

class _CreateCustomerScreenState extends State<CreateCustomerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _service = CustomerService();
  final _picker = ImagePicker();

  int _step = 0;
  bool _loading = false;

  // Personal
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _fatherName = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  String _gender = 'Male';
  DateTime? _dob;

  // Address
  final _address = TextEditingController();
  final _city = TextEditingController();
  final _state = TextEditingController();
  final _pincode = TextEditingController();

  // Financial
  String _employmentType = 'Salaried';
  final _employer = TextEditingController();
  final _income = TextEditingController();
  final _existingEmi = TextEditingController(text: '0');

  // KYC
  final _pan = TextEditingController();
  final _aadhaar = TextEditingController();

  // Docs
  String? _profilePhotoUrl;
  String? _panCardUrl;
  String? _aadhaarCardUrl;
  File? _profileLocal;
  File? _panLocal;
  File? _aadhaarLocal;

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _fatherName.dispose();
    _phone.dispose();
    _email.dispose();
    _address.dispose();
    _city.dispose();
    _state.dispose();
    _pincode.dispose();
    _employer.dispose();
    _income.dispose();
    _existingEmi.dispose();
    _pan.dispose();
    _aadhaar.dispose();
    super.dispose();
  }

  Future<void> _pickImage(String type) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt, color: AppColors.primary),
                title: const Text('Camera'),
                onTap: () => Navigator.pop(ctx, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: AppColors.primary),
                title: const Text('Gallery'),
                onTap: () => Navigator.pop(ctx, ImageSource.gallery),
              ),
            ],
          ),
        ),
      ),
    );
    if (source == null) return;

    final xfile = await _picker.pickImage(source: source, imageQuality: 70, maxWidth: 1200);
    if (xfile == null) return;

    setState(() {
      if (type == 'profile') _profileLocal = File(xfile.path);
      if (type == 'pan') _panLocal = File(xfile.path);
      if (type == 'aadhaar') _aadhaarLocal = File(xfile.path);
    });
  }

  Future<String?> _uploadIfNeeded(File? file, String? existingUrl) async {
    if (file == null) return existingUrl;
    try {
      return await _service.uploadDocument(file.path);
    } catch (_) {
      return existingUrl;
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_dob == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select date of birth'), backgroundColor: AppColors.error),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      // Upload docs
      final profileUrl = await _uploadIfNeeded(_profileLocal, _profilePhotoUrl);
      final panUrl = await _uploadIfNeeded(_panLocal, _panCardUrl);
      final aadhaarUrl = await _uploadIfNeeded(_aadhaarLocal, _aadhaarCardUrl);

      final payload = {
        'firstName': _firstName.text.trim(),
        'lastName': _lastName.text.trim(),
        if (_fatherName.text.isNotEmpty) 'fatherName': _fatherName.text.trim(),
        'dob': DateTime.utc(_dob!.year, _dob!.month, _dob!.day).toIso8601String(),
        'gender': _gender,
        'email': _email.text.trim(),
        'phone': _phone.text.trim(),
        'currentAddress': _address.text.trim(),
        'city': _city.text.trim(),
        'state': _state.text.trim(),
        'pincode': _pincode.text.trim(),
        'country': 'India',
        'employmentType': _employmentType,
        if (_employer.text.isNotEmpty) 'employerName': _employer.text.trim(),
        'monthlyIncome': double.tryParse(_income.text) ?? 0,
        'existingEmi': double.tryParse(_existingEmi.text) ?? 0,
        'panNumber': _pan.text.trim().toUpperCase(),
        'aadhaarNumber': _aadhaar.text.trim(),
        if (profileUrl != null) 'profilePhotoUrl': profileUrl,
        if (panUrl != null) 'panCardUrl': panUrl,
        if (aadhaarUrl != null) 'aadhaarCardUrl': aadhaarUrl,
      };

      await _service.create(payload);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Customer created successfully'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('New Customer · Step ${_step + 1}/4'),
      ),
      body: LoadingOverlay(
        isLoading: _loading,
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Progress
              LinearProgressIndicator(
                value: (_step + 1) / 4,
                backgroundColor: AppColors.border,
                color: AppColors.primary,
                minHeight: 3,
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: _buildStep(),
                ),
              ),
              // Nav buttons
              Container(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: SafeArea(
                  child: Row(
                    children: [
                      if (_step > 0)
                        Expanded(
                          child: AppButton(
                            label: 'Back',
                            isOutlined: true,
                            onPressed: () => setState(() => _step--),
                          ),
                        ),
                      if (_step > 0) const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: AppButton(
                          label: _step == 3 ? 'Submit' : 'Continue',
                          onPressed: () {
                            if (_step < 3) {
                              if (_formKey.currentState!.validate()) {
                                setState(() => _step++);
                              }
                            } else {
                              _submit();
                            }
                          },
                          icon: _step == 3 ? Icons.check_rounded : Icons.arrow_forward_rounded,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep() {
    switch (_step) {
      case 0:
        return _personalStep();
      case 1:
        return _addressStep();
      case 2:
        return _financialStep();
      case 3:
        return _kycStep();
      default:
        return const SizedBox();
    }
  }

  Widget _personalStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Personal Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        const SizedBox(height: 20),
        AppTextField(controller: _firstName, label: 'First Name *', hint: 'Rahul', prefixIcon: Icons.person_outline,
            validator: (v) => v == null || v.isEmpty ? 'Required' : null),
        const SizedBox(height: 14),
        AppTextField(controller: _lastName, label: 'Last Name *', hint: 'Sharma',
            validator: (v) => v == null || v.isEmpty ? 'Required' : null),
        const SizedBox(height: 14),
        AppTextField(controller: _fatherName, label: 'Father\'s Name', hint: 'Optional'),
        const SizedBox(height: 14),
        AppTextField(
          controller: _phone,
          label: 'Mobile Number *',
          hint: '9876543210',
          prefixIcon: Icons.phone_outlined,
          keyboardType: TextInputType.phone,
          validator: (v) {
            if (v == null || v.isEmpty) return 'Required';
            if (v.length < 10) return 'Enter valid 10-digit number';
            return null;
          },
        ),
        const SizedBox(height: 14),
        AppTextField(
          controller: _email,
          label: 'Email *',
          hint: 'customer@email.com',
          prefixIcon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
          validator: (v) {
            if (v == null || v.isEmpty) return 'Required';
            if (!v.contains('@')) return 'Invalid email';
            return null;
          },
        ),
        const SizedBox(height: 14),
        const Text('Gender *', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textSecondary)),
        const SizedBox(height: 6),
        Row(
          children: ['Male', 'Female', 'Other'].map((g) {
            final selected = _gender == g;
            return Padding(
              padding: const EdgeInsets.only(right: 10),
              child: ChoiceChip(
                label: Text(g),
                selected: selected,
                onSelected: (_) => setState(() => _gender = g),
                selectedColor: AppColors.primarySoft,
                labelStyle: TextStyle(
                  color: selected ? AppColors.primaryDark : AppColors.textSecondary,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 14),
        AppTextField(
          label: 'Date of Birth *',
          hint: _dob == null ? 'Select date' : '${_dob!.day}/${_dob!.month}/${_dob!.year}',
          prefixIcon: Icons.calendar_today_outlined,
          readOnly: true,
          onTap: () async {
            final d = await showDatePicker(
              context: context,
              initialDate: DateTime(1990),
              firstDate: DateTime(1950),
              lastDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
            );
            if (d != null) setState(() => _dob = d);
          },
        ),
      ],
    );
  }

  Widget _addressStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Address', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        const SizedBox(height: 20),
        AppTextField(
          controller: _address,
          label: 'Current Address *',
          hint: 'House no, Street, Area',
          maxLines: 2,
          validator: (v) => v == null || v.isEmpty ? 'Required' : null,
        ),
        const SizedBox(height: 14),
        AppTextField(controller: _city, label: 'City *', hint: 'Mumbai',
            validator: (v) => v == null || v.isEmpty ? 'Required' : null),
        const SizedBox(height: 14),
        AppTextField(controller: _state, label: 'State *', hint: 'Maharashtra',
            validator: (v) => v == null || v.isEmpty ? 'Required' : null),
        const SizedBox(height: 14),
        AppTextField(
          controller: _pincode,
          label: 'Pincode *',
          hint: '400001',
          keyboardType: TextInputType.number,
          validator: (v) {
            if (v == null || v.isEmpty) return 'Required';
            if (v.length != 6) return 'Enter 6-digit pincode';
            return null;
          },
        ),
      ],
    );
  }

  Widget _financialStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Employment & Income', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        const SizedBox(height: 20),
        const Text('Employment Type *', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textSecondary)),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          children: ['Salaried', 'Self-Employed', 'Business', 'Farmer', 'Other'].map((e) {
            final selected = _employmentType == e;
            return ChoiceChip(
              label: Text(e),
              selected: selected,
              onSelected: (_) => setState(() => _employmentType = e),
              selectedColor: AppColors.primarySoft,
              labelStyle: TextStyle(
                color: selected ? AppColors.primaryDark : AppColors.textSecondary,
                fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                fontSize: 12,
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 14),
        AppTextField(controller: _employer, label: 'Employer / Business Name', hint: 'Optional'),
        const SizedBox(height: 14),
        AppTextField(
          controller: _income,
          label: 'Monthly Income (₹) *',
          hint: '25000',
          prefixIcon: Icons.currency_rupee,
          keyboardType: TextInputType.number,
          validator: (v) {
            if (v == null || v.isEmpty) return 'Required';
            if (double.tryParse(v) == null) return 'Enter valid amount';
            return null;
          },
        ),
        const SizedBox(height: 14),
        AppTextField(
          controller: _existingEmi,
          label: 'Existing EMI (₹)',
          hint: '0',
          prefixIcon: Icons.payments_outlined,
          keyboardType: TextInputType.number,
        ),
      ],
    );
  }

  Widget _kycStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('KYC Documents', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        const SizedBox(height: 20),
        AppTextField(
          controller: _pan,
          label: 'PAN Number *',
          hint: 'ABCDE1234F',
          prefixIcon: Icons.badge_outlined,
          validator: (v) {
            if (v == null || v.isEmpty) return 'Required';
            if (v.length != 10) return 'PAN must be 10 characters';
            return null;
          },
        ),
        const SizedBox(height: 14),
        AppTextField(
          controller: _aadhaar,
          label: 'Aadhaar Number *',
          hint: '1234 5678 9012',
          prefixIcon: Icons.fingerprint,
          keyboardType: TextInputType.number,
          validator: (v) {
            if (v == null || v.isEmpty) return 'Required';
            final clean = v.replaceAll(' ', '');
            if (clean.length != 12) return 'Aadhaar must be 12 digits';
            return null;
          },
        ),
        const SizedBox(height: 24),
        const Text('Capture Documents', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        _docPicker('Profile Photo', _profileLocal, () => _pickImage('profile')),
        const SizedBox(height: 10),
        _docPicker('PAN Card Photo', _panLocal, () => _pickImage('pan')),
        const SizedBox(height: 10),
        _docPicker('Aadhaar Card Photo', _aadhaarLocal, () => _pickImage('aadhaar')),
      ],
    );
  }

  Widget _docPicker(String label, File? file, VoidCallback onTap) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: file != null ? AppColors.primary : AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: file != null ? AppColors.primarySoft : AppColors.background,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: file != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.file(file, fit: BoxFit.cover),
                      )
                    : const Icon(Icons.camera_alt_outlined, color: AppColors.textMuted),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
                    Text(
                      file != null ? 'Photo captured ✓' : 'Tap to capture',
                      style: TextStyle(
                        fontSize: 12,
                        color: file != null ? AppColors.success : AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                file != null ? Icons.check_circle : Icons.add_a_photo_outlined,
                color: file != null ? AppColors.success : AppColors.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
