import 'inventory_model.dart';

class Inventory {
  final InventoryModel _model;

  Inventory({required InventoryModel model}) : _model = model;

  String get id => _model.id;
  String get brand => _model.brand;
  String get model => _model.model;
  String get category => _model.category;
  double get price => _model.price;
  int get quantity => _model.quantity;
  String get imageUrl => _model.imageUrl;

  bool isAvailable() => quantity > 0;

  double calculateTotalPrice(int quantity) => price * quantity;

  Map<String, dynamic> toMap() => _model.toMap();

  factory Inventory.fromMap(Map<String, dynamic> map) {
    return Inventory(
      model: InventoryModel.fromMap(map),
    );
  }
}
