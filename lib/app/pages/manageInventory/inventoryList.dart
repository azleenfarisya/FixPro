import 'package:flutter/material.dart';
import '../../services/inventory_service.dart';
import 'addParts.dart';
import 'importParts.dart';
import 'editParts.dart';

class InventoryListPage extends StatefulWidget {
  const InventoryListPage({super.key});

  @override
  State<InventoryListPage> createState() => _InventoryListPageState();
}

class _InventoryListPageState extends State<InventoryListPage> {
  final _searchController = TextEditingController();
  final _inventoryService = InventoryService();
  String _searchQuery = '';
  String _selectedCategoryFilter =
      'All'; // New state variable for selected filter

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFC7E3F4), // Light blue background
      body: Column(
        children: [
          Container(
            width: double.infinity, // Make the container span full width
            decoration: const BoxDecoration(
              color: Colors.white, // White background
            ),
            padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Parts & Stock',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // New row for Import Parts and Add Parts buttons
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const ImportPartsPage(),
                              ),
                            );
                          },
                          icon: const Icon(Icons.import_export,
                              color: Colors.blue),
                          label: const Text('Import Parts',
                              style: TextStyle(color: Colors.blue)),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.blue),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const AddPartsPage(),
                              ),
                            );
                          },
                          icon: const Icon(Icons.add, color: Colors.white),
                          label: const Text('Add Parts',
                              style: TextStyle(color: Colors.white)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Category filter buttons
                const SizedBox(height: 16),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    children: [
                      _buildFilterButton('All'),
                      _buildFilterButton('Tires'),
                      _buildFilterButton('Brake disc'),
                      _buildFilterButton('Engine'),
                      _buildFilterButton('Suspension'),
                      _buildFilterButton('Electrical'),
                      _buildFilterButton('Body parts'),
                      _buildFilterButton('Accessories'),
                      _buildFilterButton('Oil filer'),
                      _buildFilterButton('Throttle'),
                      _buildFilterButton('Fuel tank'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _inventoryService.getCurrentWorkshopInventory(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(child: Text('Something went wrong'));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final items = snapshot.data ?? [];
                if (items.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inventory_2,
                          size: 64,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'No inventory items found',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Click Add Parts or Import Parts to add inventory',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                final filteredItems = _searchQuery.isEmpty
                    ? items
                    : items.where((item) {
                        final name = item['name'].toString().toLowerCase();
                        final brand = item['brand'].toString().toLowerCase();
                        final model = item['model'].toString().toLowerCase();
                        final category =
                            item['category'].toString().toLowerCase();
                        final searchQuery = _searchQuery.toLowerCase();

                        return name.contains(searchQuery) ||
                            brand.contains(searchQuery) ||
                            model.contains(searchQuery) ||
                            category.contains(searchQuery);
                      }).toList();

                if (filteredItems.isEmpty) {
                  return const Center(
                    child: Text('No matching parts found'),
                  );
                }

                // Group items by category
                final Map<String, List<Map<String, dynamic>>> itemsByCategory =
                    {};
                for (var item in filteredItems) {
                  final category = item['category'] as String;
                  final standardizedCategory =
                      _inventoryService.standardizeCategory(category);
                  if (!itemsByCategory.containsKey(standardizedCategory)) {
                    itemsByCategory[standardizedCategory] = [];
                  }
                  itemsByCategory[standardizedCategory]!.add(item);
                }

                // Build the list of sections
                return ListView.builder(
                  itemCount: itemsByCategory.keys.length,
                  itemBuilder: (context, sectionIndex) {
                    final category =
                        itemsByCategory.keys.elementAt(sectionIndex);
                    final categoryItems = itemsByCategory[category]!;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedCategoryFilter = category;
                              _searchQuery = _inventoryService
                                  .standardizeCategory(category);
                            });
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16.0,
                              vertical: 8.0,
                            ),
                            child: Row(
                              children: [
                                Text(
                                  _inventoryService
                                      .standardizeCategory(category),
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(Icons.arrow_forward_ios, size: 16),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(
                          height: 250,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: categoryItems.length,
                            itemBuilder: (context, itemIndex) {
                              final item = categoryItems[itemIndex];
                              return Stack(
                                children: [
                                  Container(
                                    width: 180,
                                    margin: const EdgeInsets.symmetric(
                                        horizontal: 8.0),
                                    child: Card(
                                      elevation: 2,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            if (item['imageUrl'] != null)
                                              Expanded(
                                                child: Container(
                                                  width: 150,
                                                  height: 150,
                                                  decoration: BoxDecoration(
                                                    border: Border.all(
                                                        color: Colors
                                                            .grey.shade300),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            8),
                                                  ),
                                                  child: ClipRRect(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            8),
                                                    child: Image.network(
                                                      item['imageUrl'],
                                                      fit: BoxFit.contain,
                                                      errorBuilder: (context,
                                                          error, stackTrace) {
                                                        print(
                                                            'Error loading image: $error');
                                                        return const Icon(
                                                            Icons.broken_image,
                                                            size: 50);
                                                      },
                                                    ),
                                                  ),
                                                ),
                                              )
                                            else
                                              const Expanded(
                                                child: Center(
                                                  child: Icon(Icons.image,
                                                      size: 50,
                                                      color: Colors.grey),
                                                ),
                                              ),
                                            const SizedBox(height: 8),
                                            Text(
                                              item['brand'] ?? '',
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey,
                                              ),
                                            ),
                                            Text(
                                              item['model'] ?? '',
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: Colors.black,
                                              ),
                                            ),
                                            Text(
                                              item['name'] ?? '',
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            Text(
                                              'RM${item['price']?.toStringAsFixed(2) ?? '0.00'}',
                                              style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            Text(
                                              'QTY: ${item['quantity'] ?? 0}',
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            SizedBox(
                                              width: double.infinity,
                                              child: ElevatedButton(
                                                onPressed: () {
                                                  Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (context) =>
                                                          EditPartsPage(
                                                              item: item),
                                                    ),
                                                  );
                                                },
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor:
                                                      Colors.orange,
                                                  foregroundColor: Colors.white,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            5),
                                                  ),
                                                  padding: const EdgeInsets
                                                      .symmetric(vertical: 8),
                                                ),
                                                child: const Text('Edit'),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  if (item['source'] == 'Import')
                                    Positioned(
                                      top: 8,
                                      right: 8,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.blue,
                                          borderRadius:
                                              BorderRadius.circular(5),
                                        ),
                                        child: const Text(
                                          'Import',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              );
                            },
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterButton(String text) {
    return Container(
      margin: const EdgeInsets.only(right: 8.0),
      child: OutlinedButton(
        onPressed: () {
          setState(() {
            _selectedCategoryFilter = text; // Update selected category
            if (text == 'All') {
              _searchQuery = ''; // Clear search query for 'All'
            } else {
              _searchQuery = _inventoryService
                  .standardizeCategory(text); // Standardize category for filter
            }
          });
        },
        style: OutlinedButton.styleFrom(
          side: BorderSide(
              color: _selectedCategoryFilter == text
                  ? Colors.blue
                  : Colors.grey), // Conditional border color
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(20), // Rounded corners for pill shape
          ),
          backgroundColor: _selectedCategoryFilter == text
              ? Colors.blue
              : Colors.transparent, // Conditional background color
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
        child: Text(
          _inventoryService
              .standardizeCategory(text), // Standardize category for display
          style: TextStyle(
              color: _selectedCategoryFilter == text
                  ? Colors.white
                  : Colors.black), // Conditional text color
        ),
      ),
    );
  }
}
