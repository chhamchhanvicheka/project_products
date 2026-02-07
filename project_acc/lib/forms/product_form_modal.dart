import 'package:flutter/material.dart';
import 'package:project_acc/models/product.dart';
import 'package:project_acc/scanner/scanner_modal.dart';

class ProductFormModal extends StatefulWidget {
  final Product? editProduct;
  final Function(Product) onSave;

  const ProductFormModal({
    super.key,
    this.editProduct,
    required this.onSave,
  });

  @override
  State<ProductFormModal> createState() => _ProductFormModalState();
}

class _ProductFormModalState extends State<ProductFormModal> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _barcodeController;
  late TextEditingController _priceController;
  late TextEditingController _quantityController;
  String _selectedCategory = '';

  static const List<String> CATEGORIES = [
    'Drinks',
    'Clothing',
    'Food',
    'Books',
    'Toys',
    'Other'
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _barcodeController = TextEditingController();
    _priceController = TextEditingController();
    _quantityController = TextEditingController();

    if (widget.editProduct != null) {
      _nameController.text = widget.editProduct!.name;
      _barcodeController.text = widget.editProduct!.barcode ?? '';
      _priceController.text = widget.editProduct!.price.toString();
      _quantityController.text = widget.editProduct!.quantity.toString();
      _selectedCategory = widget.editProduct!.category;
    } else {
      _selectedCategory = CATEGORIES.first;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _barcodeController.dispose();
    _priceController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  void _openScanner() {
    showDialog(
      context: context,
      builder: (context) => ScannerModal(
        onScan: (code) {
          setState(() {
            _barcodeController.text = code;
          });
        },
      ),
    );
  }

  void _handleSubmit() {
    if (_formKey.currentState!.validate()) {
      final product = Product(
        name: _nameController.text,
        barcode:
            _barcodeController.text.isEmpty ? null : _barcodeController.text,
        price: double.parse(_priceController.text),
        quantity: int.parse(_quantityController.text),
        category: _selectedCategory,
      );

      widget.onSave(product);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = _FormTheme.of(context);

    return Dialog(
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(t.radius)),
      backgroundColor: t.surface,
      child: SingleChildScrollView(
        child: Padding(
          padding: t.pagePadding,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.editProduct != null
                            ? 'Edit Product'
                            : 'Add New Product',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: t.textPrimary,
                        ),
                      ),
                      SizedBox(height: t.gapM / 2),
                      Text(
                        widget.editProduct != null
                            ? 'Update product details'
                            : 'Enter product details or scan a barcode',
                        style: TextStyle(
                          color: t.textMuted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close, color: t.textMuted),
                  ),
                ],
              ),
              SizedBox(height: t.gapL),
              // Form
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Barcode Field with Scan Button
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _barcodeController,
                            decoration: InputDecoration(
                              labelText: 'Barcode/QR Code (Optional)',
                              labelStyle: TextStyle(color: t.textMuted),
                              hintText: '123456789',
                              hintStyle: TextStyle(
                                  color: t.textMuted.withOpacity(0.5)),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(t.radius),
                                borderSide: BorderSide(color: t.border),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(t.radius),
                                borderSide: BorderSide(color: t.border),
                              ),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                              filled: true,
                              fillColor: t.surfaceElevated,
                            ),
                            style: TextStyle(color: t.textPrimary),
                          ),
                        ),
                        SizedBox(width: t.gapM),
                        SizedBox(
                          height: 56,
                          child: ElevatedButton.icon(
                            onPressed: _openScanner,
                            icon: Icon(Icons.camera_alt, size: 20),
                            label: Text(''),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: t.primary,
                              padding: EdgeInsets.all(12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(t.radius),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: t.gapM),
                    // Name Field
                    TextFormField(
                      controller: _nameController,
                      decoration: _buildInputDecoration(
                        'Product Name *',
                        'Enter product name',
                        t,
                      ),
                      style: TextStyle(color: t.textPrimary),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Product name is required';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: t.gapM),
                    // Price Field
                    TextFormField(
                      controller: _priceController,
                      decoration: _buildInputDecoration(
                        'Price *',
                        '0.00',
                        t,
                        prefixText: '\$ ',
                      ),
                      style: TextStyle(color: t.textPrimary),
                      keyboardType:
                          TextInputType.numberWithOptions(decimal: true),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Price is required';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Enter a valid price';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: t.gapM),
                    // Quantity Field
                    TextFormField(
                      controller: _quantityController,
                      decoration: _buildInputDecoration(
                        'Quantity *',
                        '0',
                        t,
                      ),
                      style: TextStyle(color: t.textPrimary),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Quantity is required';
                        }
                        if (int.tryParse(value) == null) {
                          return 'Enter a valid quantity';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: t.gapM),
                    // Category Dropdown
                    DropdownButtonFormField<String>(
                      value: _selectedCategory,
                      dropdownColor: t.surface,
                      style: TextStyle(color: t.textPrimary),
                      decoration: _buildInputDecoration('Category *', '', t),
                      items: CATEGORIES.map((category) {
                        return DropdownMenuItem(
                          value: category,
                          child: Text(category,
                              style: TextStyle(color: t.textPrimary)),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _selectedCategory = value);
                        }
                      },
                    ),
                  ],
                ),
              ),
              SizedBox(height: t.gapL),
              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        side: BorderSide(color: t.border),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(t.radius),
                        ),
                      ),
                      child: Text('Cancel',
                          style: TextStyle(color: t.textPrimary)),
                    ),
                  ),
                  SizedBox(width: t.gapM),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _handleSubmit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: t.primary,
                        padding: EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(t.radius),
                        ),
                      ),
                      child: Text(
                        widget.editProduct != null ? 'Update' : 'Add',
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration(
    String label,
    String hint,
    _FormTheme t, {
    String? prefixText,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: t.textMuted),
      hintText: hint,
      hintStyle: TextStyle(color: t.textMuted.withOpacity(0.5)),
      prefixText: prefixText,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(t.radius),
        borderSide: BorderSide(color: t.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(t.radius),
        borderSide: BorderSide(color: t.border),
      ),
      contentPadding: EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 12,
      ),
      filled: true,
      fillColor: t.surfaceElevated,
    );
  }
}

// -------------------- Form Theme --------------------
class _FormTheme {
  final bool isDark;
  final Color primary;
  final Color surface;
  final Color surfaceElevated;
  final Color border;
  final Color textPrimary;
  final Color textMuted;
  final double radius;
  final double gapM;
  final double gapL;
  final EdgeInsets pagePadding;

  const _FormTheme({
    required this.isDark,
    required this.primary,
    required this.surface,
    required this.surfaceElevated,
    required this.border,
    required this.textPrimary,
    required this.textMuted,
    required this.radius,
    required this.gapM,
    required this.gapL,
    required this.pagePadding,
  });

  factory _FormTheme.of(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return _FormTheme(
      isDark: isDark,
      primary: Colors.deepPurple,
      surface: isDark ? const Color(0xFF14141A) : Colors.white,
      surfaceElevated: isDark ? const Color(0xFF1E1E26) : Colors.grey.shade50,
      border: isDark ? Colors.white12 : Colors.grey.shade300,
      textPrimary: isDark ? Colors.white : const Color(0xFF1C1C28),
      textMuted: isDark ? Colors.white70 : Colors.grey.shade600,
      radius: 12,
      gapM: 12,
      gapL: 20,
      pagePadding: const EdgeInsets.all(20),
    );
  }
}
