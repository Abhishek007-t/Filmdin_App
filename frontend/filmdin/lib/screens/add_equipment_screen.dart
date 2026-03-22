import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/auth_provider.dart';
import '../providers/equipment_provider.dart';

class AddEquipmentScreen extends StatefulWidget {
  const AddEquipmentScreen({super.key});

  @override
  State<AddEquipmentScreen> createState() => _AddEquipmentScreenState();
}

class _AddEquipmentScreenState extends State<AddEquipmentScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  String _selectedCategory = 'Camera';
  String _selectedCondition = 'Excellent';
  String _selectedRentalType = 'Rent';

  final List<String> _categories = [
    'Camera',
    'Lens',
    'Lighting',
    'Sound',
    'Drone',
    'Stabilizer',
    'Other',
  ];

  final List<String> _conditions = ['Excellent', 'Good', 'Fair'];
  final List<String> _rentalTypes = ['Rent', 'Lend', 'Both'];

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  bool get _showPriceField {
    return _selectedRentalType == 'Rent' || _selectedRentalType == 'Both';
  }

  Future<void> _saveEquipment() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final equipmentProvider = Provider.of<EquipmentProvider>(
      context,
      listen: false,
    );

    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Equipment name is required'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_showPriceField &&
        _priceController.text.trim().isNotEmpty &&
        double.tryParse(_priceController.text.trim()) == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Price per day must be a valid number'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final data = {
      'name': _nameController.text.trim(),
      'category': _selectedCategory,
      'condition': _selectedCondition,
      'rentalType': _selectedRentalType,
      'pricePerDay': _showPriceField
          ? double.tryParse(_priceController.text.trim()) ?? 0
          : 0,
      'location': _locationController.text.trim(),
      'description': _descriptionController.text.trim(),
    };

    final success = await equipmentProvider.addEquipment(
      token: authProvider.token ?? '',
      data: data,
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Equipment listed successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to list equipment'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final equipmentProvider = Provider.of<EquipmentProvider>(context);

    return Scaffold(
      backgroundColor: AppTheme.black,
      appBar: AppBar(
        backgroundColor: AppTheme.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppTheme.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'List Equipment',
          style: TextStyle(
            color: AppTheme.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLabel('Equipment Name'),
            const SizedBox(height: 8),
            _buildTextField(
              controller: _nameController,
              hint: 'e.g. Sony A7III Camera',
              icon: Icons.camera_alt_outlined,
            ),

            const SizedBox(height: 20),

            _buildLabel('Category'),
            const SizedBox(height: 8),
            _buildDropdown(
              value: _selectedCategory,
              items: _categories,
              onChanged: (value) {
                setState(() => _selectedCategory = value!);
              },
            ),

            const SizedBox(height: 20),

            _buildLabel('Condition'),
            const SizedBox(height: 8),
            _buildDropdown(
              value: _selectedCondition,
              items: _conditions,
              onChanged: (value) {
                setState(() => _selectedCondition = value!);
              },
            ),

            const SizedBox(height: 20),

            _buildLabel('Rental Type'),
            const SizedBox(height: 8),
            _buildDropdown(
              value: _selectedRentalType,
              items: _rentalTypes,
              onChanged: (value) {
                setState(() => _selectedRentalType = value!);
              },
            ),

            if (_showPriceField) ...[
              const SizedBox(height: 20),
              _buildLabel('Price Per Day'),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _priceController,
                hint: 'e.g. 2500',
                icon: Icons.currency_rupee,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
              ),
            ],

            const SizedBox(height: 20),

            _buildLabel('Location'),
            const SizedBox(height: 8),
            _buildTextField(
              controller: _locationController,
              hint: 'e.g. Mumbai',
              icon: Icons.location_on_outlined,
            ),

            const SizedBox(height: 20),

            _buildLabel('Description'),
            const SizedBox(height: 8),
            TextField(
              controller: _descriptionController,
              maxLines: 4,
              style: const TextStyle(color: AppTheme.white),
              decoration: InputDecoration(
                hintText: 'Add details about this equipment...',
                hintStyle: const TextStyle(color: AppTheme.grey),
                filled: true,
                fillColor: AppTheme.darkGrey,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: AppTheme.gold,
                    width: 1.5,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: equipmentProvider.isLoading ? null : _saveEquipment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.gold,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: equipmentProvider.isLoading
                    ? const CircularProgressIndicator(color: AppTheme.gold)
                    : const Text(
                        'Save',
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

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: AppTheme.white,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _buildDropdown({
    required String value,
    required List<String> items,
    required void Function(String?) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppTheme.darkGrey,
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          dropdownColor: AppTheme.darkGrey,
          style: const TextStyle(color: AppTheme.white),
          icon: const Icon(Icons.keyboard_arrow_down, color: AppTheme.grey),
          items: items.map((item) {
            return DropdownMenuItem(
              value: item,
              child: Text(item),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(color: AppTheme.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppTheme.grey),
        filled: true,
        fillColor: AppTheme.darkGrey,
        prefixIcon: Icon(icon, color: AppTheme.grey),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: AppTheme.gold,
            width: 1.5,
          ),
        ),
      ),
    );
  }
}
