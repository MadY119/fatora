import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
// 🌟 1. تم إضافة hide TextDirection لحل تداخل مكتبة intl مع فلاتر
import 'package:intl/intl.dart' hide TextDirection;
import 'package:fatora/core/constants/app_colors.dart';
import 'package:fatora/models/invoice_model.dart';
import 'package:fatora/services/invoice_storage_service.dart';
import 'package:fatora/views/invoice_form_screen.dart';
import 'package:fatora/views/invoice_preview_screen.dart';
import 'package:fatora/views/widgets/app_navigation.dart';

class InvoiceHistoryScreen extends StatefulWidget {
  const InvoiceHistoryScreen({super.key});

  @override
  State<InvoiceHistoryScreen> createState() => _InvoiceHistoryScreenState();
}

class _InvoiceHistoryScreenState extends State<InvoiceHistoryScreen> {
  List<InvoiceModel> _allInvoices = [];
  List<InvoiceModel> _filteredInvoices = [];
  bool _isLoading = true;
  
  String _selectedStatusFilter = 'الكل'; // 'الكل', 'مدفوعة', 'غير مدفوعة', 'متأخرة', 'مسودات'
  String _selectedPaymentMethod = 'الكل'; // 'الكل', 'CASH', 'VODAFONE_CASH', 'INSTAPAY', 'BANK_TRANSFER'
  final TextEditingController _searchController = TextEditingController();
  
  final Map<String, String> _paymentMethods = {
    'الكل': 'جميع طرق الدفع',
    'CASH': 'كاش',
    'VODAFONE_CASH': 'فودافون كاش',
    'INSTAPAY': 'انستا باي',
    'BANK_TRANSFER': 'تحويل بنكي',
  };

  @override
  void initState() {
    super.initState();
    _loadInvoices();
  }

  Future<void> _loadInvoices() async {
    setState(() => _isLoading = true);
    final data = await InvoiceStorageService.getInvoices();
    if (!mounted) return;
    setState(() {
      _allInvoices = data;
      _applyFilters();
      _isLoading = false;
    });
  }

  void _applyFilters() {
    String query = _searchController.text.trim().toLowerCase();
    _filteredInvoices = _allInvoices.where((inv) {
      bool matchesSearch = inv.clientName.toLowerCase().contains(query) || inv.invoiceNumber.toLowerCase().contains(query);
      
      bool matchesStatus = true;
      if (_selectedStatusFilter == 'مدفوعة') {
        matchesStatus = inv.paymentStatus == 'PAID';
      } else if (_selectedStatusFilter == 'غير مدفوعة') {
        matchesStatus = inv.paymentStatus == 'PENDING';
      } else if (_selectedStatusFilter == 'متأخرة') {
        matchesStatus = inv.paymentStatus == 'OVERDUE';
      } else if (_selectedStatusFilter == 'مسودات') {
        matchesStatus = inv.paymentStatus == 'DRAFT';
      }
      
      bool matchesPaymentMethod = _selectedPaymentMethod == 'الكل' || inv.paymentMethod == _selectedPaymentMethod;
      
      return matchesSearch && matchesStatus && matchesPaymentMethod;
    }).toList();
  }

