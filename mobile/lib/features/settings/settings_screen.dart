import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:second_brain/core/theme/app_colors.dart';
import 'package:second_brain/core/theme/app_radius.dart';
import 'package:second_brain/core/theme/app_spacing.dart';
import 'package:second_brain/core/theme/app_text_styles.dart';
import 'package:second_brain/features/documents/data/document_repository.dart';
import 'package:second_brain/features/expenses/data/expense_repository.dart';
import 'package:second_brain/features/investments/data/investment_repository.dart';
import 'package:second_brain/features/reminders/data/reminder_repository.dart';
import 'package:second_brain/features/settings/data/user_profile_repository.dart';
import 'package:second_brain/shared/widgets/app_card.dart';

/// Settings / Profile screen — lets the user personalise their name and view
/// a live snapshot of their vault across all modules.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _nameController = TextEditingController();
  bool _isEditingName = false;

  @override
  void initState() {
    super.initState();
    _nameController.text = UserProfileRepository.instance.name;
    UserProfileRepository.instance.addListener(_onProfileChanged);
  }

  @override
  void dispose() {
    _nameController.dispose();
    UserProfileRepository.instance.removeListener(_onProfileChanged);
    super.dispose();
  }

  void _onProfileChanged() {
    if (mounted) setState(() {});
  }

  void _saveName() {
    final value = _nameController.text.trim();
    if (value.isNotEmpty) {
      UserProfileRepository.instance.updateName(value);
    } else {
      _nameController.text = UserProfileRepository.instance.name;
    }
    setState(() => _isEditingName = false);
  }

  @override
  Widget build(BuildContext context) {
    final profile = UserProfileRepository.instance;
    final docs = DocumentRepository.instance.getDocuments();
    final expenses = ExpenseRepository.instance.getExpenses();
    final investments = InvestmentRepository.instance.getInvestments();
    final reminders = ReminderRepository.instance.getAll();

    final now = DateTime.now();
    final thisMonthExpenses = ExpenseRepository.instance
        .getTotalForMonth(now.year, now.month);
    final totalInvested = InvestmentRepository.instance.getTotalInvested();

    final currencyFmt = NumberFormat.currency(
        locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.space24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Profile Card ────────────────────────────────────────────────
            _buildProfileCard(profile),
            const SizedBox(height: AppSpacing.space24),

            // ── Vault Snapshot ───────────────────────────────────────────────
            _sectionLabel('Vault Snapshot'),
            const SizedBox(height: AppSpacing.space12),
            _buildSnapshotGrid(
              docs: docs.length,
              investments: investments.length,
              expenses: expenses.length,
              reminders:
                  reminders.where((r) => !r.isCompleted).length,
              thisMonth: currencyFmt.format(thisMonthExpenses),
              totalInvested: currencyFmt.format(totalInvested),
            ),
            const SizedBox(height: AppSpacing.space24),

            // ── Preferences ──────────────────────────────────────────────────
            _sectionLabel('Preferences'),
            const SizedBox(height: AppSpacing.space12),
            AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  _PreferenceTile(
                    icon: Icons.language_outlined,
                    label: 'Currency',
                    value: 'Indian Rupee (₹)',
                    onTap: () => _showInfoSnackBar(
                        context, 'Multi-currency support coming soon.'),
                  ),
                  const Divider(height: 1, indent: 56, color: AppColors.border),
                  _PreferenceTile(
                    icon: Icons.notifications_outlined,
                    label: 'Notifications',
                    value: 'Enabled',
                    onTap: () => _showInfoSnackBar(
                        context, 'Notification settings coming soon.'),
                  ),
                  const Divider(height: 1, indent: 56, color: AppColors.border),
                  _PreferenceTile(
                    icon: Icons.lock_outlined,
                    label: 'App Lock',
                    value: 'Coming soon',
                    onTap: () =>
                        _showInfoSnackBar(context, 'App lock coming soon.'),
                  ),
                  const Divider(height: 1, indent: 56, color: AppColors.border),
                  _PreferenceTile(
                    icon: Icons.cloud_outlined,
                    label: 'Cloud Backup',
                    value: 'Coming soon',
                    onTap: () =>
                        _showInfoSnackBar(context, 'Cloud backup coming soon.'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.space24),

            // ── About ────────────────────────────────────────────────────────
            _sectionLabel('About'),
            const SizedBox(height: AppSpacing.space12),
            AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  _PreferenceTile(
                    icon: Icons.info_outline,
                    label: 'Version',
                    value: '1.0.0 (beta)',
                    onTap: null,
                  ),
                  const Divider(height: 1, indent: 56, color: AppColors.border),
                  _PreferenceTile(
                    icon: Icons.privacy_tip_outlined,
                    label: 'Privacy Policy',
                    value: '',
                    onTap: () => _showInfoSnackBar(
                        context, 'Privacy policy coming soon.'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.space32),

            // ── Footer ───────────────────────────────────────────────────────
            Center(
              child: Text(
                'Second Brain · All data stored locally',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.mutedText,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.space8),
          ],
        ),
      ),
    );
  }

  // ── Profile card ──────────────────────────────────────────────────────────
  Widget _buildProfileCard(UserProfileRepository profile) {
    return AppCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Avatar
          Container(
            width: 60,
            height: 60,
            decoration: const BoxDecoration(
              color: AppColors.veryLightBlue,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                profile.name.isNotEmpty
                    ? profile.name[0].toUpperCase()
                    : 'U',
                style: AppTextStyles.screenTitle.copyWith(
                  color: AppColors.darkBlue,
                  fontSize: 26,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.space16),

          // Name + Greeting
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_isEditingName) ...[
                  TextField(
                    controller: _nameController,
                    autofocus: true,
                    textCapitalization: TextCapitalization.words,
                    style: AppTextStyles.cardTitle.copyWith(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.darkText,
                    ),
                    decoration: const InputDecoration(
                      isDense: true,
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 0, vertical: 4),
                      border: UnderlineInputBorder(),
                      focusedBorder: UnderlineInputBorder(
                        borderSide:
                            BorderSide(color: AppColors.primaryBrightBlue),
                      ),
                    ),
                    onSubmitted: (_) => _saveName(),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      GestureDetector(
                        onTap: _saveName,
                        child: Text(
                          'Save',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.primaryBrightBlue,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: () {
                          _nameController.text =
                              UserProfileRepository.instance.name;
                          setState(() => _isEditingName = false);
                        },
                        child: Text(
                          'Cancel',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.secondaryText,
                          ),
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  Text(
                    profile.name,
                    style: AppTextStyles.cardTitle.copyWith(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.darkText,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${profile.greeting} 👋',
                    style: AppTextStyles.secondary.copyWith(fontSize: 13),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.space8),

          // Edit button
          if (!_isEditingName)
            InkWell(
              onTap: () => setState(() => _isEditingName = true),
              borderRadius: AppRadius.smallBorderRadius,
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: Icon(
                  Icons.edit_outlined,
                  size: 20,
                  color: AppColors.secondaryText,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ── 2×3 snapshot grid ─────────────────────────────────────────────────────
  Widget _buildSnapshotGrid({
    required int docs,
    required int investments,
    required int expenses,
    required int reminders,
    required String thisMonth,
    required String totalInvested,
  }) {
    final items = [
      _SnapshotItem(
        label: 'Documents',
        value: docs.toString(),
        icon: Icons.folder_outlined,
        iconColor: AppColors.primaryBrightBlue,
        bgColor: AppColors.lightBlue,
      ),
      _SnapshotItem(
        label: 'Investments',
        value: investments.toString(),
        icon: Icons.trending_up,
        iconColor: AppColors.darkBlue,
        bgColor: AppColors.veryLightBlue,
      ),
      _SnapshotItem(
        label: 'Expenses',
        value: expenses.toString(),
        icon: Icons.receipt_long_outlined,
        iconColor: AppColors.warningOrange,
        bgColor: AppColors.lightOrange,
      ),
      _SnapshotItem(
        label: 'Active Reminders',
        value: reminders.toString(),
        icon: Icons.alarm_outlined,
        iconColor: AppColors.successGreen,
        bgColor: AppColors.lightGreen,
      ),
      _SnapshotItem(
        label: 'This Month',
        value: thisMonth,
        icon: Icons.account_balance_wallet_outlined,
        iconColor: AppColors.primaryBrightBlue,
        bgColor: AppColors.lightBlue,
      ),
      _SnapshotItem(
        label: 'Total Invested',
        value: totalInvested,
        icon: Icons.savings_outlined,
        iconColor: AppColors.darkBlue,
        bgColor: AppColors.veryLightBlue,
      ),
    ];

    return Column(
      children: [
        for (int i = 0; i < items.length; i += 2)
          Padding(
            padding: EdgeInsets.only(
                bottom: i + 2 < items.length ? AppSpacing.space12 : 0),
            child: Row(
              children: [
                Expanded(child: _buildSnapshotCard(items[i])),
                const SizedBox(width: AppSpacing.space12),
                Expanded(child: _buildSnapshotCard(items[i + 1])),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildSnapshotCard(_SnapshotItem item) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.space12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: item.bgColor,
              borderRadius: AppRadius.smallBorderRadius,
            ),
            child: Icon(item.icon, size: 18, color: item.iconColor),
          ),
          const SizedBox(width: AppSpacing.space12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.value,
                  style: AppTextStyles.cardTitle.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.darkText,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  item.label,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.secondaryText,
                    fontSize: 11,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String title) {
    return Text(
      title,
      style: AppTextStyles.sectionTitle,
    );
  }

  void _showInfoSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message,
            style: const TextStyle(color: AppColors.white)),
        backgroundColor: AppColors.darkBlue,
        behavior: SnackBarBehavior.fixed,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

// ── Supporting data classes ───────────────────────────────────────────────────

class _SnapshotItem {
  final String label;
  final String value;
  final IconData icon;
  final Color iconColor;
  final Color bgColor;

  const _SnapshotItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.iconColor,
    required this.bgColor,
  });
}

class _PreferenceTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onTap;

  const _PreferenceTile({
    required this.icon,
    required this.label,
    required this.value,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.space16,
          vertical: AppSpacing.space12,
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.veryLightBlue,
                borderRadius: AppRadius.smallBorderRadius,
              ),
              child: Icon(icon, size: 18, color: AppColors.darkBlue),
            ),
            const SizedBox(width: AppSpacing.space12),
            Expanded(
              child: Text(
                label,
                style: AppTextStyles.body.copyWith(
                  fontSize: 14,
                  color: AppColors.darkText,
                ),
              ),
            ),
            if (value.isNotEmpty) ...[
              Text(
                value,
                style: AppTextStyles.secondary.copyWith(fontSize: 13),
              ),
              const SizedBox(width: AppSpacing.space4),
            ],
            if (onTap != null)
              const Icon(Icons.chevron_right,
                  size: 18, color: AppColors.mutedText),
          ],
        ),
      ),
    );
  }
}
