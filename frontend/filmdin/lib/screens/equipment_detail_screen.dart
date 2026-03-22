import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class EquipmentDetailScreen extends StatelessWidget {
  final Map<String, dynamic> equipment;

  const EquipmentDetailScreen({
    super.key,
    required this.equipment,
  });

  @override
  Widget build(BuildContext context) {
    final owner = equipment['owner'] as Map<String, dynamic>? ?? {};
    final ownerName = owner['name'] ?? 'Unknown';
    final ownerRole = owner['role'] ?? 'Filmmaker';
    final name = equipment['name'] ?? 'Equipment';
    final category = equipment['category'] ?? 'Other';
    final condition = equipment['condition'] ?? 'Good';
    final availability = equipment['availability'] ?? 'Available';
    final location = equipment['location'] ?? 'Not specified';
    final description = equipment['description'] ?? '';
    final pricePerDay = (equipment['pricePerDay'] as num?)?.toDouble() ?? 0;

    return Scaffold(
      backgroundColor: AppTheme.black,
      appBar: AppBar(
        backgroundColor: AppTheme.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppTheme.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              name,
              style: const TextStyle(
                color: AppTheme.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildBadge(category, AppTheme.gold.withOpacity(0.2), AppTheme.gold),
            const SizedBox(height: 20),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.darkGrey,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: AppTheme.gold,
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: Center(
                      child: Text(
                        ownerName.toString().isNotEmpty
                            ? ownerName.toString()[0].toUpperCase()
                            : 'F',
                        style: const TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ownerName,
                        style: const TextStyle(
                          color: AppTheme.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        ownerRole,
                        style: const TextStyle(
                          color: AppTheme.grey,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildBadge('Condition: $condition', AppTheme.darkGrey, AppTheme.white),
                _buildBadge('Availability: $availability', AppTheme.darkGrey, AppTheme.white),
                _buildBadge(
                  pricePerDay > 0 ? 'Rs ${pricePerDay.toStringAsFixed(0)}/day' : 'Free',
                  AppTheme.darkGrey,
                  AppTheme.white,
                ),
              ],
            ),

            const SizedBox(height: 20),
            Row(
              children: [
                const Icon(
                  Icons.location_on_outlined,
                  color: AppTheme.grey,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    location,
                    style: const TextStyle(
                      color: AppTheme.white,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),
            const Text(
              'Description',
              style: TextStyle(
                color: AppTheme.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              description.toString().isNotEmpty ? description : 'No description provided.',
              style: const TextStyle(
                color: AppTheme.grey,
                fontSize: 14,
                height: 1.5,
              ),
            ),

            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Contact flow will be added soon'),
                      backgroundColor: Colors.green,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.gold,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Contact Owner',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge(String text, Color backgroundColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
