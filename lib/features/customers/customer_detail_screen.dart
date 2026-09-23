import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../models/customer_model.dart';
import '../../services/customer_service.dart';
import '../../widgets/common_widgets.dart';
import '../loans/new_loan_screen.dart';

class CustomerDetailScreen extends StatefulWidget {
  final String customerId;
  const CustomerDetailScreen({super.key, required this.customerId});

  @override
  State<CustomerDetailScreen> createState() => _CustomerDetailScreenState();
}

class _CustomerDetailScreenState extends State<CustomerDetailScreen> {
  CustomerModel? _customer;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final c = await CustomerService().getById(widget.customerId);
      setState(() => _customer = c);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Customer Details')),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _error != null || _customer == null
              ? EmptyState(
                  icon: Icons.error_outline,
                  title: 'Could not load customer',
                  subtitle: _error,
                  actionLabel: 'Retry',
                  onAction: _load,
                )
              : _buildContent(_customer!),
      bottomNavigationBar: _customer != null
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: AppButton(
                  label: 'Start Loan Application',
                  icon: Icons.add_chart_rounded,
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => NewLoanScreen(preselectedCustomer: _customer),
                      ),
                    );
                  },
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildContent(CustomerModel c) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Header card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              CircleAvatar(
                radius: 36,
                backgroundColor: AppColors.primarySoft,
                child: Text(
                  c.initials,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryDark,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                c.fullName,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(c.customerNumber, style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
              const SizedBox(height: 8),
              StatusChip(status: c.status),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _infoCard('Contact', [
          _row(Icons.phone, 'Phone', c.phone),
          _row(Icons.email, 'Email', c.email),
        ]),
        const SizedBox(height: 12),
        _infoCard('Address', [
          _row(Icons.location_on, 'Address', c.currentAddress),
          _row(Icons.location_city, 'City', '${c.city}, ${c.state} - ${c.pincode}'),
        ]),
        const SizedBox(height: 12),
        _infoCard('Financial', [
          _row(Icons.work, 'Employment', c.employmentType),
          if (c.employerName != null) _row(Icons.business, 'Employer', c.employerName!),
          _row(Icons.currency_rupee, 'Monthly Income', '₹${c.monthlyIncome.toStringAsFixed(0)}'),
          _row(Icons.payments, 'Existing EMI', '₹${c.existingEmi.toStringAsFixed(0)}'),
        ]),
        const SizedBox(height: 12),
        _infoCard('KYC', [
          _row(Icons.badge, 'PAN', c.panNumber),
          _row(Icons.fingerprint, 'Aadhaar', c.aadhaarNumber),
          _row(Icons.person, 'Gender', c.gender),
          if (c.dob != null)
            _row(Icons.cake, 'DOB', '${c.dob!.day}/${c.dob!.month}/${c.dob!.year}'),
        ]),
        const SizedBox(height: 80),
      ],
    );
  }

  Widget _infoCard(String title, List<Widget> rows) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
          const SizedBox(height: 12),
          ...rows,
        ],
      ),
    );
  }

  Widget _row(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: 10),
          SizedBox(
            width: 100,
            child: Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}
