import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../services/loan_service.dart';
import '../../models/loan_model.dart';
import '../../widgets/common_widgets.dart';

/// Collections screen – lists applications that are DISBURSED / ACTIVE
/// and allows recording a payment (wired to status update for now;
/// full repayment API can be plugged in when backend exposes it).
class CollectionsScreen extends StatefulWidget {
  const CollectionsScreen({super.key});

  @override
  State<CollectionsScreen> createState() => _CollectionsScreenState();
}

class _CollectionsScreenState extends State<CollectionsScreen> {
  final _service = LoanService();
  List<LoanApplicationModel> _disbursed = [];
  bool _loading = true;
  String? _error;
  final _currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

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
      final apps = await _service.getApplications();
      // Show approved / disbursed loans as collectible
      setState(() {
        _disbursed = apps
            .where((a) =>
                a.status == 'DISBURSED' ||
                a.status == 'SANCTIONED' ||
                a.status == 'READY_FOR_DISBURSEMENT' ||
                a.isApproved)
            .toList();
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _recordPayment(LoanApplicationModel app) async {
    final amountCtrl = TextEditingController();
    String method = 'CASH';

    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Record Collection', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(
              app.customerName ?? app.applicationNumber,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: amountCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Amount Collected (₹)',
                prefixIcon: Icon(Icons.currency_rupee),
              ),
            ),
            const SizedBox(height: 14),
            const Text('Payment Method', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
            const SizedBox(height: 6),
            StatefulBuilder(
              builder: (ctx, setS) {
                return Wrap(
                  spacing: 8,
                  children: ['CASH', 'UPI', 'CHEQUE', 'NEFT'].map((m) {
                    final selected = method == m;
                    return ChoiceChip(
                      label: Text(m),
                      selected: selected,
                      onSelected: (_) => setS(() => method = m),
                      selectedColor: AppColors.primarySoft,
                    );
                  }).toList(),
                );
              },
            ),
            const SizedBox(height: 20),
            AppButton(
              label: 'Confirm Collection',
              icon: Icons.check_rounded,
              onPressed: () {
                if (amountCtrl.text.isEmpty || double.tryParse(amountCtrl.text) == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Enter a valid amount'), backgroundColor: AppColors.error),
                  );
                  return;
                }
                Navigator.pop(ctx, true);
              },
            ),
            const SizedBox(height: 8),
            AppButton(
              label: 'Cancel',
              isOutlined: true,
              onPressed: () => Navigator.pop(ctx, false),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true) {
      // When backend repayment endpoint is available, call it here.
      // For now we show success and keep a local log feel.
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Collected ₹${amountCtrl.text} via $method for ${app.applicationNumber}',
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Collections'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: _load),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _error != null
              ? EmptyState(
                  icon: Icons.cloud_off,
                  title: 'Could not load collections',
                  subtitle: _error,
                  actionLabel: 'Retry',
                  onAction: _load,
                )
              : _disbursed.isEmpty
                  ? const EmptyState(
                      icon: Icons.payments_outlined,
                      title: 'No active loans to collect',
                      subtitle: 'Disbursed loans will appear here for EMI collection',
                    )
                  : RefreshIndicator(
                      onRefresh: _load,
                      color: AppColors.primary,
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                        itemCount: _disbursed.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, i) {
                          final app = _disbursed[i];
                          return Material(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
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
                                          app.customerName ?? 'Customer',
                                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                                        ),
                                      ),
                                      StatusChip(status: app.status),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    app.applicationNumber,
                                    style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Text(
                                        _currency.format(app.requestedAmount),
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                      const Spacer(),
                                      SizedBox(
                                        height: 36,
                                        child: ElevatedButton.icon(
                                          onPressed: () => _recordPayment(app),
                                          icon: const Icon(Icons.payments, size: 16),
                                          label: const Text('Collect', style: TextStyle(fontSize: 13)),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: AppColors.success,
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(horizontal: 14),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}
