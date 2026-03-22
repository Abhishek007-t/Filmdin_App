import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/auth_provider.dart';
import '../providers/job_provider.dart';

class AddJobScreen extends StatefulWidget {
  const AddJobScreen({super.key});

  @override
  State<AddJobScreen> createState() => _AddJobScreenState();
}

class _AddJobScreenState extends State<AddJobScreen> {
  final TextEditingController titleController = TextEditingController();
  final TextEditingController projectNameController = TextEditingController();
  final TextEditingController roleController = TextEditingController();
  final TextEditingController locationController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController requirementsController = TextEditingController();

  String selectedJobType = 'Casting Call';
  String selectedProjectType = 'Short Film';
  String selectedCompensation = 'Negotiable';
  bool isLoading = false;

  final List<String> jobTypes = [
    'Casting Call',
    'Crew Required',
    'Post Production',
    'Equipment',
    'Other',
  ];

  final List<String> projectTypes = [
    'Feature Film',
    'Short Film',
    'Web Series',
    'Documentary',
    'Advertisement',
    'Music Video',
  ];

  final List<String> compensations = [
    'Paid',
    'Unpaid',
    'Negotiable',
  ];

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final jobProvider = Provider.of<JobProvider>(context);

    return Scaffold(
      backgroundColor: AppTheme.black,
      appBar: AppBar(
        backgroundColor: AppTheme.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppTheme.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Post a Job',
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
            _buildLabel('Job Title'),
            const SizedBox(height: 8),
            _buildTextField(
              controller: titleController,
              hint: 'e.g. Lead Actor Needed',
              icon: Icons.work_outline,
            ),

            const SizedBox(height: 20),

            _buildLabel('Job Type'),
            const SizedBox(height: 8),
            _buildDropdown(
              value: selectedJobType,
              items: jobTypes,
              onChanged: (value) =>
                  setState(() => selectedJobType = value!),
            ),

            const SizedBox(height: 20),

            _buildLabel('Project Name'),
            const SizedBox(height: 8),
            _buildTextField(
              controller: projectNameController,
              hint: 'e.g. The Lost Frame',
              icon: Icons.movie_outlined,
            ),

            const SizedBox(height: 20),

            _buildLabel('Project Type'),
            const SizedBox(height: 8),
            _buildDropdown(
              value: selectedProjectType,
              items: projectTypes,
              onChanged: (value) =>
                  setState(() => selectedProjectType = value!),
            ),

            const SizedBox(height: 20),

            _buildLabel('Role Needed'),
            const SizedBox(height: 8),
            _buildTextField(
              controller: roleController,
              hint: 'e.g. Lead Actor Male 25-35',
              icon: Icons.person_outline,
            ),

            const SizedBox(height: 20),

            _buildLabel('Location'),
            const SizedBox(height: 8),
            _buildTextField(
              controller: locationController,
              hint: 'e.g. Mangaluru, Karnataka',
              icon: Icons.location_on_outlined,
            ),

            const SizedBox(height: 20),

            _buildLabel('Description'),
            const SizedBox(height: 8),
            _buildMultilineField(
              controller: descriptionController,
              hint: 'Describe the role and project...',
            ),

            const SizedBox(height: 20),

            _buildLabel('Requirements (Optional)'),
            const SizedBox(height: 8),
            _buildMultilineField(
              controller: requirementsController,
              hint: 'Age, experience, skills needed...',
            ),

            const SizedBox(height: 20),

            _buildLabel('Compensation'),
            const SizedBox(height: 8),
            _buildDropdown(
              value: selectedCompensation,
              items: compensations,
              onChanged: (value) =>
                  setState(() => selectedCompensation = value!),
            ),

            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: isLoading
                    ? null
                    : () async {
                        if (titleController.text.trim().isEmpty ||
                            projectNameController.text.trim().isEmpty ||
                            roleController.text.trim().isEmpty ||
                            locationController.text.trim().isEmpty ||
                            descriptionController.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Please fill all required fields'),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }

                        setState(() => isLoading = true);

                        final success = await jobProvider.createJob(
                          token: authProvider.token ?? '',
                          data: {
                            'title': titleController.text.trim(),
                            'jobType': selectedJobType,
                            'projectName': projectNameController.text.trim(),
                            'projectType': selectedProjectType,
                            'role': roleController.text.trim(),
                            'location': locationController.text.trim(),
                            'description': descriptionController.text.trim(),
                            'requirements': requirementsController.text.trim(),
                            'compensation': selectedCompensation,
                          },
                        );

                        setState(() => isLoading = false);

                        if (success && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Job posted successfully!'),
                              backgroundColor: Colors.green,
                            ),
                          );
                          Navigator.pop(context, true);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                jobProvider.errorMessage ?? 'Failed to post job',
                              ),
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
                  ? const CircularProgressIndicator(color: AppTheme.gold)
                    : const Text(
                        'Post Job',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 40),
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
  }) {
    return TextField(
      controller: controller,
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
          borderSide: const BorderSide(color: AppTheme.gold, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildMultilineField({
    required TextEditingController controller,
    required String hint,
  }) {
    return TextField(
      controller: controller,
      maxLines: 3,
      style: const TextStyle(color: AppTheme.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppTheme.grey),
        filled: true,
        fillColor: AppTheme.darkGrey,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.gold, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String value,
    required List<String> items,
    required Function(String?) onChanged,
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
          icon: const Icon(Icons.keyboard_arrow_down, color: AppTheme.gold),
          items: items.map((item) {
            return DropdownMenuItem(value: item, child: Text(item));
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}