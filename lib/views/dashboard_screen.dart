import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fatora/core/constants/app_colors.dart';
import 'package:fatora/models/invoice_model.dart';
import 'package:fatora/services/invoice_storage_service.dart';
import 'package:fatora/views/invoice_form_screen.dart';
import 'package:fatora/views/invoice_history_screen.dart';
import 'package:fatora/views/invoice_preview_screen.dart';
import 'package:fatora/views/widgets/app_navigation.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<InvoiceModel> _invoices = [];
  bool _isLoading = true;
  String _currencySymbol = 'ر.س';

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);
    final data = await InvoiceStorageService.getInvoices();
    final prefs = await SharedPreferences.getInstance();
    
    if (!mounted) return;
    setState(() {
      _invoices = data;
      _currencySymbol = prefs.getString('default_currency') ?? 'ر.س';
      _isLoading = false;
    });
  }

  void _onWillPop() {
    _loadDashboardData();
  }

  // --- حسابات الإحصائيات الحية ---
  double get _totalRevenue => _invoices
      .where((inv) => inv.paymentStatus == 'PAID')
      .fold(0.0, (sum, inv) => sum + inv.grandTotal);

  double get _pendingAmount => _invoices
      .where((inv) => inv.paymentStatus == 'PENDING' || inv.paymentStatus == 'OVERDUE')
      .fold(0.0, (sum, inv) => sum + inv.grandTotal);

  int get _paidCount => _invoices.where((inv) => inv.paymentStatus == 'PAID').length;
  int get _unpaidCount => _invoices.where((inv) => inv.paymentStatus == 'PENDING' || inv.paymentStatus == 'OVERDUE').length;

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 1024;
    final dateFormat = DateFormat('dd MMMM yyyy');

    return Directionality(
      textDirection: TextDirection.rtl,
      child: PopScope(
        canPop: true,
        onPopInvoked: (_) => _onWillPop(),
        child: Scaffold(
          backgroundColor: AppColors.background,
          
          // --- Top AppBar ---
          appBar: isDesktop ? null : AppBar(
            backgroundColor: AppColors.surface,
            elevation: 0,
            centerTitle: true,
            title: Text('FAWTARA | لوحة التحكم', style: GoogleFonts.plusJakartaSans(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primary)),
            leading: IconButton(
              icon: const Icon(CupertinoIcons.bars, color: AppColors.textSecondary),
              onPressed: () => AppNavigation.showMenu(context, currentIndex: 0),
            ),
            actions: [
              IconButton(icon: const Icon(CupertinoIcons.refresh, color: AppColors.primary), onPressed: _loadDashboardData),
            ],
            bottom: PreferredSize(preferredSize: const Size.fromHeight(1), child: Container(color: AppColors.outline.withOpacity(0.3), height: 1)),
          ),

          // --- Bottom NavBar ---
          bottomNavigationBar: isDesktop ? null : AppNavigation.bottomNav(context: context, currentIndex: 0),

          // --- Floating Action Button ---
          floatingActionButton: isDesktop ? null : FloatingActionButton(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const InvoiceFormScreen())),
            backgroundColor: AppColors.primary,
            child: const Icon(CupertinoIcons.add, color: Colors.white, size: 28),
          ),

          body: Row(
          children: [
            if (isDesktop) AppNavigation.desktopSideNav(context: context, currentIndex: 0),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadDashboardData,
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
                          // العنوان الترحيبي
                          Text('مرحباً بك في فواتير 👋', style: GoogleFonts.plusJakartaSans(fontSize: isDesktop ? 32 : 26, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                          const SizedBox(height: 4),
                          Text('إليك ملخص سريع لأداء عملك والفواتير الصادرة.', style: GoogleFonts.plusJakartaSans(fontSize: 15, color: AppColors.textSecondary)),
                          const SizedBox(height: 24),

                          // --- كروت الإحصائيات (Stat Cards) ---
                          if (_isLoading)
                            const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator()))
                          else
                            Column(
                              children: [
                                Row(
                                  children: [
                                    Expanded(child: _buildStatCard('إجمالي الإيرادات (مدفوعة)', '${_totalRevenue.toStringAsFixed(2)} $_currencySymbol', CupertinoIcons.money_dollar_circle_fill, AppColors.paidGreen, '$_paidCount فاتورة')),
                                    const SizedBox(width: 16),
                                    Expanded(child: _buildStatCard('مبالغ معلقة (قيد الانتظار)', '${_pendingAmount.toStringAsFixed(2)} $_currencySymbol', CupertinoIcons.clock_fill, AppColors.unpaidRed, '$_unpaidCount فاتورة')),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Expanded(child: _buildActionCard('إصدار فاتورة جديدة', 'قم بإنشاء وإرسال فاتورة في ثوانٍ', CupertinoIcons.add_circled_solid, AppColors.primary, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const InvoiceFormScreen())))),
                                    const SizedBox(width: 16),
                                    Expanded(child: _buildActionCard('سجل الفواتير الكامل', 'عرض، فلترة، وتتبع جميع المعاملات', CupertinoIcons.doc_on_doc_fill, const Color(0xFF505F76), () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const InvoiceHistoryScreen())))),
                                  ],
                                ),
                              ],
                            ),

                          const SizedBox(height: 36),
                          
                          // --- أحدث الفواتير ---
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('أحدث الفواتير الصادرة', style: GoogleFonts.plusJakartaSans(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                              TextButton(
                                onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const InvoiceHistoryScreen())),
                                child: Text('عرض الكل ->', style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primary)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          if (_invoices.isEmpty)
                            _buildEmptyRecent()
                          else
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _invoices.length > 5 ? 5 : _invoices.length, // عرض أحدث 5 فقط
                              itemBuilder: (context, index) {
                                final invoice = _invoices[index];
                                return _buildRecentInvoiceRow(invoice, dateFormat);
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
      ),
    );
  }

  // ويدجت كارت الإحصائيات المالي
  Widget _buildStatCard(String title, String amount, IconData icon, Color color, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outline.withOpacity(0.3)),
        boxShadow: [BoxShadow(color: const Color(0xFF0F172A).withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle), child: Icon(icon, color: color, size: 24)),
              Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(12)), child: Text(subtitle, style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary))),
            ],
          ),
          const SizedBox(height: 16),
          Text(title, style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(amount, style: GoogleFonts.plusJakartaSans(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        ],
      ),
    );
  }

  // ويدجت كارت الإجراء السريع
  Widget _buildActionCard(String title, String desc, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: color.withOpacity(0.25), blurRadius: 15, offset: const Offset(0, 6))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Colors.white, size: 28),
            const SizedBox(height: 14),
            Text(title, style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 4),
            Text(desc, style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.white.withOpacity(0.8))),
          ],
        ),
      ),
    );
  }

  // سطر الفاتورة في الأحدث
  Widget _buildRecentInvoiceRow(InvoiceModel invoice, DateFormat dateFormat) {
    bool isPaid = invoice.paymentStatus == 'PAID';
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => InvoicePreviewScreen(invoice: invoice))),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.outline.withOpacity(0.2))),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                CircleAvatar(backgroundColor: AppColors.primaryContainer, child: const Icon(CupertinoIcons.doc_text_fill, color: AppColors.primary, size: 18)),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(invoice.clientName.isEmpty ? 'عميل غير محدد' : invoice.clientName, style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                    Text('#${invoice.invoiceNumber} • ${dateFormat.format(invoice.date)}', style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.textSecondary)),
                  ],
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('${invoice.grandTotal.toStringAsFixed(2)} ${invoice.currencySymbol}', style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: isPaid ? AppColors.paidGreenBg : AppColors.unpaidRedBg, borderRadius: BorderRadius.circular(10)),
                  child: Text(isPaid ? 'مدفوعة' : 'غير مدفوعة', style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.bold, color: isPaid ? AppColors.paidGreen : AppColors.unpaidRed)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyRecent() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.outline.withOpacity(0.2))),
      child: Column(
        children: [
          Icon(CupertinoIcons.chart_bar_alt_fill, size: 48, color: AppColors.outline.withOpacity(0.4)),
          const SizedBox(height: 12),
          Text('لا توجد إحصائيات بعد', style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
          const SizedBox(height: 4),
          Text('قم بإصدار أول فاتورة لتبدأ الأرقام بالظهور هنا.', style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppColors.outline)),
        ],
      ),
    );
  }
}