  Future<void> _deleteInvoice(String invoiceNumber) async {
    await InvoiceStorageService.deleteInvoice(invoiceNumber);
    _loadInvoices();
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 1024;
    final dateFormat = DateFormat('dd MMMM yyyy');

    return Directionality(
      textDirection: TextDirection.rtl, // 🌟 الآن ستعمل بسلاسة تامة بدون أي خطأ
      child: Scaffold(
        backgroundColor: AppColors.background,
        
        // --- TopAppBar (Mobile) ---
        appBar: isDesktop ? null : AppBar(
          backgroundColor: AppColors.surface,
          elevation: 0,
          centerTitle: true,
          title: Text('FAWTARA | الفواتير', style: GoogleFonts.plusJakartaSans(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primary)),
          leading: IconButton(
            icon: const Icon(CupertinoIcons.bars, color: AppColors.textSecondary),
            onPressed: () => AppNavigation.showMenu(context, currentIndex: 1),
          ),
          bottom: PreferredSize(preferredSize: const Size.fromHeight(1), child: Container(color: AppColors.outline.withOpacity(0.3), height: 1)),
        ),

        // --- Bottom NavBar (Mobile) ---
        bottomNavigationBar: isDesktop ? null : AppNavigation.bottomNav(context: context, currentIndex: 1),

        // --- Floating Action Button (Mobile) ---
        floatingActionButton: isDesktop ? null : FloatingActionButton(
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const InvoiceFormScreen())),
          backgroundColor: AppColors.primary,
          child: const Icon(CupertinoIcons.add, color: Colors.white, size: 28),
        ),

        // --- Body Content ---
        body: Row(
          children: [
            // الجانب الأيمن شريط التنقل (Desktop SideNav)
            if (isDesktop) AppNavigation.desktopSideNav(context: context, currentIndex: 1),

            // منطقة المحتوى الرئيسية
            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadInvoices,
                color: AppColors.primary,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.symmetric(horizontal: isDesktop ? 40.0 : 16.0, vertical: 24.0),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1200),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // عنوان الشاشة وشريط البحث
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('الفواتير', style: GoogleFonts.plusJakartaSans(fontSize: isDesktop ? 32 : 26, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                                  const SizedBox(height: 4),
                                  Text('إدارة وتتبع جميع فواتيرك بذكاء.', style: GoogleFonts.plusJakartaSans(fontSize: 15, color: AppColors.textSecondary)),
                                ],
                              ),
                              // شريط البحث
                              SizedBox(
                                width: isDesktop ? 300 : 200,
                                child: TextField(
                                  controller: _searchController,
                                  onChanged: (_) => setState(() => _applyFilters()),
                                  style: GoogleFonts.plusJakartaSans(fontSize: 14),
                                  decoration: InputDecoration(
                                    hintText: 'البحث عن فاتورة...',
                                    hintStyle: GoogleFonts.plusJakartaSans(color: AppColors.textSecondary.withOpacity(0.6), fontSize: 13),
                                    prefixIcon: const Icon(CupertinoIcons.search, size: 18, color: AppColors.textSecondary),
                                    filled: true,
                                    fillColor: AppColors.surface,
                                    contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppColors.outline.withOpacity(0.4))),
                                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppColors.outline.withOpacity(0.4))),
                                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // أزرار الفلترة (Filter Chips) - حسب حالة الدفع
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                Text('حالة الدفع:', style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                                const SizedBox(width: 12),
                                ...['الكل', 'مدفوعة', 'غير مدفوعة', 'متأخرة', 'مسودات'].map((filter) {
                                  bool isSelected = _selectedStatusFilter == filter;
                                  return Padding(
                                    padding: const EdgeInsets.only(left: 8.0),
                                    child: ChoiceChip(
                                      label: Text(
                                        filter, 
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 13, 
                                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                          color: isSelected ? Colors.white : AppColors.textSecondary,
                                        ),
                                      ),
                                      selected: isSelected,
                                      onSelected: (selected) {
                                        if (selected) setState(() { _selectedStatusFilter = filter; _applyFilters(); });
                                      },
                                      selectedColor: AppColors.primary,
                                      backgroundColor: AppColors.surface,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: isSelected ? AppColors.primary : AppColors.outline.withOpacity(0.3))),
                                      showCheckmark: false,
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    ),
                                  );
                                }).toList(),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          
                          // أزرار الفلترة (Filter Chips) - حسب طريقة الدفع
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                Text('طريقة الدفع:', style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                                const SizedBox(width: 12),
                                ..._paymentMethods.keys.map((method) {
                                  bool isSelected = _selectedPaymentMethod == method;
                                  return Padding(
                                    padding: const EdgeInsets.only(left: 8.0),
                                    child: ChoiceChip(
                                      label: Text(
                                        _paymentMethods[method]!, 
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 13, 
                                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                          color: isSelected ? Colors.white : AppColors.textSecondary,
                                        ),
                                      ),
                                      selected: isSelected,
                                      onSelected: (selected) {
                                        if (selected) setState(() { _selectedPaymentMethod = method; _applyFilters(); });
                                      },
                                      selectedColor: AppColors.accent,
                                      backgroundColor: AppColors.surface,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: isSelected ? AppColors.accent : AppColors.outline.withOpacity(0.3))),
                                      showCheckmark: false,
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    ),
                                  );
                                }).toList(),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),

                          // قائمة الفواتير (Grid / List)
                          if (_isLoading)
                            const Center(child: Padding(padding: EdgeInsets.all(40.0), child: CircularProgressIndicator(color: AppColors.primary)))
                          else if (_filteredInvoices.isEmpty)
                            _buildEmptyState()
                          else
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _filteredInvoices.length,
                              itemBuilder: (context, index) {
                                final invoice = _filteredInvoices[index];
                                return _buildInvoiceCard(invoice, dateFormat);
                              },
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // كارت الفاتورة الفردي
  Widget _buildInvoiceCard(InvoiceModel invoice, DateFormat dateFormat) {
    Color badgeColor = AppColors.paidGreen;
    Color badgeBg = AppColors.paidGreenBg;
    String statusText = 'مدفوعة';

    if (invoice.paymentStatus == 'PENDING' || invoice.paymentStatus == 'OVERDUE') {
      badgeColor = AppColors.unpaidRed;
      badgeBg = AppColors.unpaidRedBg;
      statusText = 'غير مدفوعة';
    } else if (invoice.paymentStatus == 'DRAFT') {
      badgeColor = AppColors.draftGrey;
      badgeBg = AppColors.draftGreyBg;
      statusText = 'مسودة';
    }

    return Dismissible(
      key: Key(invoice.invoiceNumber),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 24),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(color: Colors.redAccent, borderRadius: BorderRadius.circular(12)),
        child: const Icon(CupertinoIcons.delete, color: Colors.white, size: 24),
      ),
      onDismissed: (_) => _deleteInvoice(invoice.invoiceNumber),
      child: GestureDetector(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => InvoicePreviewScreen(invoice: invoice))),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.outline.withOpacity(0.3)),
            boxShadow: [BoxShadow(color: const Color(0xFF0F172A).withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 4))],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // الأيقونة واسم العميل ورقم الفاتورة
              Row(
                children: [
                  Container(
                    width: 48, height: 48,
                    decoration: BoxDecoration(color: AppColors.primaryContainer.withOpacity(0.6), shape: BoxShape.circle),
                    child: const Icon(CupertinoIcons.doc_text_fill, color: AppColors.primary, size: 22),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('# ${invoice.invoiceNumber}', style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.outline)),
                      const SizedBox(height: 2),
                      Text(invoice.clientName.isEmpty ? 'عميل غير محدد' : invoice.clientName, style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                    ],
                  ),
                ],
              ),

              // الإجمالي والتاريخ والشارة
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('${invoice.grandTotal.toStringAsFixed(2)} ${invoice.currencySymbol}', style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text(dateFormat.format(invoice.date), style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.textSecondary)),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(color: badgeBg, borderRadius: BorderRadius.circular(20), border: Border.all(color: badgeColor.withOpacity(0.3))),
                        child: Text(statusText, style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.bold, color: badgeColor)),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(60.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(CupertinoIcons.doc_on_clipboard, size: 80, color: AppColors.outline.withOpacity(0.4)),
            const SizedBox(height: 16),
            Text('لا توجد فواتير مطابقة لبحثك', style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
            const SizedBox(height: 8),
            Text('اضغط على "إنشاء فاتورة" لإصدار أول فاتورة لعملائك.', style: GoogleFonts.plusJakartaSans(fontSize: 14, color: AppColors.outline)),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const InvoiceFormScreen())),
              icon: const Icon(CupertinoIcons.add, color: Colors.white, size: 18),
              label: Text('إنشاء فاتورة جديدة', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, color: Colors.white)),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            ),
          ],
        ),
      ),
    );
  }
}
