import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../models/loan_model.dart';
import '../../services/loan_service.dart';
import '../../widgets/common_widgets.dart';
import 'new_loan_screen.dart';
import 'loan_detail_screen.dart';

class LoansScreen extends StatefulWidget {
  const LoansScreen({super.key});

  @override
  State<LoansScreen> createState() => _LoansScreenState();
}

class _LoansScreenState extends State<LoansScreen> {
  final _service = LoanService();
  List<LoanApplicationModel> _apps = [];
  bool _loading = true;
  String? _error;
  String _filter = 'ALL';

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
      final list = await _service.getApplications();
      setState(() => _apps = list);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<LoanApplicationModel> get _filtered {
    if (_filter == 'ALL') return _apps;
    if (_filter == 'PENDING') return _apps.where((a) => a.isPending).toList();
    if (_filter == 'APPROVED') return _apps.where((a) => a.isApproved).toList();
    if (_filter == 'REJECTED') return _apps.where((a) => a.isRejected).toList();
    return _apps;
  }

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Loan Applications'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: _load),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final r = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const NewLoanScreen()),
          );
          if (r == true) _load();
        },
        icon: const Icon(Icons.add),
        label: const Text('New Loan'),
        backgroundColor: AppColors.primary,
      ),
      body: Column(
        children: [
          // Filters
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: ['ALL', 'PENDING', 'APPROVED', 'REJECTED'].map((f) {
                final selected = _filter == f;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(f),
                    selected: selected,
                    onSelected: (_) => setState(() => _filter = f),
                    selectedColor: AppColors.primarySoft,
                    labelStyle: TextStyle(
                      fontSize: 12,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                      color: selected ? AppColors.primaryDark : AppColors.textSecondary,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : _error != null
                    ? EmptyState(
                        icon: Icons.cloud_off,
                        title: 'Could not load applications',
                        subtitle: _error,
                        actionLabel: 'Retry',
                        onAction: _load,
                      )
                    : _filtered.isEmpty
                        ? EmptyState(
                            icon: Icons.description_outlined,
                            title: 'No applications',
                            subtitle: 'Create a new loan application for a customer',
                            actionLabel: 'New Loan',
                            onAction: () async {
                              final r = await Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const NewLoanScreen()),
                              );
                              if (r == true) _load();
                            },
                          )
                        : RefreshIndicator(
                            onRefresh: _load,
                            color: AppColors.primary,
                            child: ListView.separated(
                              padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                              itemCount: _filtered.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 10),
                              itemBuilder: (context, i) {
                                final app = _filtered[i];
                                return Material(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(16),
                                    onTap: () async {
                                      await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => LoanDetailScreen(applicationId: app.id),
                                        ),
                                      );
                                      _load();
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(14),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(color: AppColors.border),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  app.applicationNumber,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 14,
                                                  ),
                                                ),
                                              ),
                                              StatusChip(status: app.status),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            app.customerName ?? 'Customer',
                                            style: const TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w500,
                                              color: AppColors.textPrimary,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              Text(
                                                currency.format(app.requestedAmount),
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  color: AppColors.primary,
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Text(
                                                '${app.requestedTenureMonths} months',
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  color: AppColors.textSecondary,
                                                ),
                                              ),
                                              if (app.productName != null) ...[
                                                const SizedBox(width: 12),
                                                Flexible(
                                                  child: Text(
                                                    app.productName!,
                                                    style: const TextStyle(
                                                      fontSize: 12,
                                                      color: AppColors.textMuted,
                                                    ),
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}
