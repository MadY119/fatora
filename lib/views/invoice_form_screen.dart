import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fatora/core/constants/app_colors.dart';
import 'package:fatora/models/invoice_model.dart';
import 'package:fatora/models/client_model.dart';
import 'package:fatora/services/client_storage_service.dart';
import 'package:fatora/services/invoice_storage_service.dart';
import 'package:fatora/views/invoice_history_screen.dart';
import 'package:fatora/views/invoice_preview_screen.dart';
import 'package:fatora/views/widgets/app_navigation.dart';

class ItemController {
  final TextEditingController description = TextEditingController();
  final TextEditingController price = TextEditingController();
  final TextEditingController quantity = TextEditingController(text: '1');

  void dispose() {
    description.dispose();
    price.dispose();
    quantity.dispose();
  }
}

class InvoiceFormScreen extends StatefulWidget {
  final ClientModel? initialClient;

  const InvoiceFormScreen({super.key, this.initialClient});

  @override
  State<InvoiceFormScreen> createState() => _InvoiceFormScreenState();
}

class _InvoiceFormScreenState extends State<InvoiceFormScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _invoiceNumController = TextEditingController(text: 'INV-2026-001');
  final TextEditingController _clientNameController = TextEditingController();
  final TextEditingController _clientEmailController = TextEditingController();
  final TextEditingController _clientPhoneController = TextEditingController();
  final TextEditingController _discountController = TextEditingController(text: '0.00');
  final TextEditingController _taxRateController = TextEditingController(text: '15'); // 15% حسب الديزاين
  final TextEditingController _paymentInstructionsController = TextEditingController();

  final List<ItemController> _itemControllers = [ItemController()];
  
  String _selectedCurrency = 'ر.س';
  String _selectedPaymentMethod = 'CASH';
  String _selectedPaymentStatus = 'PENDING';
  final Map<String, String> _currencies = {
    'ر.س': 'ريال سعودي (SAR)',
    '\$': 'دولار أمريكي (USD)',
    '€': 'يورو (EUR)',
    'EGP': 'جنيه مصري (EGP)',
  };
  final Map<String, String> _paymentMethods = {
    'CASH': 'كاش',
    'VODAFONE_CASH': 'فودافون كاش',
    'INSTAPAY': 'انستا باي',
    'BANK_TRANSFER': 'تحويل بنكي',
  };
  final Map<String, String> _paymentStatuses = {
    'PENDING': 'غير مدفوعة',
    'PAID': 'مدفوعة',
    'OVERDUE': 'متأخرة',
  };
  
  Uint8List? _logoBytes;

  @override
  void initState() {
    super.initState();
    _applyInitialClient();
    _loadFormDefaults();
  }

  void _applyInitialClient() {
    final client = widget.initialClient;
    if (client == null) return;
    _clientNameController.text = client.name;
    _clientEmailController.text = client.email;
    _clientPhoneController.text = client.phone;
  }

  @override
  void dispose() {
    _invoiceNumController.dispose();
    _clientNameController.dispose();
    _clientEmailController.dispose();
    _clientPhoneController.dispose();
    _discountController.dispose();
    _taxRateController.dispose();
    _paymentInstructionsController.dispose();
    for (var controller in _itemControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  // --- حسابات المال الفورية (Live Calculations) ---
  double get _subTotal {
    double total = 0;
    for (var item in _itemControllers) {
      double p = double.tryParse(item.price.text.trim()) ?? 0.0;
      int q = int.tryParse(item.quantity.text.trim()) ?? 1;
      total += (p * q);
    }
    return total;
  }

  double get _discountAmount => double.tryParse(_discountController.text.trim()) ?? 0.0;
  double get _taxableAmount => (_subTotal - _discountAmount) > 0 ? (_subTotal - _discountAmount) : 0.0;
  double get _taxPercent => double.tryParse(_taxRateController.text.trim()) ?? 15.0;
  double get _taxAmount => _taxableAmount * (_taxPercent / 100.0);
  double get _grandTotal => _taxableAmount + _taxAmount;

  void _addItem() {
    setState(() => _itemControllers.add(ItemController()));
  }

  void _removeItem(int index) {
    if (_itemControllers.length > 1) {
      setState(() {
        _itemControllers[index].dispose();
        _itemControllers.removeAt(index);
      });
    }
  }

  Future<void> _loadFormDefaults() async {
    final prefs = await SharedPreferences.getInstance();
    final invoices = await InvoiceStorageService.getInvoices();
    final logoBase64 = prefs.getString('company_logo');

    if (!mounted) return;

    setState(() {
      final defaultCurrency = prefs.getString('default_currency');
      if (defaultCurrency != null && _currencies.containsKey(defaultCurrency)) {
        _selectedCurrency = defaultCurrency;
      }
      _taxRateController.text = prefs.getString('default_tax') ?? _taxRateController.text;
      _paymentInstructionsController.text = prefs.getString('default_instructions') ?? '';
      _selectedPaymentMethod = prefs.getString('default_payment_method') ?? _selectedPaymentMethod;
      _invoiceNumController.text = _nextInvoiceNumber(invoices);
      if (logoBase64 != null) {
        try {
          _logoBytes = base64Decode(logoBase64);
        } catch (e) {
          _logoBytes = null;
        }
      }
    });
  }

  String _nextInvoiceNumber(List<InvoiceModel> invoices) {
    final year = DateTime.now().year;
    final prefix = 'INV-$year-';
    var maxNumber = 0;

    for (final invoice in invoices) {
      if (!invoice.invoiceNumber.startsWith(prefix)) continue;
      final suffix = invoice.invoiceNumber.substring(prefix.length);
      final number = int.tryParse(suffix);
      if (number != null && number > maxNumber) {
        maxNumber = number;
      }
    }

    return '$prefix${(maxNumber + 1).toString().padLeft(3, '0')}';
  }

  List<InvoiceItemModel> _buildItems({required bool includeEmptyDraftItem}) {
    final items = _itemControllers
        .where((itemCtrl) =>
            itemCtrl.description.text.trim().isNotEmpty ||
            itemCtrl.price.text.trim().isNotEmpty)
        .map((itemCtrl) {
      return InvoiceItemModel(
        description: itemCtrl.description.text.trim(),
        unitPrice: double.tryParse(itemCtrl.price.text.trim()) ?? 0.0,
        quantity: int.tryParse(itemCtrl.quantity.text.trim()) ?? 1,
      );
    }).toList();

    if (items.isEmpty && includeEmptyDraftItem) {
      return [
        InvoiceItemModel(
          description: 'مسودة بدون عناصر',
          unitPrice: 0,
          quantity: 1,
        ),
      ];
    }

    return items;
  }

  InvoiceModel _buildInvoice({required String paymentStatus}) {
    return InvoiceModel(
      invoiceNumber: _invoiceNumController.text.trim(),
      clientName: _clientNameController.text.trim(),
      clientEmail: _clientEmailController.text.trim(),
      clientPhone: _clientPhoneController.text.trim(),
      date: DateTime.now(),
      items: _buildItems(includeEmptyDraftItem: paymentStatus == 'DRAFT'),
      taxRate: _taxPercent / 100.0,
      discountAmount: _discountAmount,
      currencySymbol: _selectedCurrency,
      logoBytes: _logoBytes,
      paymentStatus: paymentStatus,
      paymentMethod: _selectedPaymentMethod,
      paymentInstructions: _paymentInstructionsController.text.trim(),
    );
  }

  Future<void> _saveCurrentClient() async {
    await ClientStorageService.saveClient(
      ClientModel(
        name: _clientNameController.text,
        email: _clientEmailController.text,
        phone: _clientPhoneController.text,
      ),
    );
  }

  Future<void> _generateAndPreviewInvoice() async {
    if (_formKey.currentState!.validate()) {
      final invoice = _buildInvoice(paymentStatus: _selectedPaymentStatus);
      await InvoiceStorageService.saveInvoice(invoice);
      await _saveCurrentClient();

      if (mounted) {
        // عرض SnackBar للتأكيد مع حالة الفاتورة
        String statusText = '';
        if (_selectedPaymentStatus == 'PAID') {
          statusText = 'تم حفظ الفاتورة كمدفوعة ✓';
        } else if (_selectedPaymentStatus == 'PENDING') {
          statusText = 'تم حفظ الفاتورة (غير مدفوعة)';
        } else if (_selectedPaymentStatus == 'OVERDUE') {
          statusText = 'تم حفظ الفاتورة (متأخرة)';
        } else {
          statusText = 'تم حفظ الفاتورة كمسودة';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(CupertinoIcons.checkmark_alt_circle_fill, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    statusText,
                    style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            backgroundColor: _selectedPaymentStatus == 'PAID' ? AppColors.paidGreen : AppColors.primary,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
        
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => InvoicePreviewScreen(invoice: invoice)),
        );
      }
    }
  }

  Future<void> _saveDraftInvoice() async {
    final invoice = _buildInvoice(paymentStatus: 'DRAFT');
    await InvoiceStorageService.saveInvoice(invoice);
    await _saveCurrentClient();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم حفظ المسودة بنجاح', style: GoogleFonts.plusJakartaSans()),
          backgroundColor: AppColors.textPrimary,
        ),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const InvoiceHistoryScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // تحديد هل الشاشة كبيرة (Desktop/Tablet) أم موبايل
    final isDesktop = MediaQuery.of(context).size.width >= 1024;

    return Directionality(
      textDirection: TextDirection.rtl, // 🌟 واجهة عربية من اليمين لليسار حسب الـ HTML
      child: Scaffold(
        backgroundColor: AppColors.background,
        
        // --- Top AppBar (Mobile Style) ---
        appBar: isDesktop ? null : AppBar(
          backgroundColor: AppColors.surface,
          elevation: 0,
          centerTitle: true,
          title: Text(
            'FAWTARA',
            style: GoogleFonts.plusJakartaSans(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primary, letterSpacing: -0.5),
          ),
          leading: IconButton(
            icon: const Icon(CupertinoIcons.bars, color: AppColors.textSecondary),
            onPressed: () => AppNavigation.showMenu(context, currentIndex: 2),
          ),
          actions: [
            IconButton(
              icon: const Icon(CupertinoIcons.folder_solid, color: AppColors.textSecondary),
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const InvoiceHistoryScreen())),
            ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(color: AppColors.outline, height: 1),
          ),
        ),

        // --- Bottom Nav Bar (Mobile Style) ---
        bottomNavigationBar: isDesktop ? null : AppNavigation.bottomNav(context: context, currentIndex: 2),

        // --- Main Content Canvas (Responsive 12-Column Grid) ---
        body: Row(
          children: [
            if (isDesktop) AppNavigation.desktopSideNav(context: context, currentIndex: 2),
            Expanded(
              child: Form(
                key: _formKey,
                onChanged: () => setState(() {}), // 🌟 تحديث فوري للأرقام في الملخص عند الكتابة
                child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: isDesktop ? 40.0 : 16.0,
              vertical: 24.0,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1280), // container-max
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // العنوان الرئيسي والفرعي
                    Text(
                      'إنشاء فاتورة جديدة',
                      style: GoogleFonts.plusJakartaSans(fontSize: isDesktop ? 32 : 26, fontWeight: FontWeight.bold, color: AppColors.textPrimary, letterSpacing: -0.5),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'يرجى ملء التفاصيل أدناه لإصدار الفاتورة.',
                      style: GoogleFonts.plusJakartaSans(fontSize: 16, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 28),

                    // 🌟 هندسة الشبكة (8 أعمدة للفورم + 4 أعمدة للملخص)
                    if (isDesktop)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 8, child: _buildLeftColumnForm()),
                          const SizedBox(width: 32),
                          Expanded(flex: 4, child: _buildRightColumnSummary()),
                        ],
                      )
                    else
                      Column(
                        children: [
                          _buildLeftColumnForm(),
                          const SizedBox(height: 24),
                          _buildRightColumnSummary(),
                        ],
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

  // ==========================================
  // 📦 العمود الأول (بيانات الفاتورة والأصناف)
  // ==========================================
  Widget _buildLeftColumnForm() {
    return Column(
      children: [
        // 1. كارت بيانات الفاتورة والعميل
        _buildCardContainer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('بيانات الفاتورة والعميل', CupertinoIcons.person_fill),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildInputField(
                      label: 'رقم الفاتورة',
                      controller: _invoiceNumController,
                      readOnly: true,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('العملة', style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.outline),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _selectedCurrency,
                              isExpanded: true,
                              icon: const Icon(CupertinoIcons.chevron_down, size: 16, color: AppColors.textSecondary),
                              style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textPrimary),
                              items: _currencies.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
                              onChanged: (val) => setState(() => _selectedCurrency = val!),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Divider(color: AppColors.outline, thickness: 1),
              const SizedBox(height: 16),
              Text('تفاصيل العميل', style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
              const SizedBox(height: 16),
              _buildInputField(label: 'اسم العميل', controller: _clientNameController, hint: 'أدخل اسم العميل', isRequired: true),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _buildInputField(label: 'البريد الإلكتروني', controller: _clientEmailController, hint: 'client@example.com', keyboardType: TextInputType.emailAddress)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildInputField(label: 'رقم الهاتف', controller: _clientPhoneController, hint: '+966 5X XXX XXXX', keyboardType: TextInputType.phone)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // 2. كارت عناصر الفاتورة
        _buildCardContainer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('عناصر الفاتورة', CupertinoIcons.list_bullet_below_rectangle),
              const SizedBox(height: 16),
              
              // قائمة الأصناف
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _itemControllers.length,
                itemBuilder: (context, index) {
                  final item = _itemControllers[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.background, // surface-container-low
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.outline.withOpacity(0.6)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          flex: 5,
                          child: TextFormField(
                            controller: item.description,
                            style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w500, color: AppColors.textPrimary),
                            validator: (value) => value == null || value.trim().isEmpty ? 'أدخل الوصف' : null,
                            decoration: InputDecoration(
                              hintText: 'وصف العنصر أو الخدمة...',
                              hintStyle: GoogleFonts.plusJakartaSans(color: AppColors.textSecondary.withOpacity(0.7)),
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                        Container(width: 1, height: 30, color: AppColors.outline, margin: const EdgeInsets.symmetric(horizontal: 12)),
                        SizedBox(
                          width: 70,
                          child: TextFormField(
                            controller: item.quantity,
                            textAlign: TextAlign.center,
                            keyboardType: TextInputType.number,
                            style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                            validator: (value) {
                              final quantity = int.tryParse(value?.trim() ?? '');
                              return quantity == null || quantity <= 0 ? 'كمية غير صحيحة' : null;
                            },
                            decoration: const InputDecoration(border: InputBorder.none, hintText: 'الكمية'),
                          ),
                        ),
                        Container(width: 1, height: 30, color: AppColors.outline, margin: const EdgeInsets.symmetric(horizontal: 12)),
                        SizedBox(
                          width: 100,
                          child: TextFormField(
                            controller: item.price,
                            textAlign: TextAlign.left,
                            textDirection: TextDirection.ltr,
                            keyboardType: TextInputType.number,
                            style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.primary),
                            validator: (value) {
                              final price = double.tryParse(value?.trim() ?? '');
                              return price == null || price <= 0 ? 'سعر غير صحيح' : null;
                            },
                            decoration: InputDecoration(border: InputBorder.none, hintText: '0.00 $_selectedCurrency'),
                          ),
                        ),
                        if (_itemControllers.length > 1) ...[
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(CupertinoIcons.delete, color: Colors.redAccent, size: 20),
                            onPressed: () => _removeItem(index),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),

              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: _addItem,
                icon: const Icon(CupertinoIcons.add, size: 18, color: AppColors.primary),
                label: Text('إضافة عنصر جديد', style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primary)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // 3. كارت تعليمات الدفع
        _buildCardContainer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('تعليمات الدفع', CupertinoIcons.creditcard_fill),
              const SizedBox(height: 12),
              _buildInputField(
                label: 'ملاحظات أو تفاصيل بنكية',
                controller: _paymentInstructionsController,
                hint: 'أدخل تفاصيل الحساب البنكي، أو أي تعليمات خاصة بالدفع...',
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('طريقة الدفع', style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: _showPaymentMethodDialog,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.outline),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _paymentMethods[_selectedPaymentMethod] ?? 'اختر الطريقة',
                                  style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textPrimary),
                                ),
                                const Icon(CupertinoIcons.chevron_down, size: 16, color: AppColors.textSecondary),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildDropdownField(
                      label: 'حالة الفاتورة',
                      value: _selectedPaymentStatus,
                      items: _paymentStatuses,
                      onChanged: (value) => setState(() => _selectedPaymentStatus = value),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ==========================================
  // 📊 العمود الثاني (الملخص والأزرار - Sticky)
  // ==========================================
  Widget _buildRightColumnSummary() {
    return _buildCardContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('الملخص المالي', CupertinoIcons.chart_pie_fill),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildInputField(label: 'الخصم ($_selectedCurrency)', controller: _discountController, hint: '0.00', keyboardType: TextInputType.number)),
              const SizedBox(width: 16),
              Expanded(child: _buildInputField(label: 'الضريبة (%)', controller: _taxRateController, hint: '15', keyboardType: TextInputType.number)),
            ],
          ),
          const SizedBox(height: 24),
          const Divider(color: AppColors.outline, thickness: 1),
          const SizedBox(height: 16),

          // الأرقام المالية الحية
          _buildSummaryRow('المجموع الفرعي', '${_subTotal.toStringAsFixed(2)} $_selectedCurrency'),
          if (_discountAmount > 0)
            _buildSummaryRow('الخصم', '- ${_discountAmount.toStringAsFixed(2)} $_selectedCurrency', color: Colors.redAccent),
          _buildSummaryRow('الضريبة (${_taxPercent.toInt()}%)', '${_taxAmount.toStringAsFixed(2)} $_selectedCurrency'),
          const SizedBox(height: 12),
          const Divider(color: AppColors.outline, thickness: 1),
          const SizedBox(height: 12),
          
          // الإجمالي الكلي
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('الإجمالي الكلي', style: GoogleFonts.plusJakartaSans(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              Text('${_grandTotal.toStringAsFixed(2)} $_selectedCurrency', style: GoogleFonts.plusJakartaSans(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primary)),
            ],
          ),
          const SizedBox(height: 32),

          // زرار إصدار الفاتورة (بالظل الفخم shadow-[0_10px_30px_rgba(49,111,246,0.15)])
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(color: AppColors.primary.withOpacity(0.2), blurRadius: 25, offset: const Offset(0, 10)),
              ],
            ),
            child: ElevatedButton.icon(
              onPressed: _generateAndPreviewInvoice,
              icon: const Icon(CupertinoIcons.paperplane_fill, size: 18, color: Colors.white),
              label: Text('إصدار الفاتورة', style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), // rounded-lg
                elevation: 0,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // زرار حفظ كمسودة (surface-container)
          SizedBox(
            width: double.infinity,
            child: TextButton.icon(
              onPressed: _saveDraftInvoice,
              icon: const Icon(CupertinoIcons.floppy_disk, size: 18, color: AppColors.textPrimary),
              label: Text('حفظ كمسودة', style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
              style: TextButton.styleFrom(
                backgroundColor: const Color(0xFFEAEDFF), // surface-container
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // 🛠️ الويدجت والمساعدين (Helper Widgets)
  // ==========================================

  // كارت الحاويات الأبيض (.card-container)
  Widget _buildCardContainer({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16), // rounded-xl
        border: Border.all(color: AppColors.outline, width: 1),
      ),
      child: child,
    );
  }

  // عنوان السكشن مع الأيقونة الزرقاء في مربع Tinted (.section-title)
  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primaryContainer, // bg-surface-container-low
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppColors.primary, size: 20),
        ),
        const SizedBox(width: 12),
        Text(title, style: GoogleFonts.plusJakartaSans(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
      ],
    );
  }

  // سطر الأرقام في الملخص
  Widget _buildSummaryRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 15, color: AppColors.textSecondary)),
          Text(value, style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w600, color: color ?? AppColors.textPrimary)),
        ],
      ),
    );
  }

  // حقول الإدخال (.input-field)
  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    String? hint,
    TextInputType keyboardType = TextInputType.text,
    bool isRequired = false,
    bool readOnly = false,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          readOnly: readOnly,
          maxLines: maxLines,
          keyboardType: keyboardType,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 15,
            fontWeight: readOnly ? FontWeight.bold : FontWeight.w500,
            color: readOnly ? AppColors.textSecondary : AppColors.textPrimary,
          ),
          validator: (val) => isRequired && (val == null || val.isEmpty) ? 'هذا الحقل مطلوب' : null,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.plusJakartaSans(color: AppColors.textSecondary.withOpacity(0.5)),
            filled: true,
            fillColor: readOnly ? AppColors.background : AppColors.surface,
            contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.outline, width: 1)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.outline, width: 1)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String value,
    required Map<String, String> items,
    required ValueChanged<String> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.outline),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              icon: const Icon(CupertinoIcons.chevron_down, size: 16, color: AppColors.textSecondary),
              style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textPrimary),
              items: items.entries.map((entry) => DropdownMenuItem(value: entry.key, child: Text(entry.value))).toList(),
              onChanged: (selected) {
                if (selected != null) onChanged(selected);
              },
            ),
          ),
        ),
      ],
    );
  }

  void _showPaymentMethodDialog() {
    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: Text('اختر طريقة الدفع', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: _paymentMethods.entries.map((entry) {
                bool isSelected = _selectedPaymentMethod == entry.key;
                IconData icon;
                Color color;
                
                switch (entry.key) {
                  case 'CASH':
                    icon = CupertinoIcons.money_dollar;
                    color = const Color(0xFF10B981);
                    break;
                  case 'VODAFONE_CASH':
                    icon = CupertinoIcons.phone;
                    color = const Color(0xFFE1224B);
                    break;
                  case 'INSTAPAY':
                    icon = CupertinoIcons.creditcard;
                    color = const Color(0xFF003DA5);
                    break;
                  case 'BANK_TRANSFER':
                    icon = CupertinoIcons.building_2_fill;
                    color = const Color(0xFF0052D1);
                    break;
                  default:
                    icon = CupertinoIcons.question_circle_fill;
                    color = AppColors.textSecondary;
                }
                
                return GestureDetector(
                  onTap: () {
                    setState(() => _selectedPaymentMethod = entry.key);
                    Navigator.pop(context);
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: isSelected ? color : AppColors.outline.withOpacity(0.3),
                        width: isSelected ? 2 : 1,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      color: isSelected ? color.withOpacity(0.1) : AppColors.background,
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(icon, color: color, size: 24),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                entry.value,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isSelected)
                          Icon(CupertinoIcons.checkmark_alt_circle_fill, color: color, size: 24),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('إغلاق', style: GoogleFonts.plusJakartaSans()),
            ),
          ],
        ),
      ),
    );
  }
}

