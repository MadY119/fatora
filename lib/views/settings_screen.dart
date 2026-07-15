import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fatora/core/constants/app_colors.dart';
import 'package:fatora/models/client_model.dart';
import 'package:fatora/services/client_storage_service.dart';
import 'package:fatora/views/invoice_form_screen.dart';
import 'package:fatora/views/widgets/app_navigation.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _companyNameController = TextEditingController();
  final TextEditingController _defaultTaxController = TextEditingController();
  final TextEditingController _defaultInstructionsController = TextEditingController();
  final TextEditingController _newClientNameController = TextEditingController();
  final TextEditingController _newClientPhoneController = TextEditingController();
  final TextEditingController _newClientEmailController = TextEditingController();
  
  String _selectedCurrency = 'ر.س';
  final Map<String, String> _currencies = {
    'ر.س': 'ريال سعودي (SAR)',
    'EGP': 'جنيه مصري (EGP)',
    '\$': 'دولار أمريكي (USD)',
    '€': 'يورو (EUR)',
  };

  Uint8List? _logoBytes;
  bool _isLoading = true;
  List<ClientModel> _savedClients = [];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  // --- تحميل الإعدادات المحفوظة من ذاكرة الجهاز ---
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final clients = await ClientStorageService.getClients();
    
    if (!mounted) return;
    setState(() {
      _companyNameController.text = prefs.getString('company_name') ?? 'FAWTARA INC.';
      _defaultTaxController.text = prefs.getString('default_tax') ?? '15';
      _defaultInstructionsController.text = prefs.getString('default_instructions') ?? 'فودافون كاش / Instapay / IBAN الحساب البنكي...';
      _selectedCurrency = prefs.getString('default_currency') ?? 'ر.س';
      _savedClients = clients;
      
      final logoBase64 = prefs.getString('company_logo');
      if (logoBase64 != null) {
        try {
          _logoBytes = base64Decode(logoBase64);
        } catch (e) {
          _logoBytes = null;
        }
      }
      _isLoading = false;
    });
  }

  Future<void> _addNewClient() async {
    if (_newClientNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('يرجى إدخال اسم العميل', style: GoogleFonts.plusJakartaSans())),
      );
      return;
    }

    final newClient = ClientModel(
      name: _newClientNameController.text.trim(),
      phone: _newClientPhoneController.text.trim(),
      email: _newClientEmailController.text.trim(),
    );

    await ClientStorageService.saveClient(newClient);
    _newClientNameController.clear();
    _newClientPhoneController.clear();
    _newClientEmailController.clear();
    
    _loadSettings();
    
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(CupertinoIcons.checkmark_alt_circle_fill, color: Colors.white),
              const SizedBox(width: 8),
              Text('تم إضافة العميل بنجاح!', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)),
            ],
          ),
          backgroundColor: AppColors.paidGreen,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _deleteClient(String clientName) async {
    await ClientStorageService.deleteClient(clientName);
    _loadSettings();
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تم حذف العميل', style: GoogleFonts.plusJakartaSans())),
      );
    }
  }

  void _showAddClientDialog() {
    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: Text('إضافة عميل جديد', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _newClientNameController,
                  decoration: InputDecoration(
                    labelText: 'اسم العميل',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _newClientPhoneController,
                  decoration: InputDecoration(
                    labelText: 'رقم الهاتف',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _newClientEmailController,
                  decoration: InputDecoration(
                    labelText: 'البريد الإلكتروني',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('إلغاء', style: GoogleFonts.plusJakartaSans()),
            ),
            ElevatedButton(
              onPressed: _addNewClient,
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              child: Text('إضافة', style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  // --- حفظ الإعدادات في ذاكرة الجهاز ---
  Future<void> _saveSettings() async {
    if (_formKey.currentState!.validate()) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('company_name', _companyNameController.text.trim());
      await prefs.setString('default_tax', _defaultTaxController.text.trim());
      await prefs.setString('default_instructions', _defaultInstructionsController.text.trim());
      await prefs.setString('default_currency', _selectedCurrency);
      
      if (_logoBytes != null) {
        await prefs.setString('company_logo', base64Encode(_logoBytes!));
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(CupertinoIcons.checkmark_alt_circle_fill, color: Colors.white),
                const SizedBox(width: 8),
                Text('تم حفظ الإعدادات بنجاح! 💾', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)),
              ],
            ),
            backgroundColor: AppColors.paidGreen,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _pickLogo() async {
    try {
      // عرض مؤشر التحميل
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white)),
                ),
                const SizedBox(width: 12),
                Text('جاري معالجة الصورة...', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)),
              ],
            ),
            backgroundColor: AppColors.primary,
            duration: const Duration(seconds: 30),
          ),
        );
      }

      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      
      if (pickedFile != null) {
        // قراءة الصورة الأصلية
        final bytes = await pickedFile.readAsBytes();
        
        // فك تشفير الصورة وضغطها
        final image = img.decodeImage(bytes);
        if (image != null) {
          // تصغير الصورة إلى 200x200 للحفاظ على الأداء
          final resized = img.copyResize(image, width: 200, height: 200);
          
          // ضغط الصورة بجودة 85%
          final compressed = img.encodePng(resized, level: 6); // أقصى ضغط PNG
          
          setState(() => _logoBytes = Uint8List.fromList(compressed));
          
          if (mounted) {
            ScaffoldMessenger.of(context).clearSnackBars();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(CupertinoIcons.checkmark_circle_fill, color: Colors.white),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'تم تحميل الصورة بنجاح! ✓',
                        style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                backgroundColor: AppColors.paidGreen,
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 2),
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(CupertinoIcons.exclamationmark_circle_fill, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'خطأ في تحميل الصورة: ${e.toString()}',
                    style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.unpaidRed,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _companyNameController.dispose();
    _defaultTaxController.dispose();
    _defaultInstructionsController.dispose();
    _newClientNameController.dispose();
    _newClientPhoneController.dispose();
    _newClientEmailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 1024;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.background,
        
        // --- Top AppBar (Mobile) ---
        appBar: isDesktop ? null : AppBar(
          backgroundColor: AppColors.surface,
          elevation: 0,
          centerTitle: true,
          title: Text('FAWTARA | الإعدادات والعملاء', style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary)),
          leading: IconButton(
            icon: const Icon(CupertinoIcons.bars, color: AppColors.textSecondary),
            onPressed: () => AppNavigation.showMenu(context, currentIndex: 3),
          ),
          bottom: PreferredSize(preferredSize: const Size.fromHeight(1), child: Container(color: AppColors.outline.withOpacity(0.3), height: 1)),
        ),

        // --- Bottom NavBar (Mobile) ---
        bottomNavigationBar: isDesktop ? null : AppNavigation.bottomNav(context: context, currentIndex: 3),

        body: Row(
          children: [
            if (isDesktop) AppNavigation.desktopSideNav(context: context, currentIndex: 3),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                  : Form(
                key: _formKey,
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: isDesktop ? 40.0 : 16.0, vertical: 24.0),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1000),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('الإعدادات المؤسسية', style: GoogleFonts.plusJakartaSans(fontSize: isDesktop ? 32 : 26, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                          const SizedBox(height: 4),
                          Text('إدارة بيانات شركتك، الحسابات المالية الافتراضية، وقائمة العملاء.', style: GoogleFonts.plusJakartaSans(fontSize: 15, color: AppColors.textSecondary)),
                          const SizedBox(height: 24),

                          // 1. كارت هوية الشركة والشعار
                          _buildCardContainer(
                            title: 'هوية الشركة والشعار',
                            icon: CupertinoIcons.building_2_fill,
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    GestureDetector(
                                      onTap: _pickLogo,
                                      child: Container(
                                        width: 80, height: 80,
                                        decoration: BoxDecoration(
                                          color: AppColors.background,
                                          borderRadius: BorderRadius.circular(16),
                                          border: Border.all(color: AppColors.primary.withOpacity(0.5), width: 1.5),
                                        ),
                                        child: _logoBytes != null
                                            ? ClipRRect(borderRadius: BorderRadius.circular(14), child: Image.memory(_logoBytes!, fit: BoxFit.cover))
                                            : Column(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  const Icon(CupertinoIcons.camera_fill, color: AppColors.primary, size: 24),
                                                  const SizedBox(height: 4),
                                                  Text('الشعار', style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColors.textSecondary)),
                                                ],
                                              ),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: _buildInputField(label: 'اسم الشركة أو المؤسسة', controller: _companyNameController, hint: 'FAWTARA INC.', isRequired: true),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),

                          // 2. كارت الإعدادات المالية الافتراضية
                          _buildCardContainer(
                            title: 'الإعدادات المالية والضرائب',
                            icon: CupertinoIcons.money_dollar_circle_fill,
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text('العملة الافتراضية', style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                                          const SizedBox(height: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
                                            decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.outline)),
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
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: _buildInputField(label: 'نسبة الضريبة الافتراضية (%)', controller: _defaultTaxController, hint: '15', keyboardType: TextInputType.number),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                _buildInputField(label: 'تعليمات الدفع والتحويل الافتراضية (تظهر في كل فاتورة)', controller: _defaultInstructionsController, hint: 'مثال: فودافون كاش / Instapay / IBAN...', maxLines: 2),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),

                          // 3. زرار الحفظ الفخم
                          Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.2), blurRadius: 20, offset: const Offset(0, 8))],
                            ),
                            child: ElevatedButton.icon(
                              onPressed: _saveSettings,
                              icon: const Icon(CupertinoIcons.floppy_disk, color: Colors.white, size: 20),
                              label: Text('حفظ التعديلات المؤسسية', style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                elevation: 0,
                              ),
                            ),
                          ),
                          const SizedBox(height: 36),

                          // 4. كارت إدارة العملاء الدائمين
                          _buildCardContainer(
                            title: 'قائمة العملاء الدائمين (${_savedClients.length})',
                            icon: CupertinoIcons.group_solid,
                            child: Column(
                              children: [
                                if (_savedClients.isEmpty)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 24.0),
                                    child: Center(
                                      child: Column(
                                        children: [
                                          Icon(CupertinoIcons.person_crop_circle, color: AppColors.textSecondary.withOpacity(0.3), size: 48),
                                          const SizedBox(height: 12),
                                          Text('لا يوجد عملاء مضافون حالياً', style: GoogleFonts.plusJakartaSans(fontSize: 15, color: AppColors.textSecondary)),
                                          const SizedBox(height: 4),
                                          Text('أضف عملاء جدد للبدء', style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppColors.textSecondary.withOpacity(0.6))),
                                        ],
                                      ),
                                    ),
                                  )
                                else
                                  ListView.separated(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    itemCount: _savedClients.length,
                                    separatorBuilder: (_, __) => const Divider(color: AppColors.outline, height: 24),
                                    itemBuilder: (context, index) {
                                      final client = _savedClients[index];
                                      return Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Row(
                                              children: [
                                                CircleAvatar(
                                                  backgroundColor: AppColors.primaryContainer,
                                                  child: const Icon(CupertinoIcons.person_fill, color: AppColors.primary, size: 18),
                                                ),
                                                const SizedBox(width: 12),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Text(client.name, style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                                                      Text('${client.phone} • ${client.email}', style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          PopupMenuButton(
                                            itemBuilder: (context) => [
                                              PopupMenuItem(
                                                child: Text('إصدار فاتورة', style: GoogleFonts.plusJakartaSans()),
                                                onTap: () => Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (_) => InvoiceFormScreen(initialClient: client),
                                                  ),
                                                ),
                                              ),
                                              PopupMenuItem(
                                                child: Text('حذف', style: GoogleFonts.plusJakartaSans(color: Colors.redAccent)),
                                                onTap: () => _deleteClient(client.name),
                                              ),
                                            ],
                                            icon: const Icon(CupertinoIcons.ellipsis_vertical, color: AppColors.primary),
                                          ),
                                        ],
                                      );
                                    },
                                  ),
                                const SizedBox(height: 16),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: _showAddClientDialog,
                                    icon: const Icon(CupertinoIcons.add_circled, color: Colors.white),
                                    label: Text('إضافة عميل جديد', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, color: Colors.white)),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primary,
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                  ),
                                ),
                              ],
                            ),
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

  Widget _buildCardContainer({required String title, required IconData icon, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outline.withOpacity(0.3)),
        boxShadow: [BoxShadow(color: const Color(0xFF0F172A).withOpacity(0.02), blurRadius: 15, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: AppColors.primaryContainer, borderRadius: BorderRadius.circular(8)), child: Icon(icon, color: AppColors.primary, size: 20)),
              const SizedBox(width: 12),
              Text(title, style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
            ],
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }

  Widget _buildInputField({required String label, required TextEditingController controller, String? hint, TextInputType keyboardType = TextInputType.text, bool isRequired = false, int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w500, color: AppColors.textPrimary),
          validator: (val) => isRequired && (val == null || val.isEmpty) ? 'مطلوب' : null,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.plusJakartaSans(color: AppColors.textSecondary.withOpacity(0.5)),
            filled: true,
            fillColor: AppColors.surface,
            contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.outline, width: 1)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.outline, width: 1)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
          ),
        ),
      ],
    );
  }
}
