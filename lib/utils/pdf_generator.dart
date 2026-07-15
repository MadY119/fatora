import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:fatora/models/invoice_model.dart'; // ⬅️ تأكد أن الاستدعاء باسم fatora

class PdfGenerator {
  static Future<Uint8List> generateInvoice(InvoiceModel invoice) async {
    final pdf = pw.Document();
    final dateFormat = DateFormat('yyyy-MM-dd');

    // 🌟 تحميل خط Cairo العربي من جوجل لتشغيل الحروف العربية بشكل متصل ونظيف
    final arabicFont = await PdfGoogleFonts.cairoRegular();
    final arabicBoldFont = await PdfGoogleFonts.cairoBold();

    // تجهيز اللوجو
    pw.MemoryImage? logoImage;
    if (invoice.logoBytes != null) {
      logoImage = pw.MemoryImage(invoice.logoBytes!);
    }

    // بيانات كود الـ QR
    final String qrData = '''
FAWTARA SMART INVOICE
No: ${invoice.invoiceNumber}
Client: ${invoice.clientName}
Date: ${dateFormat.format(invoice.date)}
Grand Total: ${invoice.currencySymbol} ${invoice.grandTotal.toStringAsFixed(2)}
Status: ${invoice.paymentStatus}
''';

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        // 🌟 تطبيق الخط العربي على كل الصفحة
        theme: pw.ThemeData.withFont(
          base: arabicFont,
          bold: arabicBoldFont,
        ),
        build: (pw.Context context) {
          // 🌟 تغليف الصفحة بالكامل باتجاه اليمين لليسار (RTL) لتشغيل محرك ربط الحروف العربية
          return pw.Directionality(
            textDirection: pw.TextDirection.rtl,
            child: pw.Stack(
              children: [
                // 1. المحتوى الأساسي للفاتورة
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    // --- الهيدر ---
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        // بيانات الفاتورة رقم والتاريخ والحالة (على اليسار عربي)
                        pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text('فاتورة / INVOICE', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColor.fromInt(0xFF1A1C1E)), textDirection: pw.TextDirection.rtl),
                            pw.SizedBox(height: 8),
                            pw.Container(
                              padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: pw.BoxDecoration(
                                color: PdfColor.fromInt(0xFFF1F5F9),
                                border: pw.Border.all(color: PdfColor.fromInt(0xFF3366CC), width: 1.5),
                                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                              ),
                              child: pw.Column(
                                crossAxisAlignment: pw.CrossAxisAlignment.start,
                                children: [
                                  pw.Text('# ${invoice.invoiceNumber}', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColor.fromInt(0xFF3366CC))),
                                  pw.Text('التاريخ: ${dateFormat.format(invoice.date)}', style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700), textDirection: pw.TextDirection.rtl),
                                ],
                              ),
                            ),
                            pw.SizedBox(height: 12),
                            // حالة الدفع وطريقة الدفع
                            pw.Row(
                              children: [
                                pw.Container(
                                  padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: pw.BoxDecoration(
                                    color: invoice.paymentStatus == 'PAID' ? PdfColor.fromInt(0xFFE8F5E9) : invoice.paymentStatus == 'OVERDUE' ? PdfColor.fromInt(0xFFFFEBEE) : PdfColor.fromInt(0xFFFFF9C4),
                                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                                    border: pw.Border.all(
                                      color: invoice.paymentStatus == 'PAID' ? PdfColor.fromInt(0xFF4CAF50) : invoice.paymentStatus == 'OVERDUE' ? PdfColor.fromInt(0xFFF44336) : PdfColor.fromInt(0xFFFBC02D),
                                    ),
                                  ),
                                  child: pw.Text(
                                    invoice.paymentStatus == 'PAID' ? 'مدفوعة / PAID' : invoice.paymentStatus == 'OVERDUE' ? 'متأخرة / OVERDUE' : invoice.paymentStatus == 'DRAFT' ? 'مسودة / DRAFT' : 'قيد الانتظار / PENDING',
                                    style: pw.TextStyle(
                                      fontSize: 11,
                                      fontWeight: pw.FontWeight.bold,
                                      color: invoice.paymentStatus == 'PAID' ? PdfColor.fromInt(0xFF2E8B57) : invoice.paymentStatus == 'OVERDUE' ? PdfColor.fromInt(0xFFD32F2F) : invoice.paymentStatus == 'DRAFT' ? PdfColors.grey700 : PdfColor.fromInt(0xFFF57F17),
                                    ),
                                    textDirection: pw.TextDirection.rtl,
                                  ),
                                ),
                                pw.SizedBox(width: 12),
                                pw.Container(
                                  padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: pw.BoxDecoration(
                                    color: PdfColor.fromInt(0xFFE3F2FD),
                                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                                    border: pw.Border.all(color: PdfColor.fromInt(0xFF1976D2)),
                                  ),
                                  child: pw.Text(
                                    'الدفع: ${_getPaymentMethodArabic(invoice.paymentMethod)}',
                                    style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColor.fromInt(0xFF1976D2)),
                                    textDirection: pw.TextDirection.rtl,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        // اللوجو واسم الشركة (على اليمين)
                        pw.Row(
                          children: [
                            pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.end,
                              children: [
                                pw.Text('FAWTARA', style: pw.TextStyle(fontSize: 28, fontWeight: pw.FontWeight.bold, color: PdfColor.fromInt(0xFF3366CC))),
                                pw.Text('فواتير ذكية', style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700), textDirection: pw.TextDirection.rtl),
                                pw.Text('حلول الفواتير التنفيذية', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600), textDirection: pw.TextDirection.rtl),
                              ],
                            ),
                            if (logoImage != null) ...[
                              pw.SizedBox(width: 16),
                              pw.Container(
                                width: 60,
                                height: 60,
                                decoration: pw.BoxDecoration(
                                  border: pw.Border.all(color: PdfColor.fromInt(0xFF3366CC), width: 2),
                                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                                ),
                                child: pw.Image(logoImage),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 24),
                    pw.Divider(color: PdfColors.grey300, thickness: 2),
                    pw.SizedBox(height: 16),

                    // --- بيانات العميل بشكل أفضل ---
                    pw.Container(
                      padding: const pw.EdgeInsets.all(12),
                      decoration: pw.BoxDecoration(
                        color: PdfColor.fromInt(0xFFF8F9FA),
                        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                        border: pw.Border.all(color: PdfColors.grey300),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('العميل / BILL TO:', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColor.fromInt(0xFF3366CC)), textDirection: pw.TextDirection.rtl),
                          pw.SizedBox(height: 8),
                          pw.Text(invoice.clientName.isEmpty ? 'عميل عام' : invoice.clientName, style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold), textDirection: pw.TextDirection.rtl),
                          if (invoice.clientEmail.isNotEmpty) ...[
                            pw.SizedBox(height: 4),
                            pw.Text('البريد: ${invoice.clientEmail}', style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey700), textDirection: pw.TextDirection.rtl),
                          ],
                          if (invoice.clientPhone.isNotEmpty) ...[
                            pw.SizedBox(height: 2),
                            pw.Text('الهاتف: ${invoice.clientPhone}', style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey700), textDirection: pw.TextDirection.rtl),
                          ],
                        ],
                      ),
                    ),
                    pw.SizedBox(height: 20),

