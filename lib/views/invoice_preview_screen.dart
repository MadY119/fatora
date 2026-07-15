import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:printing/printing.dart';
import 'package:fatora/core/constants/app_colors.dart';
import 'package:fatora/models/invoice_model.dart';
import 'package:fatora/utils/pdf_generator.dart';

class InvoicePreviewScreen extends StatelessWidget {
  final InvoiceModel invoice;

  const InvoicePreviewScreen({super.key, required this.invoice});

  String _getStatusText() {
    switch (invoice.paymentStatus) {
      case 'PAID':
        return 'مدفوعة';
      case 'OVERDUE':
        return 'متأخرة';
      case 'DRAFT':
        return 'مسودة';
      default:
        return 'غير مدفوعة';
    }
  }

  Color _getStatusColor() {
    switch (invoice.paymentStatus) {
      case 'PAID':
        return AppColors.paidGreen;
      case 'OVERDUE':
        return const Color(0xFFEA4335);
      case 'DRAFT':
        return AppColors.textSecondary;
      default:
        return AppColors.primary;
    }
  }

  IconData _getStatusIcon() {
    switch (invoice.paymentStatus) {
      case 'PAID':
        return CupertinoIcons.checkmark_circle_fill;
      case 'OVERDUE':
        return CupertinoIcons.exclamationmark_circle_fill;
      case 'DRAFT':
        return CupertinoIcons.doc_text;
      default:
        return CupertinoIcons.hourglass;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 1,
        title: Text(
          'معاينة الفاتورة #${invoice.invoiceNumber}',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.primary),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // حالة الفاتورة
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _getStatusColor().withOpacity(0.1),
              border: Border(bottom: BorderSide(color: _getStatusColor().withOpacity(0.3))),
            ),
            child: Row(
              children: [
                Icon(_getStatusIcon(), color: _getStatusColor(), size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'حالة الفاتورة',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _getStatusText(),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: _getStatusColor(),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // معاينة PDF
          Expanded(
            child: PdfPreview(
              build: (format) => PdfGenerator.generateInvoice(invoice),
              allowPrinting: true,
              allowSharing: true,
              canChangeOrientation: false,
              canChangePageFormat: false,
              pdfFileName: 'Invoice_${invoice.invoiceNumber}.pdf',
              loadingWidget: const Center(child: CircularProgressIndicator(color: AppColors.primary)),
            ),
          ),
        ],
      ),
    );
  }
}
