import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/job_provider.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import 'add_job_screen.dart';
import 'job_detail_screen.dart';

bool isOwner(dynamic ownerId, String? currentUserId) {
  if (currentUserId == null) return false;
  if (ownerId == null) return false;
  if (ownerId is Map) {
    return (ownerId['_id'] ?? ownerId['id'])?.toString() == currentUserId;
  }
  return ownerId.toString() == currentUserId;
}

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
    final authProvider = Provider.of<AuthProvider>(context);
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
                              final isOwnerJob = isOwner(
                                job?['postedBy'],
                                authProvider.user?['id']?.toString(),
                              );

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
                                          if (isOwnerJob)
                                            PopupMenuButton<String>(
                                              icon: const Icon(
                                                Icons.more_vert,
                                                color: AppTheme.grey,
                                              ),
                                              color: AppTheme.darkGrey,
                                              onSelected: (value) async {
                                                if (value == 'close') {
                                                  final result = await ApiService.closeJob(
                                                    token: authProvider.token ?? '',
                                                    jobId: jobId,
                                                  );

                                                  if (!context.mounted) {
                                                    return;
                                                  }

                                                  if (result['success'] == true) {
                                                    await _fetchJobs();
                                                    if (!context.mounted) {
                                                      return;
                                                    }
                                                    ScaffoldMessenger.of(context)
                                                        .showSnackBar(
                                                      const SnackBar(
                                                        content: Text(
                                                          'Job closed successfully',
                                                        ),
                                                        backgroundColor: Colors.green,
                                                      ),
                                                    );
                                                  } else {
                                                    ScaffoldMessenger.of(context)
                                                        .showSnackBar(
                                                      SnackBar(
                                                        content: Text(
                                                          (result['message'] ??
                                                                  'Failed to close job')
                                                              .toString(),
                                                        ),
                                                        backgroundColor: Colors.red,
                                                      ),
                                                    );
                                                  }
                                                  return;
                                                }

                                                if (value == 'delete') {
                                                  final shouldDelete = await showDialog<bool>(
                                                    context: context,
                                                    builder: (dialogContext) => AlertDialog(
                                                      backgroundColor:
                                                          AppTheme.darkGrey,
                                                      title: const Text(
                                                        'Confirm Delete',
                                                        style: TextStyle(
                                                          color: AppTheme.white,
                                                        ),
                                                      ),
                                                      content: const Text(
                                                        'Are you sure you want to delete this?',
                                                        style: TextStyle(
                                                          color: AppTheme.grey,
                                                        ),
                                                      ),
                                                      actions: [
                                                        TextButton(
                                                          onPressed: () =>
                                                              Navigator.pop(
                                                            dialogContext,
                                                            false,
                                                          ),
                                                          child: const Text(
                                                            'Cancel',
                                                            style: TextStyle(
                                                              color: AppTheme.grey,
                                                            ),
                                                          ),
                                                        ),
                                                        TextButton(
                                                          onPressed: () =>
                                                              Navigator.pop(
                                                            dialogContext,
                                                            true,
                                                          ),
                                                          child: const Text(
                                                            'Delete',
                                                            style: TextStyle(
                                                              color: Colors.red,
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  );

                                                  if (shouldDelete != true) {
                                                    return;
                                                  }

                                                  final result =
                                                      await ApiService.deleteJob(
                                                    token: authProvider.token ?? '',
                                                    jobId: jobId,
                                                  );

                                                  if (!context.mounted) {
                                                    return;
                                                  }

                                                  if (result['success'] == true) {
                                                    await _fetchJobs();
                                                    if (!context.mounted) {
                                                      return;
                                                    }
                                                    ScaffoldMessenger.of(context)
                                                        .showSnackBar(
                                                      const SnackBar(
                                                        content: Text(
                                                          'Job deleted successfully',
                                                        ),
                                                        backgroundColor: Colors.green,
                                                      ),
                                                    );
                                                  } else {
                                                    ScaffoldMessenger.of(context)
                                                        .showSnackBar(
                                                      SnackBar(
                                                        content: Text(
                                                          (result['message'] ??
                                                                  'Failed to delete job')
                                                              .toString(),
                                                        ),
                                                        backgroundColor: Colors.red,
                                                      ),
                                                    );
                                                  }
                                                }
                                              },
                                              itemBuilder: (context) => const [
                                                PopupMenuItem<String>(
                                                  value: 'close',
                                                  child: Text(
                                                    'Close Job',
                                                    style: TextStyle(
                                                      color: AppTheme.white,
                                                    ),
                                                  ),
                                                ),
                                                PopupMenuItem<String>(
                                                  value: 'delete',
                                                  child: Text(
                                                    'Delete',
                                                    style: TextStyle(
                                                      color: Colors.red,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
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
