import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:finance_dashboard/features/transactions/business/transactions_provider.dart';
import 'package:finance_dashboard/features/categories/business/categories_provider.dart';
import 'package:finance_dashboard/features/dashboard/business/dashboard_provider.dart';
import 'package:finance_dashboard/core/theme/colors.dart';
import 'package:finance_dashboard/core/theme/spacing.dart';
import 'package:finance_dashboard/core/widgets/responsive_layout.dart';

/// Page for entering a new transaction, styled after the app's reference
/// design: borderless hero amount field, chip-wrap category picker with a
/// yellow selection accent, and a flat pill CTA.
class TransactionEntryPage extends StatefulWidget {
  const TransactionEntryPage({super.key});

  @override
  State<TransactionEntryPage> createState() => _TransactionEntryPageState();
}

class _TransactionEntryPageState extends State<TransactionEntryPage> {
  String? _selectedCategoryCode;
  final _amountController = TextEditingController();
  final _amountFocusNode = FocusNode();
  final _reasonController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  String? _amountError;
  String? _categoryError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CategoriesProvider>().load();
      _amountFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _amountFocusNode.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  bool get _isValid {
    final amount = double.tryParse(_amountController.text);
    return _selectedCategoryCode != null && amount != null && amount > 0;
  }

  IconData _iconForCategory(String codeOrName) {
    final key = codeOrName.toLowerCase();
    if (key.contains('food') || key.contains('restaurant') || key.contains('grocer')) {
      return Icons.restaurant_rounded;
    }
    if (key.contains('rent') || key.contains('home') || key.contains('house')) {
      return Icons.home_rounded;
    }
    if (key.contains('travel') || key.contains('flight') || key.contains('trip')) {
      return Icons.flight_takeoff_rounded;
    }
    if (key.contains('transport') || key.contains('cab') || key.contains('fuel') || key.contains('uber')) {
      return Icons.directions_car_filled_rounded;
    }
    if (key.contains('shop') || key.contains('cloth')) {
      return Icons.shopping_bag_rounded;
    }
    if (key.contains('health') || key.contains('medic') || key.contains('pharma')) {
      return Icons.local_hospital_rounded;
    }
    if (key.contains('entertain') || key.contains('movie') || key.contains('game')) {
      return Icons.movie_rounded;
    }
    if (key.contains('bill') || key.contains('utilit') || key.contains('electric')) {
      return Icons.receipt_long_rounded;
    }
    if (key.contains('subscription')) {
      return Icons.autorenew_rounded;
    }
    if (key.contains('education') || key.contains('school') || key.contains('course')) {
      return Icons.school_rounded;
    }
    return Icons.category_rounded;
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: highlightColor,
              surface: primaryColor,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  String _formattedDateLabel() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final picked = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
    if (picked == today) return 'Today';
    final yesterday = today.subtract(const Duration(days: 1));
    if (picked == yesterday) return 'Yesterday';
    return DateFormat('MMM d, yyyy').format(_selectedDate);
  }

