import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/job_provider.dart';
import '../theme/app_theme.dart';
import 'add_job_screen.dart';
import 'job_detail_screen.dart';

class JobsScreen extends StatefulWidget {
  const JobsScreen({super.key});

  @override
  State<JobsScreen> createState() => _JobsScreenState();
}

class _JobsScreenState extends State<JobsScreen> {
  final List<String> _filters = const [
    'All',
    'Casting Call',
    'Crew Required',
    'Post Production',
    'Equipment',
    'Other',
  ];

  final Set<String> _applyingJobs = <String>{};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchJobs();
    });
  }

  Future<void> _fetchJobs() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final jobProvider = Provider.of<JobProvider>(context, listen: false);
    final selected = jobProvider.selectedJobType;

    await jobProvider.fetchAllJobs(
      token: authProvider.token ?? '',
      jobType: selected == 'All' ? null : selected,
    );
  }

  Future<void> _applyToJob(String jobId) async {
    if (_applyingJobs.contains(jobId)) {
      return;
    }

    setState(() {
      _applyingJobs.add(jobId);
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final jobProvider = Provider.of<JobProvider>(context, listen: false);

    final success = await jobProvider.applyToJob(
      token: authProvider.token ?? '',
      jobId: jobId,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _applyingJobs.remove(jobId);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Applied successfully!'
              : (jobProvider.errorMessage ?? 'Failed to apply'),
        ),
        backgroundColor: success ? Colors.green : Colors.red,
      ),
    );

    if (success) {
      await _fetchJobs();
    }
  }

  @override
  Widget build(BuildContext context) {
    final jobProvider = Provider.of<JobProvider>(context);
    final jobs = jobProvider.jobs;

    return Scaffold(
      backgroundColor: AppTheme.black,
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.darkGrey,
        onPressed: () async {
          final created = await Navigator.push<bool>(
            context,
            MaterialPageRoute(builder: (_) => const AddJobScreen()),
          );

          if (created == true && mounted) {
            await _fetchJobs();
          }
        },
        child: const Icon(Icons.add, color: AppTheme.gold),
      ),
      body: SafeArea(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Jobs and Casting',
                  style: TextStyle(
                    color: AppTheme.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            SizedBox(
              height: 52,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: _filters.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final type = _filters[index];
                  final selected = jobProvider.selectedJobType == type;

                  return FilterChip(
                    showCheckmark: false,
                    label: Text(
                      type,
                      style: TextStyle(
                        color: selected ? AppTheme.black : AppTheme.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    selected: selected,
                    onSelected: (_) async {
                      jobProvider.filterByType(type);
                      await _fetchJobs();
                    },
                    selectedColor: AppTheme.gold,
                    backgroundColor: AppTheme.darkGrey,
                    side: BorderSide.none,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: jobProvider.isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: AppTheme.gold),
                    )
                  : jobs.isEmpty
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.work_off_outlined,
                                color: AppTheme.grey,
                                size: 52,
                              ),
                              SizedBox(height: 10),
                              Text(
                                'No jobs posted yet',
                                style: TextStyle(
                                  color: AppTheme.grey,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          color: AppTheme.gold,
                          onRefresh: _fetchJobs,
                          child: ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 4, 16, 90),
                            itemCount: jobs.length,
                            itemBuilder: (context, index) {
                              final job = jobs[index] as Map<String, dynamic>?;
                              final jobId = (job?['_id'] ?? '').toString();
                              final title = (job?['title'] ?? '').toString();
                              final jobType = (job?['jobType'] ?? '').toString();
                              final projectName =
                                  (job?['projectName'] ?? '').toString();
                              final location =
                                  (job?['location'] ?? 'Unknown').toString();
                              final compensation =
                                  (job?['compensation'] ?? 'Negotiable')
                                      .toString();

                              return GestureDetector(
                                onTap: () {
                                  if (jobId.isEmpty) {
                                    return;
                                  }
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => JobDetailScreen(
                                        jobId: jobId,
                                      ),
                                    ),
                                  );
                                },
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: AppTheme.darkGrey,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppTheme.gold.withOpacity(0.15),
                                          borderRadius:
                                              BorderRadius.circular(14),
                                        ),
                                        child: Text(
                                          jobType,
                                          style: const TextStyle(
                                            color: AppTheme.gold,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      Text(
                                        title,
                                        style: const TextStyle(
                                          color: AppTheme.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        projectName,
                                        style: const TextStyle(
                                          color: AppTheme.grey,
                                          fontSize: 13,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Row(
                                              children: [
                                                const Icon(
                                                  Icons.location_on_outlined,
                                                  color: AppTheme.grey,
                                                  size: 16,
                                                ),
                                                const SizedBox(width: 4),
                                                Flexible(
                                                  child: Text(
                                                    location,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: const TextStyle(
                                                      color: AppTheme.grey,
                                                      fontSize: 13,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                    horizontal: 8,
                                                    vertical: 3,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: Colors.green
                                                        .withOpacity(0.15),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                      10,
                                                    ),
                                                  ),
                                                  child: Text(
                                                    compensation,
                                                    style: const TextStyle(
                                                      color: Colors.green,
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          SizedBox(
                                            height: 36,
                                            child: ElevatedButton(
                                              onPressed: jobId.isEmpty
                                                  ? null
                                                  : () => _applyToJob(jobId),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: AppTheme.gold,
                                                foregroundColor: AppTheme.black,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                ),
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  horizontal: 14,
                                                ),
                                              ),
                                              child: _applyingJobs.contains(jobId)
                                                  ? const SizedBox(
                                                      width: 16,
                                                      height: 16,
                                                      child:
                                                          CircularProgressIndicator(
                                                        strokeWidth: 2,
                                                        color: AppTheme.gold,
                                                      ),
                                                    )
                                                  : const Text(
                                                      'Apply',
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                            ),
                                          ),
                                        ],
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
      ),
    );
  }
}
