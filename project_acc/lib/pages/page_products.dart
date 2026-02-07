import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:project_acc/forms/product_form_modal.dart';
import 'package:project_acc/models/product.dart';
import 'package:project_acc/pages/page_settings.dart';
import 'package:project_acc/scanner/scanner_modal.dart';

class ProductsPage extends StatefulWidget {
  const ProductsPage({
    super.key,
    required this.onThemeChanged,
  });

  final OnThemeChanged onThemeChanged;

  @override
  State<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends State<ProductsPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'all';
  String _searchTerm = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = _ProductsTheme.of(context);

    return Scaffold(
      backgroundColor: t.scaffoldBg,
      appBar: AppBar(
        title: Text('Products Management',
            style: TextStyle(fontWeight: FontWeight.bold, color: t.textPrimary)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: Column(
        children: [
          // Header Section: Search and Filters
          _buildHeader(t),

          // Product List
          Expanded(
            child: StreamBuilder(
              stream: _firestore.collection('products').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return _buildEmptyState();
                }

                // Filtering Logic
                final filteredDocs = snapshot.data!.docs.where((doc) {
                  final data = doc.data();
                  final name = (data['name'] ?? '').toString().toLowerCase();
                  final barcode = (data['barcode'] ?? '').toString();
                  final category = (data['category'] ?? 'all').toString();

                  final matchesSearch =
                      name.contains(_searchTerm.toLowerCase()) ||
                          barcode.contains(_searchTerm);
                  final matchesCategory = _selectedCategory == 'all' ||
                      category == _selectedCategory;

                  return matchesSearch && matchesCategory;
                }).toList();

                return ListView.builder(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: filteredDocs.length,
                  itemBuilder: (context, index) {
                    final doc = filteredDocs[index];
                    return _ProductCard(
                      productId: doc.id,
                      product: doc.data(),
                      lowStockThreshold: 10,
                      theme: t,
                      onEdit: () => _openEditModal(doc.id, doc.data()),
                      onDelete: () => _showDeleteConfirmation(doc.id),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddModal,
        label: const Text('Add Product'),
        icon: const Icon(Icons.add),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }


  Widget _buildHeader(_ProductsTheme t) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      decoration: BoxDecoration(
        color: t.scaffoldBg,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Search Bar
          TextField(
            controller: _searchController,
            onChanged: (val) => setState(() => _searchTerm = val),
            style: TextStyle(color: t.textPrimary),
            decoration: InputDecoration(
              hintText: 'Search by name or scan...',
              hintStyle: TextStyle(color: t.textMuted),
              prefixIcon: Icon(Icons.search, color: t.textMuted),
              suffixIcon: IconButton(
                icon: Icon(Icons.qr_code_scanner, color: t.textMuted),
                onPressed: _openScanner,
              ),
              filled: true,
              fillColor: t.surfaceElevated,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Category Chips
          _buildCategoryList(),
        ],
      ),
    );
  }

  Widget _buildCategoryList() {
    return StreamBuilder(
      stream: _firestore.collection('products').snapshots(),
      builder: (context, snapshot) {
        List<String> categories = ['all'];
        if (snapshot.hasData) {
          categories.addAll(snapshot.data!.docs
              .map((doc) => doc['category']?.toString() ?? 'other')
              .toSet()
              .toList());
        }
        return SizedBox(
          height: 35,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: categories.map((cat) {
              final isSelected = _selectedCategory == cat;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(cat[0].toUpperCase() + cat.substring(1)),
                  selected: isSelected,
                  onSelected: (_) => setState(() => _selectedCategory = cat),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  Widget _buildBottomNav() {
    return BottomNavigationBar(
      currentIndex: 1,
      items: const [
        BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard),
            label: 'Dashboard'),
        BottomNavigationBarItem(
            icon: Icon(Icons.inventory_2_outlined),
            activeIcon: Icon(Icons.inventory_2),
            label: 'Products'),
        BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            activeIcon: Icon(Icons.settings),
            label: 'Settings'),
      ],
      onTap: (index) {
        if (index == 0) Navigator.pushReplacementNamed(context, '/dashboard');
        if (index == 2) Navigator.pushReplacementNamed(context, '/settings');
      },
    );
  }

  Widget _buildEmptyState() {
    final t = _ProductsTheme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2_outlined,
              size: 80, color: t.textMuted.withOpacity(0.5)),
          const SizedBox(height: 16),
          Text("No products found",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: t.textPrimary)),
          Text("Try a different search or add a new item",
              style: TextStyle(color: t.textMuted)),
        ],
      ),
    );
  }

  // --- LOGIC METHODS ---

  void _openScanner() {
    showDialog(
      context: context,
      builder: (context) => ScannerModal(onScan: (barcode) {
        setState(() {
          _searchController.text = barcode;
          _searchTerm = barcode;
        });
      }),
    );
  }


  void _openAddModal() {
    showDialog(
      context: context,
      builder: (context) => ProductFormModal(onSave: (product) async {
        await _firestore.collection('products').add(product.toMap());
      }),
    );
  }

  void _openEditModal(String id, Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (context) => ProductFormModal(
        editProduct: Product.fromMap(data),
        onSave: (updated) async {
          await _firestore
              .collection('products')
              .doc(id)
              .update(updated.toMap());
        },
      ),
    );
  }

  void _showDeleteConfirmation(String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Product?'),
        content: const Text('Are you sure you want to remove this item?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () {
              _firestore.collection('products').doc(id).delete();
              Navigator.pop(context);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final String productId;
  final Map<String, dynamic> product;
  final int lowStockThreshold;
  final _ProductsTheme theme;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ProductCard({
    required this.productId,
    required this.product,
    required this.lowStockThreshold,
    required this.theme,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final qty = int.tryParse(product['quantity']?.toString() ?? '0') ?? 0;
    final isLow = qty <= lowStockThreshold;
    final price = double.tryParse(product['price']?.toString() ?? '0.0') ?? 0.0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 0,
      color: theme.surface,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            // Product Image
            ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: Container(
                width: 80,
                height: 80,
                color: theme.surfaceElevated,
                child: product['imageUrl'] != null &&
                        product['imageUrl'].isNotEmpty
                    ? Image.network(product['imageUrl'],
                        fit: BoxFit.cover,
                        errorBuilder: (c, e, s) =>
                            Icon(Icons.broken_image, color: theme.textMuted))
                    : Icon(Icons.image, color: theme.textMuted),
              ),
            ),
            const SizedBox(width: 16),
            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product['name'] ?? 'Unknown',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16, color: theme.textPrimary)),
                  Text(product['category'] ?? 'Other',
                      style:
                          TextStyle(color: theme.textMuted, fontSize: 12)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text("\$${price.toStringAsFixed(2)}",
                          style: const TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold)),
                      const Spacer(),
                      _buildStockBadge(qty, isLow),
                    ],
                  ),
                ],
              ),
            ),
            // Actions
            Column(
              children: [
                IconButton(

                    onPressed: onEdit,
                    icon: const Icon(Icons.edit_outlined, color: Colors.blue)),
                IconButton(
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete_outline, color: Colors.red)),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildStockBadge(int qty, bool isLow) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isLow
            ? Colors.red.withOpacity(theme.isDark ? 0.2 : 0.1)
            : Colors.green.withOpacity(theme.isDark ? 0.2 : 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        "Stock: $qty",
        style: TextStyle(
          color: isLow
              ? (theme.isDark ? Colors.red.shade300 : Colors.red)
              : (theme.isDark ? Colors.green.shade300 : Colors.green),
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }
}

// -------------------- Products Theme --------------------
class _ProductsTheme {
  final bool isDark;
  final Color primary;
  final Color surface;
  final Color surfaceElevated;
  final Color scaffoldBg;
  final Color border;
  final Color textPrimary;
  final Color textMuted;
  final double radius;

  const _ProductsTheme({
    required this.isDark,
    required this.primary,
    required this.surface,
    required this.surfaceElevated,
    required this.scaffoldBg,
    required this.border,
    required this.textPrimary,
    required this.textMuted,
    required this.radius,
  });

  factory _ProductsTheme.of(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return _ProductsTheme(
      isDark: isDark,
      primary: Colors.deepPurple,
      surface: isDark ? const Color(0xFF14141A) : Colors.white,
      surfaceElevated: isDark ? const Color(0xFF1E1E26) : Colors.grey.shade100,
      scaffoldBg: isDark ? const Color(0xFF0F0F14) : const Color(0xFFF8F9FA),
      border: isDark ? Colors.white12 : Colors.grey.shade200,
      textPrimary: isDark ? Colors.white : const Color(0xFF1C1C28),
      textMuted: isDark ? Colors.white70 : Colors.grey.shade600,
      radius: 12,
    );
  }
}
