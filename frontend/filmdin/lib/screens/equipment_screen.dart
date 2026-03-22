import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/auth_provider.dart';
import '../providers/equipment_provider.dart';
import 'add_equipment_screen.dart';
import 'equipment_detail_screen.dart';

class EquipmentScreen extends StatefulWidget {
  const EquipmentScreen({super.key});

  @override
  State<EquipmentScreen> createState() => _EquipmentScreenState();
}

class _EquipmentScreenState extends State<EquipmentScreen> {
  final List<String> _categories = [
    'All',
    'Camera',
    'Lens',
    'Lighting',
    'Sound',
    'Drone',
    'Stabilizer',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final equipmentProvider = Provider.of<EquipmentProvider>(
        context,
        listen: false,
      );
      equipmentProvider.fetchAllEquipment(token: authProvider.token ?? '');
    });
  }

  Future<void> _refresh() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await Provider.of<EquipmentProvider>(context, listen: false).fetchAllEquipment(
      token: authProvider.token ?? '',
    );
  }

  IconData _categoryIcon(String category) {
    switch (category) {
      case 'Camera':
        return Icons.camera_alt_outlined;
      case 'Lens':
        return Icons.lens_outlined;
      case 'Lighting':
        return Icons.light_mode_outlined;
      case 'Sound':
        return Icons.mic_outlined;
      case 'Drone':
        return Icons.flight_outlined;
      case 'Stabilizer':
        return Icons.settings_input_component_outlined;
      default:
        return Icons.handyman_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final equipmentProvider = Provider.of<EquipmentProvider>(context);

    return Scaffold(
      backgroundColor: AppTheme.black,
      appBar: AppBar(
        backgroundColor: AppTheme.black,
        title: const Text(
          'Equipment',
          style: TextStyle(
            color: AppTheme.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        children: [
          SizedBox(
            height: 52,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                final isSelected = equipmentProvider.selectedCategory == category;

                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    selected: isSelected,
                    showCheckmark: false,
                    selectedColor: AppTheme.gold,
                    backgroundColor: AppTheme.darkGrey,
                    side: BorderSide.none,
                    label: Text(
                      category,
                      style: TextStyle(
                        color: isSelected ? Colors.black : AppTheme.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    onSelected: (_) async {
                      equipmentProvider.filterByCategory(category);
                      await equipmentProvider.fetchAllEquipment(
                        token: authProvider.token ?? '',
                      );
                    },
                  ),
                );
              },
            ),
          ),
          Expanded(
            child: equipmentProvider.isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppTheme.gold),
                  )
                : equipmentProvider.equipment.isEmpty
                ? RefreshIndicator(
                    color: AppTheme.gold,
                    onRefresh: _refresh,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: const [
                        SizedBox(height: 160),
                        Icon(
                          Icons.handyman_outlined,
                          color: AppTheme.grey,
                          size: 52,
                        ),
                        SizedBox(height: 12),
                        Center(
                          child: Text(
                            'No equipment listings yet',
                            style: TextStyle(
                              color: AppTheme.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        SizedBox(height: 6),
                        Center(
                          child: Text(
                            'Add your first listing and start sharing gear',
                            style: TextStyle(color: AppTheme.grey),
                          ),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    color: AppTheme.gold,
                    onRefresh: _refresh,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: equipmentProvider.equipment.length,
                      itemBuilder: (context, index) {
                        final item = equipmentProvider.equipment[index]
                            as Map<String, dynamic>;
                        final owner = item['owner'] as Map<String, dynamic>? ?? {};
                        final ownerName = owner['name'] ?? 'Unknown';
                        final price = (item['pricePerDay'] as num?)?.toDouble() ?? 0;
                        final category = item['category'] ?? 'Other';

                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => EquipmentDetailScreen(
                                  equipment: item,
                                ),
                              ),
                            );
                          },
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppTheme.darkGrey,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 42,
                                  height: 42,
                                  decoration: BoxDecoration(
                                    color: AppTheme.gold.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    _categoryIcon(category),
                                    color: AppTheme.gold,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item['name'] ?? 'Untitled',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: AppTheme.white,
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '$ownerName • ${item['location'] ?? 'Unknown'}',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: AppTheme.grey,
                                          fontSize: 12,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        price > 0
                                            ? 'Rs ${price.toStringAsFixed(0)} / day'
                                            : 'Free',
                                        style: const TextStyle(
                                          color: AppTheme.gold,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.gold,
        foregroundColor: Colors.black,
        onPressed: () async {
          final created = await Navigator.push<bool>(
            context,
            MaterialPageRoute(builder: (context) => const AddEquipmentScreen()),
          );

          if (created == true && mounted) {
            await _refresh();
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
