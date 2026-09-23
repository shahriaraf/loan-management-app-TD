import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../models/customer_model.dart';
import '../../models/loan_model.dart';
import '../../services/customer_service.dart';
import '../../services/loan_service.dart';
import '../../widgets/common_widgets.dart';

class NewLoanScreen extends StatefulWidget {
  final CustomerModel? preselectedCustomer;
  const NewLoanScreen({super.key, this.preselectedCustomer});

  @override
  State<NewLoanScreen> createState() => _NewLoanScreenState();
}

class _NewLoanScreenState extends State<NewLoanScreen> {
  final _loanService = LoanService();
  final _customerService = CustomerService();
  final _currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

  int _step = 0;
  bool _loading = false;
  bool _dataLoading = true;

  List<CustomerModel> _customers = [];
  List<LoanProductModel> _products = [];
  List<LoanPurposeModel> _purposes = [];

  CustomerModel? _selectedCustomer;
  LoanProductModel? _selectedProduct;
  LoanPurposeModel? _selectedPurpose;

  final _amountCtrl = TextEditingController();
  final _tenureCtrl = TextEditingController();

  Map<String, dynamic>? _eligibility;
  double? _emi;

  @override
  void initState() {
    super.initState();
    _selectedCustomer = widget.preselectedCustomer;
    _loadData();
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _tenureCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _dataLoading = true);
    try {
      final results = await Future.wait([
        _customerService.getAll(),
        _loanService.getProducts(),
        _loanService.getPurposes(),
      ]);
      setState(() {
        _customers = results[0] as List<CustomerModel>;
        _products = results[1] as List<LoanProductModel>;
        _purposes = results[2] as List<LoanPurposeModel>;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load data: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _dataLoading = false);
    }
  }

  void _calcEligibility() {
    if (_selectedCustomer == null || _selectedProduct == null) return;
    final amount = double.tryParse(_amountCtrl.text) ?? 0;
    final tenure = int.tryParse(_tenureCtrl.text) ?? 0;
    if (amount <= 0 || tenure <= 0) return;

    final emi = _loanService.calculateEMI(amount, _selectedProduct!.interestRate, tenure);
    final elig = _loanService.evaluateEligibility(
      monthlyIncome: _selectedCustomer!.monthlyIncome,
      existingEmi: _selectedCustomer!.existingEmi,
      requestedEmi: emi,
    );
    setState(() {
      _emi = emi;
      _eligibility = elig;
    });
  }