                    // --- جدول الأصناف (مع إجبار اتجاه النص RTL لربط الحروف) ---
                    pw.TableHelper.fromTextArray(
                      headers: ['البيان / Description', 'الكمية', 'سعر الوحدة', 'الإجمالي (${invoice.currencySymbol})'],
                      data: invoice.items.map((item) => [
                        item.description,
                        item.quantity.toString(),
                        '${invoice.currencySymbol} ${item.unitPrice.toStringAsFixed(2)}',
                        '${invoice.currencySymbol} ${item.totalPrice.toStringAsFixed(2)}',
                      ]).toList(),
                      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 11),
                      headerDecoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFF3366CC)),
                      rowDecoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey200))),
                      cellAlignment: pw.Alignment.centerRight,
                      headerDirection: pw.TextDirection.rtl,
                      tableDirection: pw.TextDirection.rtl,
                      cellAlignments: {
                        1: pw.Alignment.center,
                        2: pw.Alignment.centerLeft,
                        3: pw.Alignment.centerLeft,
                      },
                      cellPadding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                    ),
                    pw.SizedBox(height: 24),

                    // --- الحسابات الختامية والـ QR ---
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        // أرقام الحسابات
                        pw.Container(
                          width: 220,
                          child: pw.Column(
                            children: [
                              _buildTotalRow('المجموع الفرعي:', '${invoice.currencySymbol} ${invoice.subTotal.toStringAsFixed(2)}'),
                              if (invoice.discountAmount > 0)
                                _buildTotalRow('الخصم:', '- ${invoice.currencySymbol} ${invoice.discountAmount.toStringAsFixed(2)}', color: PdfColors.red700),
                              if (invoice.taxRate > 0)
                                _buildTotalRow('الضريبة (${(invoice.taxRate * 100).toInt()}%):', '${invoice.currencySymbol} ${invoice.taxAmount.toStringAsFixed(2)}'),
                              pw.Divider(color: PdfColors.grey400),
                              _buildTotalRow('الإجمالي الكلي:', '${invoice.currencySymbol} ${invoice.grandTotal.toStringAsFixed(2)}', isBold: true),
                            ],
                          ),
                        ),
                        // كود الـ QR
                        pw.Container(
                          padding: const pw.EdgeInsets.all(6),
                          decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey300), borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6))),
                          child: pw.Row(
                            children: [
                              pw.Column(
                                crossAxisAlignment: pw.CrossAxisAlignment.end,
                                children: [
                                  pw.Text('امسح للتحقق', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColor.fromInt(0xFF3366CC)), textDirection: pw.TextDirection.rtl),
                                  pw.Text('فاتورة ذكية', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600), textDirection: pw.TextDirection.rtl),
                                  pw.Text('الحالة: ${invoice.paymentStatus}', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: invoice.paymentStatus == 'PAID' ? PdfColors.green700 : PdfColors.red700), textDirection: pw.TextDirection.rtl),
                                ],
                              ),
                              pw.SizedBox(width: 10),
                              pw.BarcodeWidget(
                                barcode: pw.Barcode.qrCode(),
                                data: qrData,
                                width: 55,
                                height: 55,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 20),

                    // --- طرق تحويل الفلوس (مضبوطة عربياً) ---
                    if (invoice.paymentInstructions.isNotEmpty) ...[
                      pw.Container(
                        width: double.infinity,
                        padding: const pw.EdgeInsets.all(12),
                        decoration: pw.BoxDecoration(
                          color: PdfColor.fromInt(0xFFF1F5F9),
                          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                          border: pw.Border.all(color: PdfColors.grey300),
                        ),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text('طرق الدفع والتحويل / PAYMENT INSTRUCTIONS:', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColor.fromInt(0xFF3366CC)), textDirection: pw.TextDirection.rtl),
                            pw.SizedBox(height: 4),
                            pw.Text(invoice.paymentInstructions, style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey800), textDirection: pw.TextDirection.rtl),
                          ],
                        ),
                      ),
                    ],

                    pw.Spacer(),
                    pw.Divider(color: PdfColors.grey300),
                    pw.SizedBox(height: 8),
                    pw.Center(
                      child: pw.Text('شكراً لتعاملكم معنا! تم إصدار الفاتورة بواسطة تطبيق Fawtara.', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey500), textDirection: pw.TextDirection.rtl),
                    ),
                  ],
                ),

                // 2. 🌟 نقل الختم ليكون على الشمال تحت بأناقة وبدون ما يغطي الكلام
                if (invoice.paymentStatus == 'PAID' || invoice.paymentStatus == 'OVERDUE')
                  pw.Positioned(
                    left: 10, // تم نقله لليسار ليتناسب مع التنسيق العربي
                    bottom: 60,
                    child: pw.Transform.rotate(
                      angle: 0.2,
                      child: pw.Container(
                        decoration: pw.BoxDecoration(
                          border: pw.Border.all(
                            color: invoice.paymentStatus == 'PAID' ? PdfColor.fromInt(0xFF2E8B57) : PdfColor.fromInt(0xFFB22222),
                            width: 3.5,
                          ),
                          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
                        ),
                        padding: const pw.EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                        child: pw.Text(
                          invoice.paymentStatus == 'PAID' ? 'خالص / PAID' : 'متأخر / OVERDUE',
                          style: pw.TextStyle(
                            fontSize: 22,
                            fontWeight: pw.FontWeight.bold,
                            color: invoice.paymentStatus == 'PAID' ? PdfColor.fromInt(0xFF2E8B57) : PdfColor.fromInt(0xFFB22222),
                          ),
                          textDirection: pw.TextDirection.rtl, // ⬅️ لربط حروف كلمة خالص
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildTotalRow(String label, String value, {bool isBold = false, PdfColor? color}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(value, style: pw.TextStyle(fontSize: 13, fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal, color: color ?? (isBold ? PdfColor.fromInt(0xFF3366CC) : PdfColors.black))),
          pw.Text(label, style: pw.TextStyle(fontSize: 11, fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal), textDirection: pw.TextDirection.rtl),
        ],
      ),
    );
  }

  static String _getPaymentMethodArabic(String method) {
    switch (method) {
      case 'CASH':
        return 'كاش / Cash';
      case 'VODAFONE_CASH':
        return 'فودافون كاش';
      case 'INSTAPAY':
        return 'إنستاباي';
      case 'BANK_TRANSFER':
        return 'تحويل بنكي';
      default:
        return 'كاش / Cash';
    }
  }
}