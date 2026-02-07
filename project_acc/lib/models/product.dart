class Product {
  final String name;
  final double price;
  final int quantity;
  final String category;
  final String? barcode;
  final String? imageUrl;

  const Product({
    required this.name,
    required this.price,
    required this.quantity,
    required this.category,
    this.barcode,
    this.imageUrl,
  });

  Map<String, dynamic> toMap() => {
        'name': name,
        'price': price,
        'quantity': quantity,
        'category': category,
        'barcode': barcode,
        'imageUrl': imageUrl,
      };

  factory Product.fromMap(Map<String, dynamic> m) => Product(
        name: m['name'] as String? ?? '',
        price: (m['price'] as num?)?.toDouble() ?? 0,
        quantity: (m['quantity'] as num?)?.toInt() ?? 0,
        category: m['category'] as String? ?? '',
        barcode: m['barcode'] as String?,
        imageUrl: m['imageUrl'] as String?,
      );

  Product copyWith({
    String? userId,
    String? name,
    double? price,
    int? quantity,
    String? category,
    String? barcode,
    String? imageUrl,
  }) =>
      Product(
        name: name ?? this.name,
        price: price ?? this.price,
        quantity: quantity ?? this.quantity,
        category: category ?? this.category,
        barcode: barcode ?? this.barcode,
        imageUrl: imageUrl ?? this.imageUrl,
      );
}