  Future<void> _submit() async {
    if (_selectedCustomer == null || _selectedProduct == null) return;
    final amount = double.tryParse(_amountCtrl.text);
    final tenure = int.tryParse(_tenureCtrl.text);
    if (amount == null || tenure == null) return;

    setState(() => _loading = true);
    try {
      await _loanService.createApplication({
        'customerId': _selectedCustomer!.id,
        'productId': _selectedProduct!.id,
        'requestedAmount': amount,
        'requestedTenureMonths': tenure,
        if (_selectedPurpose != null) 'purpose': _selectedPurpose!.name,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Loan application submitted!'),
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
      appBar: AppBar(title: Text('New Loan · Step ${_step + 1}/3')),
      body: _dataLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : LoadingOverlay(
              isLoading: _loading,
              child: Column(
                children: [
                  LinearProgressIndicator(
                    value: (_step + 1) / 3,
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
                  Container(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -2)),
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
                              label: _step == 2 ? 'Submit Application' : 'Continue',
                              onPressed: _onNext,
                              icon: _step == 2 ? Icons.send_rounded : Icons.arrow_forward_rounded,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  void _onNext() {
    if (_step == 0) {
      if (_selectedCustomer == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Select a customer'), backgroundColor: AppColors.error),
        );
        return;
      }
      setState(() => _step = 1);
    } else if (_step == 1) {
      if (_selectedProduct == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Select a product'), backgroundColor: AppColors.error),
        );
        return;
      }
      final amount = double.tryParse(_amountCtrl.text) ?? 0;
      final tenure = int.tryParse(_tenureCtrl.text) ?? 0;
      if (amount < _selectedProduct!.minAmount || amount > _selectedProduct!.maxAmount) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Amount must be between ${_currency.format(_selectedProduct!.minAmount)} – ${_currency.format(_selectedProduct!.maxAmount)}',
            ),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }
      if (tenure < _selectedProduct!.minTenureMonths || tenure > _selectedProduct!.maxTenureMonths) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Tenure must be ${_selectedProduct!.minTenureMonths}–${_selectedProduct!.maxTenureMonths} months',
            ),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }
      _calcEligibility();
      setState(() => _step = 2);
    } else {
      _submit();
    }
  }

  Widget _buildStep() {
    switch (_step) {
      case 0:
        return _customerStep();
      case 1:
        return _productStep();
      case 2:
        return _reviewStep();
      default:
        return const SizedBox();
    }
  }

  Widget _customerStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Select Customer', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        const Text('Choose the customer for this loan application', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
        const SizedBox(height: 16),
        if (_customers.isEmpty)
          const EmptyState(icon: Icons.people_outline, title: 'No customers found', subtitle: 'Onboard a customer first')
        else
          ..._customers.map((c) {
            final selected = _selectedCustomer?.id == c.id;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Material(
                color: selected ? AppColors.primarySoft : Colors.white,
                borderRadius: BorderRadius.circular(14),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => setState(() => _selectedCustomer = c),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: selected ? AppColors.primary : AppColors.border, width: selected ? 1.5 : 1),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: selected ? AppColors.primary : AppColors.primarySoft,
                          child: Text(
                            c.initials,
                            style: TextStyle(
                              color: selected ? Colors.white : AppColors.primaryDark,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(c.fullName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                              Text(
                                '${c.phone} · Income ${_currency.format(c.monthlyIncome)}',
                                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                        if (selected) const Icon(Icons.check_circle, color: AppColors.primary),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
      ],
    );
  }

  Widget _productStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Loan Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        const SizedBox(height: 16),
        const Text('Product *', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textSecondary)),
        const SizedBox(height: 6),
        ..._products.map((p) {
          final selected = _selectedProduct?.id == p.id;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Material(
              color: selected ? AppColors.primarySoft : Colors.white,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  setState(() {
                    _selectedProduct = p;
                    _amountCtrl.text = p.minAmount.toStringAsFixed(0);
                    _tenureCtrl.text = p.minTenureMonths.toString();
                  });
                },
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: selected ? AppColors.primary : AppColors.border),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(p.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                            Text(
                              '${_currency.format(p.minAmount)}–${_currency.format(p.maxAmount)} · ${p.interestRate}% p.a.',
                              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      if (selected) const Icon(Icons.check_circle, color: AppColors.primary, size: 20),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
        const SizedBox(height: 16),
        AppTextField(
          controller: _amountCtrl,
          label: 'Requested Amount (₹) *',
          hint: '50000',
          prefixIcon: Icons.currency_rupee,
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 14),
        AppTextField(
          controller: _tenureCtrl,
          label: 'Tenure (months) *',
          hint: '12',
          prefixIcon: Icons.calendar_month,
          keyboardType: TextInputType.number,
        ),
        if (_purposes.isNotEmpty) ...[
          const SizedBox(height: 14),
          const Text('Purpose', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textSecondary)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _purposes.map((p) {
              final selected = _selectedPurpose?.id == p.id;
              return ChoiceChip(
                label: Text(p.name),
                selected: selected,
                onSelected: (_) => setState(() => _selectedPurpose = p),
                selectedColor: AppColors.primarySoft,
                labelStyle: TextStyle(
                  fontSize: 12,
                  color: selected ? AppColors.primaryDark : AppColors.textSecondary,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                ),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  Widget _reviewStep() {
    final eligible = _eligibility?['eligible'] == true;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Review & Submit', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        const SizedBox(height: 16),
        _reviewCard('Customer', _selectedCustomer?.fullName ?? '-'),
        _reviewCard('Product', _selectedProduct?.name ?? '-'),
        _reviewCard('Amount', _currency.format(double.tryParse(_amountCtrl.text) ?? 0)),
        _reviewCard('Tenure', '${_tenureCtrl.text} months'),
        if (_selectedPurpose != null) _reviewCard('Purpose', _selectedPurpose!.name),
        if (_emi != null) _reviewCard('Est. EMI', _currency.format(_emi)),
        const SizedBox(height: 16),
        // Eligibility card
        if (_eligibility != null)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: eligible ? AppColors.success.withOpacity(0.08) : AppColors.error.withOpacity(0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: eligible ? AppColors.success.withOpacity(0.3) : AppColors.error.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(
                  eligible ? Icons.check_circle : Icons.warning_rounded,
                  color: eligible ? AppColors.success : AppColors.error,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        eligible ? 'Eligible' : 'High FOIR – Review Needed',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: eligible ? AppColors.success : AppColors.error,
                        ),
                      ),
                      Text(
                        'FOIR: ${_eligibility!['foir']}% (threshold 50%)',
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _reviewCard(String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
