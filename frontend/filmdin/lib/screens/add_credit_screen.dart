import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';

class AddCreditScreen extends StatefulWidget {
  const AddCreditScreen({super.key});

  @override
  State<AddCreditScreen> createState() => _AddCreditScreenState();
}

class _AddCreditScreenState extends State<AddCreditScreen> {
  final TextEditingController projectNameController = TextEditingController();
  final TextEditingController roleController = TextEditingController();
  final TextEditingController yearController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  String selectedProjectType = 'Feature Film';
  bool isLoading = false;

  final List<String> projectTypes = [
    'Feature Film',
    'Short Film',
    'Web Series',
    'Documentary',
    'Advertisement',
    'Music Video',
  ];

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: AppTheme.black,
      appBar: AppBar(
        backgroundColor: AppTheme.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppTheme.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Add Credit',
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
            // Project Name
            _buildLabel('Project Name'),
            const SizedBox(height: 8),
            _buildTextField(
              controller: projectNameController,
              hint: 'e.g. The Dark Knight',
              icon: Icons.movie_outlined,
            ),

            const SizedBox(height: 20),

            // Project Type
            _buildLabel('Project Type'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: AppTheme.darkGrey,
                borderRadius: BorderRadius.circular(12),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: selectedProjectType,
                  isExpanded: true,
                  dropdownColor: AppTheme.darkGrey,
                  style: const TextStyle(color: AppTheme.white),
                  icon: const Icon(
                    Icons.keyboard_arrow_down,
                    color: AppTheme.grey,
                  ),
                  items: projectTypes.map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Text(type),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() => selectedProjectType = value!);
                  },
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Role
            _buildLabel('Your Role'),
            const SizedBox(height: 8),
            _buildTextField(
              controller: roleController,
              hint: 'e.g. Lead Actor, Director',
              icon: Icons.person_outline,
            ),

            const SizedBox(height: 20),

            // Year
            _buildLabel('Year'),
            const SizedBox(height: 8),
            _buildTextField(
              controller: yearController,
              hint: 'e.g. 2024',
              icon: Icons.calendar_today_outlined,
              keyboardType: TextInputType.number,
            ),

            const SizedBox(height: 20),

            // Description
            _buildLabel('Description (Optional)'),
            const SizedBox(height: 8),
            TextField(
              controller: descriptionController,
              maxLines: 3,
              style: const TextStyle(color: AppTheme.white),
              decoration: InputDecoration(
                hintText: 'Brief description of your role...',
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

            // Save Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: isLoading
                    ? null
                    : () async {
                        if (projectNameController.text.trim().isEmpty ||
                            roleController.text.trim().isEmpty ||
                            yearController.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Please fill all required fields'),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }

                        setState(() => isLoading = true);

                        final result = await ApiService.addCredit(
                          token: authProvider.token!,
                          projectName: projectNameController.text.trim(),
                          projectType: selectedProjectType,
                          role: roleController.text.trim(),
                          year: int.parse(yearController.text.trim()),
                          description: descriptionController.text.trim(),
                        );

                        setState(() => isLoading = false);

                        if (result['success'] && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Credit added successfully!'),
                              backgroundColor: Colors.green,
                            ),
                          );
                          Navigator.pop(context, true);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(result['message']),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.gold,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: isLoading
                    ? const CircularProgressIndicator(color: Colors.black)
                    : const Text(
                        'Save Credit',
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
