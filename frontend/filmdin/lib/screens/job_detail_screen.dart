import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';

class JobDetailScreen extends StatefulWidget {
  final String jobId;
  const JobDetailScreen({super.key, required this.jobId});

  @override
  State<JobDetailScreen> createState() => _JobDetailScreenState();
}

class _JobDetailScreenState extends State<JobDetailScreen> {
  Map<String, dynamic>? jobData;
  bool isLoading = true;
  bool isApplying = false;
  bool hasApplied = false;

  @override
  void initState() {
    super.initState();
    _loadJob();
  }

  Future<void> _loadJob() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final result = await ApiService.getJobById(
      token: authProvider.token ?? '',
      jobId: widget.jobId,
    );

    if (result['success']) {
      final job = result['data']['job'];
      final applicants = job['applicants'] as List? ?? [];
      final userId = authProvider.user?['_id'] ?? authProvider.user?['id'];
      setState(() {
        jobData = job;
        hasApplied = applicants.any(
          (a) => (a['_id'] ?? a['id']) == userId,
        );
        isLoading = false;
      });
    } else {
      setState(() => isLoading = false);
    }
  }

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
          'Job Details',
          style: TextStyle(
            color: AppTheme.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.gold),
            )
          : jobData == null
              ? const Center(
                  child: Text(
                    'Job not found',
                    style: TextStyle(color: AppTheme.white),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Job Type Badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.gold.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppTheme.gold.withOpacity(0.3),
                          ),
                        ),
                        child: Text(
                          jobData!['jobType'] ?? '',
                          style: const TextStyle(
                            color: AppTheme.gold,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Title
                      Text(
                        jobData!['title'] ?? '',
                        style: const TextStyle(
                          color: AppTheme.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 8),

                      // Project Name
                      Text(
                        '${jobData!['projectName']} • ${jobData!['projectType'] ?? ''}',
                        style: const TextStyle(
                          color: AppTheme.grey,
                          fontSize: 14,
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Info Cards
                      _buildInfoRow(
                        Icons.person_outline,
                        'Role',
                        jobData!['role'] ?? '',
                      ),
                      const SizedBox(height: 12),
                      _buildInfoRow(
                        Icons.location_on_outlined,
                        'Location',
                        jobData!['location'] ?? '',
                      ),
                      const SizedBox(height: 12),
                      _buildInfoRow(
                        Icons.attach_money,
                        'Compensation',
                        jobData!['compensation'] ?? '',
                      ),
                      const SizedBox(height: 12),
                      _buildInfoRow(
                        Icons.people_outline,
                        'Applicants',
                        '${(jobData!['applicants'] as List? ?? []).length} applied',
                      ),

                      const SizedBox(height: 24),

                      // Description
                      const Text(
                        'Description',
                        style: TextStyle(
                          color: AppTheme.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        jobData!['description'] ?? '',
                        style: const TextStyle(
                          color: AppTheme.grey,
                          fontSize: 14,
                          height: 1.6,
                        ),
                      ),

                      if (jobData!['requirements'] != null &&
                          jobData!['requirements'].isNotEmpty) ...[
                        const SizedBox(height: 24),
                        const Text(
                          'Requirements',
                          style: TextStyle(
                            color: AppTheme.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          jobData!['requirements'],
                          style: const TextStyle(
                            color: AppTheme.grey,
                            fontSize: 14,
                            height: 1.6,
                          ),
                        ),
                      ],

                      const SizedBox(height: 24),

                      // Posted By
                      const Text(
                        'Posted By',
                        style: TextStyle(
                          color: AppTheme.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.darkGrey,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: AppTheme.gold,
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: Center(
                                child: Text(
                                  (jobData!['postedBy']?['name'] ?? 'F')[0]
                                      .toUpperCase(),
                                  style: const TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  jobData!['postedBy']?['name'] ?? '',
                                  style: const TextStyle(
                                    color: AppTheme.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                                Text(
                                  jobData!['postedBy']?['role'] ?? '',
                                  style: const TextStyle(
                                    color: AppTheme.gold,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Apply Button
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: hasApplied || isApplying
                              ? null
                              : () async {
                                  setState(() => isApplying = true);

                                  final result = await ApiService.applyToJob(
                                    token: authProvider.token ?? '',
                                    jobId: widget.jobId,
                                  );

                                  setState(() => isApplying = false);

                                  if (result['success'] && context.mounted) {
                                    setState(() => hasApplied = true);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Applied successfully!'),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                  } else if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          result['message'] ?? 'Failed to apply',
                                        ),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                hasApplied ? AppTheme.grey : AppTheme.gold,
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: isApplying
                              ? const CircularProgressIndicator(
                                  color: AppTheme.gold,
                                )
                              : Text(
                                  hasApplied ? 'Already Applied' : 'Apply Now',
                                  style: const TextStyle(
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

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.gold, size: 20),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(color: AppTheme.grey, fontSize: 12),
            ),
            Text(
              value,
              style: const TextStyle(
                color: AppTheme.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }
}