import 'package:shared_preferences/shared_preferences.dart';
import 'package:fatora/models/invoice_model.dart';

class InvoiceStorageService {
  static const String _storageKey = 'saved_invoices_archive';

  // حفظ فاتورة جديدة في الأرشيف
  static Future<void> saveInvoice(InvoiceModel invoice) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> archive = prefs.getStringList(_storageKey) ?? [];
    
    // بنتاكد لو الفاتورة دي بنفس الرقم موجودة قبل كده بنحدثها، لو جديدة بنضيفها
    archive.removeWhere((item) {
      try {
        return InvoiceModel.fromJson(item).invoiceNumber == invoice.invoiceNumber;
      } catch (e) { return false; }
    });

    archive.insert(0, invoice.toJson()); // إضافة الفاتورة الجديدة في أول القائمة
    await prefs.setStringList(_storageKey, archive);
  }

  // استرجاع كل الفواتير المحفوظة
  static Future<List<InvoiceModel>> getInvoices() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> archive = prefs.getStringList(_storageKey) ?? [];
    
    return archive.map((item) {
      try { return InvoiceModel.fromJson(item); } catch (e) { return null; }
    }).whereType<InvoiceModel>().toList();
  }

  // حذف فاتورة من الأرشيف
  static Future<void> deleteInvoice(String invoiceNumber) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> archive = prefs.getStringList(_storageKey) ?? [];
    archive.removeWhere((item) {
      try {
        return InvoiceModel.fromJson(item).invoiceNumber == invoiceNumber;
      } catch (e) {
        return true;
      }
    });
    await prefs.setStringList(_storageKey, archive);
  }
}
