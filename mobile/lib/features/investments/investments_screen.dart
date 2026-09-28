import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:second_brain/core/theme/app_colors.dart';
import 'package:second_brain/core/theme/app_spacing.dart';
import 'package:second_brain/features/investments/data/investment_repository.dart';
import 'package:second_brain/features/investments/logic/investment_status.dart';
import 'package:second_brain/features/investments/models/investment.dart';
import 'package:second_brain/features/investments/add_investment_screen.dart';
import 'package:second_brain/features/investments/investment_detail_screen.dart';
import 'package:second_brain/features/investments/widgets/investment_filter.dart';
import 'package:second_brain/features/investments/widgets/investment_list.dart';
import 'package:second_brain/features/investments/widgets/investment_summary.dart';

/// Screen displaying the overview of investments, category filters, and list.
class InvestmentsScreen extends StatefulWidget {
  const InvestmentsScreen({super.key});

  @override
  State<InvestmentsScreen> createState() => _InvestmentsScreenState();
}

class _InvestmentsScreenState extends State<InvestmentsScreen> {
  InvestmentType? _selectedType; // null represents "All"
  InvestmentSummaryData? _serverSummary;
  bool _isLoadingBackend = false;

  @override
  void initState() {
    super.initState();
    InvestmentRepository.instance.addListener(_onDataChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadBackendData();
      }
    });
  }

  @override
  void dispose() {
    InvestmentRepository.instance.removeListener(_onDataChanged);
    super.dispose();
  }

  void _onDataChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _loadBackendData() async {
    if (!mounted) return;
    setState(() => _isLoadingBackend = true);

    try {
      await InvestmentRepository.instance.loadInvestments(
        type: _selectedType?.displayName,
      );

      final summary = await InvestmentRepository.instance.fetchSummary();

      if (mounted) {
        setState(() {
          _serverSummary = summary;
          _isLoadingBackend = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoadingBackend = false);
      }
    }
  }

  List<Investment> get _allInvestments =>
      InvestmentRepository.instance.getInvestments();

  List<Investment> get _filteredInvestments {
    if (_selectedType == null) {
      return _allInvestments;
    }
    return _allInvestments.where((i) => i.type == _selectedType).toList();
  }

  double get _totalInvested {
    if (_serverSummary != null && _selectedType == null) {
      return _serverSummary!.totalInvested;
    }
    return _allInvestments.fold(0.0, (sum, i) => sum + i.totalPaid);
  }

  int get _activeCount {
    if (_serverSummary != null && _selectedType == null) {
      return _serverSummary!.activeCount;
    }
    return _allInvestments.where((i) {
      final status = i.serverStatus != null
          ? InvestmentStatusExtension.fromString(i.serverStatus)
          : deriveStatus(
              installmentsPaid: i.installmentsPaid,
              totalInstallments: i.totalInstallments,
              nextDueDate: i.nextDueDate,
            );
      return status != InvestmentStatus.completed;
    }).length;
  }

  String _formatCurrency(double amount) {
    final formatter = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 0,
    );
    return formatter.format(amount);
  }

  Future<void> _onAddInvestmentPressed() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => const AddInvestmentScreen(),
      ),
    );
    if (result == true) {
      _loadBackendData();
    }
  }

  Future<void> _openInvestmentDetail(Investment investment) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => InvestmentDetailScreen(investmentId: investment.id),
      ),
    );
    if (result == true) {
      _loadBackendData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: _loadBackendData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppSpacing.space24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_isLoadingBackend)
                const Padding(
                  padding: EdgeInsets.only(bottom: AppSpacing.space12),
                  child: LinearProgressIndicator(minHeight: 2),
                ),

              // Compact summary card: Total Invested & Active count
              InvestmentSummary(
                totalInvested: _totalInvested,
                activeCount: _activeCount,
                formatAmount: _formatCurrency,
              ),
              const SizedBox(height: AppSpacing.space20),

              // Compact horizontal chip filter by category/type
              InvestmentFilter(
                selected: _selectedType,
                onChanged: (type) {
                  setState(() {
                    _selectedType = type;
                  });
                  _loadBackendData();
                },
              ),
              const SizedBox(height: AppSpacing.space20),

              // Investment List or Empty State
              InvestmentList(
                investments: _filteredInvestments,
                formatAmount: _formatCurrency,
                onAddInvestment: _onAddInvestmentPressed,
                onInvestmentTap: _openInvestmentDetail,
              ),
              const SizedBox(height: AppSpacing.space24),

              // Clear Add Investment action button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.darkBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                  ),
                  onPressed: _onAddInvestmentPressed,
                  icon: const Icon(Icons.add, size: 20),
                  label: const Text(
                    'Add Investment',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.space24),
            ],
          ),
        ),
      ),
    );
  }
}
