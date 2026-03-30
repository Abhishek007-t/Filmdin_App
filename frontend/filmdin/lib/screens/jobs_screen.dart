import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/auth_provider.dart';
import '../providers/job_provider.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/loading_skeleton.dart';
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
  final Set<String> _savedJobIds = <String>{};

  String _sortBy = 'Newest';
  String _locationQuery = '';
  String _compensationFilter = 'All';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSavedJobs();
      _fetchJobs();
    });
  }

  Future<void> _loadSavedJobs() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList('saved_job_ids') ?? <String>[];
    if (!mounted) {
      return;
    }
    setState(() {
      _savedJobIds
        ..clear()
        ..addAll(saved);
    });
  }

  Future<void> _persistSavedJobs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('saved_job_ids', _savedJobIds.toList());
  }

  Future<void> _toggleSaveJob(String jobId) async {
    if (jobId.isEmpty) {
      return;
    }

    setState(() {
      if (_savedJobIds.contains(jobId)) {
        _savedJobIds.remove(jobId);
      } else {
        _savedJobIds.add(jobId);
      }
    });

    await _persistSavedJobs();

    if (!mounted) {
      return;
    }

    final isSaved = _savedJobIds.contains(jobId);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(isSaved ? 'Job saved' : 'Job removed from saved'),
        backgroundColor: isSaved ? Colors.green : AppTheme.grey,
      ),
    );
  }

  List<dynamic> _processedJobs(List<dynamic> sourceJobs) {
    final filtered = sourceJobs.whereType<Map<String, dynamic>>().where((job) {
      if (_locationQuery.trim().isNotEmpty) {
        final location = (job['location'] ?? '').toString().toLowerCase();
        if (!location.contains(_locationQuery.trim().toLowerCase())) {
          return false;
        }
      }

      if (_compensationFilter != 'All') {
        final compensation = (job['compensation'] ?? '').toString();
        if (compensation != _compensationFilter) {
          return false;
        }
      }

      return true;
    }).toList();

    filtered.sort((a, b) {
      final aDate = DateTime.tryParse((a['createdAt'] ?? '').toString()) ?? DateTime(2000);
      final bDate = DateTime.tryParse((b['createdAt'] ?? '').toString()) ?? DateTime(2000);

      if (_sortBy == 'Oldest') {
        return aDate.compareTo(bDate);
      }

      if (_sortBy == 'Paid First') {
        final score = {'Paid': 0, 'Negotiable': 1, 'Unpaid': 2};
        final aScore = score[(a['compensation'] ?? '').toString()] ?? 3;
        final bScore = score[(b['compensation'] ?? '').toString()] ?? 3;
        final compResult = aScore.compareTo(bScore);
        if (compResult != 0) return compResult;
      }

      return bDate.compareTo(aDate);
    });

    return filtered;
  }

  String _timeAgo(dynamic value) {
    if (value == null) return 'now';
    final date = DateTime.tryParse(value.toString());
    if (date == null) return 'now';

    final diff = DateTime.now().difference(date);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'just now';
  }

  Future<void> _openFilterSheet() async {
    final locationController = TextEditingController(text: _locationQuery);
    var localCompensation = _compensationFilter;

    await showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.darkGrey,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) => Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 16,
              bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 16,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Filter Jobs',
                  style: TextStyle(
                    color: AppTheme.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: locationController,
                  style: const TextStyle(color: AppTheme.white),
                  decoration: InputDecoration(
                    hintText: 'Location contains...',
                    hintStyle: const TextStyle(color: AppTheme.grey),
                    filled: true,
                    fillColor: AppTheme.black,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: localCompensation,
                  dropdownColor: AppTheme.black,
                  style: const TextStyle(color: AppTheme.white),
                  decoration: InputDecoration(
                    labelText: 'Compensation',
                    labelStyle: const TextStyle(color: AppTheme.grey),
                    filled: true,
                    fillColor: AppTheme.black,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'All', child: Text('All')),
                    DropdownMenuItem(value: 'Paid', child: Text('Paid')),
                    DropdownMenuItem(value: 'Negotiable', child: Text('Negotiable')),
                    DropdownMenuItem(value: 'Unpaid', child: Text('Unpaid')),
                  ],
                  onChanged: (value) {
                    if (value == null) return;
                    setSheetState(() {
                      localCompensation = value;
                    });
                  },
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          setState(() {
                            _locationQuery = '';
                            _compensationFilter = 'All';
                          });
                          Navigator.pop(sheetContext);
                        },
                        child: const Text('Reset'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.gold,
                          foregroundColor: Colors.black,
                        ),
                        onPressed: () {
                          setState(() {
                            _locationQuery = locationController.text.trim();
                            _compensationFilter = localCompensation;
                          });
                          Navigator.pop(sheetContext);
                        },
                        child: const Text('Apply'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
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
    final jobs = _processedJobs(jobProvider.jobs);

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
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 2, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: AppTheme.darkGrey,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _sortBy,
                          dropdownColor: AppTheme.darkGrey,
                          style: const TextStyle(color: AppTheme.white),
                          items: const [
                            DropdownMenuItem(value: 'Newest', child: Text('Sort: Newest')),
                            DropdownMenuItem(value: 'Oldest', child: Text('Sort: Oldest')),
                            DropdownMenuItem(value: 'Paid First', child: Text('Sort: Paid First')),
                          ],
                          onChanged: (value) {
                            if (value == null) return;
                            setState(() {
                              _sortBy = value;
                            });
                          },
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  OutlinedButton.icon(
                    onPressed: _openFilterSheet,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppTheme.gold),
                    ),
                    icon: const Icon(Icons.tune, color: AppTheme.gold, size: 18),
                    label: const Text('Filter', style: TextStyle(color: AppTheme.gold)),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 52,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: _filters.length,
                separatorBuilder: (context, index) => const SizedBox(width: 8),
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
                  ? const SkeletonList(itemCount: 5, itemHeight: 120)
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
                                          color: AppTheme.gold.withValues(alpha: 0.15),
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
                                      const SizedBox(height: 4),
                                      Text(
                                        _timeAgo(job?['createdAt']),
                                        style: const TextStyle(
                                          color: AppTheme.grey,
                                          fontSize: 12,
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
                                                        .withValues(alpha: 0.15),
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
                                          IconButton(
                                            visualDensity: VisualDensity.compact,
                                            onPressed: () => _toggleSaveJob(jobId),
                                            icon: Icon(
                                              _savedJobIds.contains(jobId)
                                                  ? Icons.bookmark
                                                  : Icons.bookmark_border,
                                              color: AppTheme.gold,
                                            ),
                                          ),
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
