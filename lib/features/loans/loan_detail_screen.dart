import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../models/loan_model.dart';
import '../../services/loan_service.dart';
import '../../widgets/common_widgets.dart';

class LoanDetailScreen extends StatefulWidget {
  final String applicationId;
  const LoanDetailScreen({super.key, required this.applicationId});

  @override
  State<LoanDetailScreen> createState() => _LoanDetailScreenState();
}

class _LoanDetailScreenState extends State<LoanDetailScreen> {
  LoanApplicationModel? _app;
  bool _loading = true;
  bool _actionLoading = false;
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
      final app = await LoanService().getApplicationById(widget.applicationId);
      setState(() => _app = app);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _updateStatus(String status, {String? remarks}) async {
    setState(() => _actionLoading = true);
    try {
      await LoanService().updateStatus(widget.applicationId, status, remarks: remarks);
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Status updated to $status'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _actionLoading = false);
    }
  }

  Future<void> _showVerificationSheet() async {
    final remarksCtrl = TextEditingController();
    String verificationType = 'FIELD_VISIT';

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
            const Text('Field Verification', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 16),
            const Text('Verification Type', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
            const SizedBox(height: 6),
            StatefulBuilder(
              builder: (ctx, setS) {
                return Wrap(
                  spacing: 8,
                  children: ['KYC', 'EMPLOYMENT', 'INCOME', 'FIELD_VISIT'].map((t) {
                    final selected = verificationType == t;
                    return ChoiceChip(
                      label: Text(t.replaceAll('_', ' ')),
                      selected: selected,
                      onSelected: (_) => setS(() => verificationType = t),
                      selectedColor: AppColors.primarySoft,
                    );
                  }).toList(),
                );
              },
            ),
            const SizedBox(height: 14),
            TextField(
              controller: remarksCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Remarks',
                hintText: 'Field visit notes...',
              ),
            ),
            const SizedBox(height: 20),
            AppButton(
              label: 'Mark Verified',
              icon: Icons.verified_rounded,
              onPressed: () => Navigator.pop(ctx, true),
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
      await _updateStatus('VERIFICATION_COMPLETED', remarks: remarksCtrl.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Application Detail')),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _error != null || _app == null
              ? EmptyState(
                  icon: Icons.error_outline,
                  title: 'Could not load application',
                  subtitle: _error,
                  actionLabel: 'Retry',
                  onAction: _load,
                )
              : LoadingOverlay(
                  isLoading: _actionLoading,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Status header
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppColors.primary, AppColors.primaryDark],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Column(
                          children: [
                            Text(
                              _app!.applicationNumber,
                              style: const TextStyle(color: Colors.white70, fontSize: 13),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _currency.format(_app!.requestedAmount),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${_app!.requestedTenureMonths} months',
                              style: const TextStyle(color: Colors.white70, fontSize: 14),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                _app!.statusLabel,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      _infoRow('Customer', _app!.customerName ?? '-'),
                      _infoRow('Product', _app!.productName ?? '-'),
                      if (_app!.purpose != null) _infoRow('Purpose', _app!.purpose!),
                      if (_app!.createdAt != null)
                        _infoRow(
                          'Created',
                          DateFormat('dd MMM yyyy, hh:mm a').format(_app!.createdAt!),
                        ),
                      const SizedBox(height: 24),

                      // Actions for agent
                      if (_app!.isPending) ...[
                        const Text('Agent Actions', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                        const SizedBox(height: 12),
                        AppButton(
                          label: 'Complete Field Verification',
                          icon: Icons.fact_check_rounded,
                          onPressed: _showVerificationSheet,
                        ),
                        const SizedBox(height: 10),
                        AppButton(
                          label: 'Submit for Review',
                          icon: Icons.send_rounded,
                          isOutlined: true,
                          onPressed: () => _updateStatus('SUBMITTED'),
                        ),
                      ],
                    ],
                  ),
                ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}
