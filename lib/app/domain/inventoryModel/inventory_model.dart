class InventoryModel {
  final String id;
  final String brand;
  final String model;
  final String category;
  final double price;
  final int quantity;
  final String imageUrl;

  InventoryModel({
    required this.id,
    required this.brand,
    required this.model,
    required this.category,
    required this.price,
    required this.quantity,
    required this.imageUrl,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'brand': brand,
      'model': model,
      'category': category,
      'price': price,
      'quantity': quantity,
      'imageUrl': imageUrl,
    };
  }

  factory InventoryModel.fromMap(Map<String, dynamic> map) {
    return InventoryModel(
      id: map['id'] ?? '',
      brand: map['brand'] ?? '',
      model: map['model'] ?? '',
      category: map['category'] ?? '',
      price: (map['price'] ?? 0.0).toDouble(),
      quantity: map['quantity'] ?? 0,
      imageUrl: map['imageUrl'] ?? '',
    );
  }
}