  void _submitForm() async {
    final amount = double.tryParse(_amountController.text);
    setState(() {
      _amountError = (amount == null || amount <= 0) ? 'Enter a valid amount' : null;
      _categoryError = _selectedCategoryCode == null ? 'Select a category' : null;
    });
    if (!_isValid) return;

    try {
      await context.read<TransactionsProvider>().addTransaction(
            categoryCode: _selectedCategoryCode!,
            amount: amount!,
            reason: _reasonController.text.isEmpty ? null : _reasonController.text,
            date: _selectedDate,
          );
      // Budget/credit figures (spent, remaining, burn rate, balance) are
      // computed server-side, so a fresh dashboard load is needed here —
      // DashboardProvider only refreshes reactively via its own load(),
      // it doesn't observe its child providers' notifyListeners() calls.
      if (mounted) {
        await context.read<DashboardProvider>().load();
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Transaction added'),
            backgroundColor: highlightColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusInput)),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusInput)),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Add Transaction',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 17),
        ),
        centerTitle: true,
      ),
      body: Consumer2<CategoriesProvider, TransactionsProvider>(
        builder: (context, categoriesProvider, transactionsProvider, child) {
          final isDesktop = ResponsiveLayout.isDesktop(context);
          return SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: isDesktop ? 480 : double.infinity),
                child: Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        padding: EdgeInsets.symmetric(horizontal: isDesktop ? 0 : 20),
                        child: Column(
                          children: [
                            SizedBox(height: isDesktop ? 12 : 24),
                            _buildAmountField(),
                            if (_amountError != null) ...[
                              const SizedBox(height: 8),
                              Text(
                                _amountError!,
                                style: TextStyle(color: errorColor, fontSize: 13),
                              ),
                            ],
                            const SizedBox(height: 32),
                            _buildSectionLabel('Category'),
                            const SizedBox(height: 12),
                            _buildCategoryChips(categoriesProvider),
                            if (_categoryError != null) ...[
                              const SizedBox(height: 8),
                              Text(
                                _categoryError!,
                                style: TextStyle(color: errorColor, fontSize: 13),
                              ),
                            ],
                            const SizedBox(height: 28),
                            _buildSectionLabel('Details'),
                            const SizedBox(height: 12),
                            _buildDetailsCard(),
                            if (transactionsProvider.errorMessage != null) ...[
                              const SizedBox(height: 16),
                              _buildErrorBanner(transactionsProvider.errorMessage!),
                            ],
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),
                    _buildSubmitBar(transactionsProvider),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAmountField() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 10),
          child: Text(
            '₹',
            style: TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.w300,
            ),
          ),
        ),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 260),
          child: IntrinsicWidth(
            child: TextField(
              controller: _amountController,
              focusNode: _amountFocusNode,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
              ],
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.w400,
                height: 1.1,
              ),
              cursorColor: highlightColor,
              decoration: InputDecoration(
                hintText: '0.00',
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.25)),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
                isCollapsed: true,
              ),
              onChanged: (_) => setState(() => _amountError = null),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionLabel(String label) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          color: mutedTextColor,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _buildCategoryChips(CategoriesProvider categoriesProvider) {
    if (categoriesProvider.isLoading && categoriesProvider.categories.isEmpty) {
      return SizedBox(
        height: 44,
        child: Center(child: CircularProgressIndicator(color: highlightColor)),
      );
    }

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: categoriesProvider.categories.map((category) {
        final code = category['code'] as String;
        final name = category['display_name'] as String? ?? 'Unknown';
        final isSelected = _selectedCategoryCode == code;

        return GestureDetector(
          onTap: () => setState(() {
            _selectedCategoryCode = code;
            _categoryError = null;
          }),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: primaryColor,
              borderRadius: BorderRadius.circular(radiusChip),
              border: Border.all(
                color: isSelected ? highlightColor : Colors.transparent,
                width: 1.5,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _iconForCategory(name.isNotEmpty ? name : code),
                  color: isSelected ? highlightColor : Colors.white70,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  name,
                  style: TextStyle(
                    color: isSelected ? highlightColor : Colors.white70,
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDetailsCard() {
    return Container(
      decoration: BoxDecoration(
        color: primaryColor,
        borderRadius: BorderRadius.circular(radiusInput),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => _selectDate(context),
            borderRadius: BorderRadius.vertical(top: Radius.circular(radiusInput)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Row(
                children: [
                  Icon(Icons.calendar_today_rounded, color: mutedTextColor, size: 18),
                  const SizedBox(width: 12),
                  const Text('Date', style: TextStyle(color: Colors.white, fontSize: 15)),
                  const Spacer(),
                  Text(
                    _formattedDateLabel(),
                    style: TextStyle(color: mutedTextColor, fontSize: 15),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.chevron_right_rounded, color: mutedTextColor, size: 20),
                ],
              ),
            ),
          ),
          Divider(height: 1, color: borderColor.withOpacity(0.4)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(Icons.notes_rounded, color: mutedTextColor, size: 18),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _reasonController,
                    style: const TextStyle(color: Colors.white, fontSize: 15),
                    decoration: InputDecoration(
                      hintText: 'Add a note (optional)',
                      hintStyle: TextStyle(color: mutedTextColor),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    maxLines: 1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorBanner(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: errorColor.withOpacity(0.12),
        borderRadius: BorderRadius.circular(radiusInput),
        border: Border.all(color: errorColor.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded, color: errorColor, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(message, style: const TextStyle(color: Colors.white70, fontSize: 13)),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitBar(TransactionsProvider transactionsProvider) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      child: SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton(
          onPressed: transactionsProvider.isLoading ? null : _submitForm,
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            disabledBackgroundColor: primaryColor.withOpacity(0.6),
            foregroundColor: highlightColor,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusCard)),
          ),
          child: transactionsProvider.isLoading
              ? SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2.5, color: highlightColor),
                )
              : Text(
                  'Add Transaction',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: highlightColor),
                ),
        ),
      ),
    );
  }
}
