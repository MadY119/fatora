import 'dart:convert';
import 'dart:typed_data';

class InvoiceItemModel {
  final String description;
  final double unitPrice;
  final int quantity;

  InvoiceItemModel({
    required this.description,
    required this.unitPrice,
    required this.quantity,
  });

  double get totalPrice => unitPrice * quantity;

  Map<String, dynamic> toJson() => {
    'description': description,
    'unitPrice': unitPrice,
    'quantity': quantity,
  };

  factory InvoiceItemModel.fromJson(Map<String, dynamic> json) => InvoiceItemModel(
    description: json['description'] ?? '',
    unitPrice: (json['unitPrice'] ?? 0.0).toDouble(),
    quantity: json['quantity'] ?? 1,
  );
}

class InvoiceModel {
  final String invoiceNumber;
  final String clientName;
  final String clientEmail;
  final String clientPhone;
  final DateTime date;
  final List<InvoiceItemModel> items;
  final double taxRate;
  final double discountAmount;
  final String currencySymbol;
  final Uint8List? logoBytes;
  
  final String paymentStatus; // 'PAID', 'PENDING', 'OVERDUE', 'DRAFT'
  final String paymentMethod; // 'CASH', 'VODAFONE_CASH', 'INSTAPAY', 'BANK_TRANSFER'
  final String paymentInstructions;

  InvoiceModel({
    required this.invoiceNumber,
    required this.clientName,
    required this.clientEmail,
    required this.clientPhone,
    required this.date,
    required this.items,
    this.taxRate = 0.00,
    this.discountAmount = 0.00,
    this.currencySymbol = '\$',
    this.logoBytes,
    this.paymentStatus = 'PENDING', // الافتراضي قيد الانتظار
    this.paymentMethod = 'CASH',
    this.paymentInstructions = '',
  });

  double get subTotal => items.fold(0, (sum, item) => sum + item.totalPrice);
  double get taxableAmount => (subTotal - discountAmount) > 0 ? (subTotal - discountAmount) : 0;
  double get taxAmount => taxableAmount * taxRate;
  double get grandTotal => taxableAmount + taxAmount;

  Map<String, dynamic> toMap() => {
    'invoiceNumber': invoiceNumber,
    'clientName': clientName,
    'clientEmail': clientEmail,
    'clientPhone': clientPhone,
    'date': date.toIso8601String(),
    'items': items.map((x) => x.toJson()).toList(),
    'taxRate': taxRate,
    'discountAmount': discountAmount,
    'currencySymbol': currencySymbol,
    'logoBytes': logoBytes != null ? base64Encode(logoBytes!) : null,
    'paymentStatus': paymentStatus,
    'paymentMethod': paymentMethod,
    'paymentInstructions': paymentInstructions,
  };

  factory InvoiceModel.fromMap(Map<String, dynamic> map) => InvoiceModel(
    invoiceNumber: map['invoiceNumber'] ?? '',
    clientName: map['clientName'] ?? '',
    clientEmail: map['clientEmail'] ?? '',
    clientPhone: map['clientPhone'] ?? '',
    date: DateTime.tryParse(map['date'] ?? '') ?? DateTime.now(),
    items: List<InvoiceItemModel>.from((map['items'] ?? []).map((x) => InvoiceItemModel.fromJson(x))),
    taxRate: (map['taxRate'] ?? 0.0).toDouble(),
    discountAmount: (map['discountAmount'] ?? 0.0).toDouble(),
    currencySymbol: map['currencySymbol'] ?? '\$',
    logoBytes: map['logoBytes'] != null ? base64Decode(map['logoBytes']) : null,
    paymentStatus: map['paymentStatus'] ?? 'PENDING',
    paymentMethod: map['paymentMethod'] ?? 'CASH',
    paymentInstructions: map['paymentInstructions'] ?? '',
  );

  String toJson() => json.encode(toMap());
  factory InvoiceModel.fromJson(String source) => InvoiceModel.fromMap(json.decode(source));
}
