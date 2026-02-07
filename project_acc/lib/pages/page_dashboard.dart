import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:project_acc/pages/page_settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({
    super.key,
    required this.onThemeChanged,
  });

  final OnThemeChanged onThemeChanged;

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  int _lowStockThreshold = 10;
  String _userName = '';

  @override
  void initState() {
    super.initState();
    _loadUserName();
  }

  Future<void> _loadUserName() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userName = prefs.getString('username') ?? 'User';
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = _DashboardTheme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Inventory Manager',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: t.textPrimary,
              ),
            ),
            Text(
              'Welcome $_userName',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 12,
                color: t.textMuted,
              ),
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: () => Navigator.of(context).pushNamed('/products'),
            icon: const Icon(Icons.add, size: 20),
            style: TextButton.styleFrom(
              foregroundColor: t.primary,
              backgroundColor: t.primary.withOpacity(0.08),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(t.radius),
              ),
            ),
            label: const Text('Add Product', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('products').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.dashboard,
                      size: 64, color: Theme.of(context).disabledColor),
                  const SizedBox(height: 16),
                  const Text('No data yet', style: TextStyle(fontSize: 18)),
                  const SizedBox(height: 8),
                  Text(
                    'Add some products to see your dashboard',
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).disabledColor,
                    ),
                  ),
                ],
              ),
            );
          }

          final products = snapshot.data!.docs;

          // Calculate stats
          final totalProducts = products.length;
          double totalValue = 0;
          int lowStockCount = 0;
          Map<String, int> categoryCount = {};
          Map<String, double> categoryValue = {};
          List<Map<String, dynamic>> lowStockProducts = [];

          for (var doc in products) {
            final data = doc.data() as Map<String, dynamic>;

            final price = data['price'] is num
                ? (data['price'] as num).toDouble()
                : double.tryParse(data['price']?.toString() ?? '0') ?? 0;

            final quantity = data['quantity'] is num
                ? (data['quantity'] as num).toInt()
                : int.tryParse(data['quantity']?.toString() ?? '0') ?? 0;

            final category = data['category'] as String? ?? 'Other';
            totalValue += price * quantity;

            categoryCount[category] = (categoryCount[category] ?? 0) + 1;
            categoryValue[category] =
                (categoryValue[category] ?? 0) + (price * quantity);

            if (quantity <= _lowStockThreshold) {
              lowStockCount++;
              lowStockProducts.add({
                'id': doc.id,
                'name': data['name'] ?? 'Unknown',
                'quantity': quantity,
                'category': category,
                'price': price,
              });
            }
          }

          final totalCategories = categoryCount.length;

          return SingleChildScrollView(
            padding: t.pagePadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Responsive Stats Grid
                LayoutBuilder(
                  builder: (context, constraints) {
                    final width = constraints.maxWidth;

                    int crossAxisCount = 1;
                    double childAspectRatio = 2;

                    if (width >= 1200) {
                      crossAxisCount = 4;
                      childAspectRatio = 1.5;
                    } else if (width >= 900) {
                      crossAxisCount = 3;
                      childAspectRatio = 1.6;
                    } else if (width >= 600) {
                      crossAxisCount = 2;
                      childAspectRatio = 1.8;
                    } else {
                      crossAxisCount = 1;
                      childAspectRatio = 2.5;
                    }

                    return GridView.count(
                      crossAxisCount: crossAxisCount,
                      childAspectRatio: childAspectRatio,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: t.gapM,
                      crossAxisSpacing: t.gapM,
                      children: [
                        _StatCard(
                          title: 'Total Products',
                          value: totalProducts.toString(),
                          icon: Icons.inventory_2,
                          color: t.primary,
                          theme: t,
                        ),
                        _StatCard(
                          title: 'Total Value',
                          value: '\$${totalValue.toStringAsFixed(2)}',
                          icon: Icons.attach_money,
                          color: Colors.green,
                          theme: t,
                        ),
                        _StatCard(
                          title: 'Low Stock Alerts',
                          value: lowStockCount.toString(),
                          icon: Icons.warning_amber,
                          color: t.warning,
                          theme: t,
                        ),
                        _StatCard(
                          title: 'Categories',
                          value: totalCategories.toString(),
                          icon: Icons.category,
                          color: Colors.purple,
                          theme: t,
                        ),
                      ],
                    );
                  },
                ),
                SizedBox(height: t.gapL),

                // Low Stock Section
                if (lowStockProducts.isNotEmpty) ...[
                  Builder(
                    builder: (context) {
                      return Card(
                        elevation: 0,
                        color: t.warningContainer,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(t.radius),
                          side: BorderSide(color: t.warning.withOpacity(0.3)),
                        ),
                        child: Padding(
                          padding: t.cardPadding,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.warning_amber, color: t.warning),
                                  SizedBox(width: t.gapM),
                                  Text(
                                    'Low Stock Alerts',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: t.warning,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: t.gapM / 1.5),
                              Text(
                                'The following items need restocking:',
                                style: TextStyle(color: t.warning),
                              ),
                              SizedBox(height: t.gapL),
                              SizedBox(
                                height: 300,
                                child: ListView.builder(
                                  itemCount: lowStockProducts.length,
                                  itemBuilder: (context, index) {
                                    final product = lowStockProducts[index];
                                    return _LowStockCard(
                                      name: product['name'],
                                      quantity: product['quantity'],
                                      category: product['category'],
                                      theme: t,
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  SizedBox(height: t.gapL),
                ],

                // Category Overview
                Card(
                  elevation: 0,
                  color: t.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(t.radius),
                    side: BorderSide(color: t.border),
                  ),
                  child: Padding(
                    padding: t.cardPadding,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Category Overview',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: t.textPrimary,
                          ),
                        ),
                        SizedBox(height: t.gapM / 1.5),
                        ...categoryCount.entries.map((entry) {
                          final category = entry.key;
                          final count = entry.value;
                          final value = categoryValue[category] ?? 0;
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  category,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: t.textPrimary,
                                  ),
                                ),
                                Text(
                                  '$count items',
                                  style: TextStyle(
                                    color: t.textMuted,
                                    fontSize: 12,
                                  ),
                                ),
                                Text(
                                  '\$${value.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: t.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.dashboard), label: 'Dashboard'),
          BottomNavigationBarItem(
              icon: Icon(Icons.inventory_2), label: 'Products'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
        ],
        onTap: (index) {
          if (index == 1) Navigator.of(context).pushReplacementNamed('/products');
          if (index == 2) Navigator.of(context).pushReplacementNamed('/settings');
        },
      ),
    );
  }
}

// -------------------- Stat Card --------------------
class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final _DashboardTheme theme;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: theme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(theme.radius),
        side: BorderSide(color: theme.border),
      ),
      child: Padding(
        padding: theme.cardPadding,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: color, size: 24),
                Icon(Icons.trending_up, color: theme.textMuted, size: 20),
              ],
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: theme.textPrimary,
              ),
            ),
            Text(
              title,
              style: TextStyle(fontSize: 12, color: theme.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}

// -------------------- Low Stock Card --------------------
class _LowStockCard extends StatelessWidget {
  final String name;
  final int quantity;
  final String category;
  final _DashboardTheme theme;

  const _LowStockCard({
    required this.name,
    required this.quantity,
    required this.category,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: theme.gapM),
      padding: theme.cardPadding,
      decoration: BoxDecoration(
        color: theme.warningContainer,
        borderRadius: BorderRadius.circular(theme.radius),
        border: Border.all(color: theme.warning.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber, color: theme.warning),
          SizedBox(width: theme.gapM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: theme.textPrimary)),
                Text(category,
                    style: TextStyle(fontSize: 12, color: theme.textMuted)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: theme.warning,
              borderRadius: BorderRadius.circular(theme.radius / 1.2),
            ),
            child: Text(
              'Qty: $quantity',
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

// -------------------- Dashboard Theme --------------------
class _DashboardTheme {
  final bool isDark;
  final Color primary;
  final Color surface;
  final Color surfaceElevated;
  final Color border;
  final Color textPrimary;
  final Color textMuted;
  final Color warning;
  final Color warningContainer;
  final double radius;
  final double gapM;
  final double gapL;
  final EdgeInsets cardPadding;
  final EdgeInsets pagePadding;

  const _DashboardTheme({
    required this.isDark,
    required this.primary,
    required this.surface,
    required this.surfaceElevated,
    required this.border,
    required this.textPrimary,
    required this.textMuted,
    required this.warning,
    required this.warningContainer,
    required this.radius,
    required this.gapM,
    required this.gapL,
    required this.cardPadding,
    required this.pagePadding,
  });

  factory _DashboardTheme.of(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return _DashboardTheme(
      isDark: isDark,
      primary: Colors.deepPurple,
      surface: isDark ? const Color(0xFF14141A) : Colors.white,
      surfaceElevated: isDark ? const Color(0xFF1E1E26) : Colors.white,
      border: isDark ? Colors.white12 : Colors.grey.shade200,
      textPrimary: isDark ? Colors.white : const Color(0xFF1C1C28),
      textMuted: isDark ? Colors.white70 : Colors.grey.shade600,
      warning: isDark ? Colors.amber : Colors.orange,
      warningContainer:
          isDark ? const Color(0xFF2A1F12) : const Color(0xFFFFF3E6),
      radius: 12,
      gapM: 12,
      gapL: 20,
      cardPadding: const EdgeInsets.all(16),
      pagePadding: const EdgeInsets.all(16),
    );
  }
}
