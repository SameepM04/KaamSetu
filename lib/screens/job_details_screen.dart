import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/job_categories.dart';
import '../data/job_previews.dart';
import '../repositories/jobs_repository.dart';
import '../theme/app_colors.dart';
import '../widgets/home/category_icon.dart';
import '../widgets/jobs/application_status_chip.dart';
import '../widgets/jobs/bookmark_button.dart';

/// Full job view shared by every job listing surface.
class JobDetailsScreen extends StatefulWidget {
  const JobDetailsScreen({super.key, required this.job, this.heroTag});

  final JobPreview job;
  final String? heroTag;

  @override
  State<JobDetailsScreen> createState() => _JobDetailsScreenState();
}

class _JobDetailsScreenState extends State<JobDetailsScreen> {
  final _repo = JobsRepository.instance;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _repo.ensureApplicationsListening();
  }

  Future<void> _confirmApply() async {
    final approved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Apply for this job?'),
        content: const Text('Confirm that you want to apply.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Apply'),
          ),
        ],
      ),
    );
    if (approved != true || _submitting) return;
    setState(() => _submitting = true);
    try {
      final created = await _repo.applyForJob(widget.job);
      if (!mounted) return;
      _showMessage(created
          ? 'Application sent successfully.'
          : 'You have already applied for this job.');
    } on FirebaseException catch (error) {
      if (!mounted) return;
      _showMessage(_firestoreMessage(error));
    } catch (_) {
      if (mounted) _showMessage('Couldn\'t apply right now. Please try again.');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  String _firestoreMessage(FirebaseException error) => switch (error.code) {
        'permission-denied' =>
          'You do not have permission to apply for this job.',
        'unavailable' =>
          'You appear to be offline. Please try again when connected.',
        _ => 'Couldn\'t apply right now. Please try again.',
      };

  void _showMessage(String message) =>
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );

  void _contactEmployer() => _showMessage(
      'Contact details will be shared after your application is reviewed.');

  void _reportJob() => showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Report job'),
          content:
              const Text('Thank you. Our team will review this job listing.'),
          actions: [
            FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Done')),
          ],
        ),
      );

  Future<void> _shareJob() async {
    await Clipboard.setData(
        ClipboardData(text: '${widget.job.title} at ${widget.job.employer}'));
    if (mounted) _showMessage('Job details copied to your clipboard.');
  }

  @override
  Widget build(BuildContext context) {
    final job = widget.job;
    final category = job.category;
    return Scaffold(
      backgroundColor: AppColors.mist,
      appBar: AppBar(
        backgroundColor: AppColors.mist,
        foregroundColor: AppColors.navy,
        title: const Text('Job details',
            style: TextStyle(fontWeight: FontWeight.w800)),
        actions: [
          IconButton(
              onPressed: _shareJob,
              icon: const Icon(Icons.ios_share_rounded),
              tooltip: 'Share job'),
          Padding(
              padding: const EdgeInsets.only(right: 8),
              child: BookmarkButton(job: job, size: 23)),
        ],
      ),
      body: SafeArea(
        top: false,
        child: ValueListenableBuilder<Map<String, ApplicationEntry>>(
          valueListenable: _repo.applications,
          builder: (context, entries, _) {
            final status = entries[job.id]?.status;
            return CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 124),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _Header(
                        job: job,
                        category: category,
                        status: status,
                        heroTag: widget.heroTag ?? 'job-details-${job.id}',
                      ),
                      const SizedBox(height: 16),
                      _DetailsGrid(job: job),
                      const SizedBox(height: 20),
                      _SectionCard(
                          title: 'About this job',
                          child: Text(job.description ?? _description(job),
                              style: _bodyStyle)),
                      const SizedBox(height: 16),
                      _SectionCard(
                          title: 'Skills needed',
                          child: Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children:
                                  job.skills.map(_SkillChip.new).toList())),
                      const SizedBox(height: 16),
                      _SectionCard(
                          title: 'Responsibilities',
                          child: _BulletList(items: _responsibilities(job))),
                      const SizedBox(height: 16),
                      _SectionCard(
                          title: 'Requirements',
                          child: _BulletList(items: _requirements(job))),
                      const SizedBox(height: 16),
                      _ContactCard(
                          employer: job.employer, onContact: _contactEmployer),
                      const SizedBox(height: 10),
                      TextButton.icon(
                          onPressed: _reportJob,
                          icon: const Icon(Icons.flag_outlined),
                          label: const Text('Report job')),
                    ]),
                  ),
                ),
              ],
            );
          },
        ),
      ),
      bottomNavigationBar:
          ValueListenableBuilder<Map<String, ApplicationEntry>>(
        valueListenable: _repo.applications,
        builder: (context, entries, _) {
          final status = entries[job.id]?.status;
          final applied = status != null;
          return SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
              child: SizedBox(
                height: 52,
                child: FilledButton.icon(
                  onPressed: applied || _submitting ? null : _confirmApply,
                  icon:
                      Icon(applied ? Icons.check_rounded : Icons.send_rounded),
                  label: Text(_submitting
                      ? 'Applying...'
                      : applied
                          ? 'Applied'
                          : 'Apply now'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.blue,
                    disabledBackgroundColor: Colors.blueGrey.shade200,
                    disabledForegroundColor: Colors.white,
                    textStyle: const TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 15),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

const _bodyStyle = TextStyle(
    color: AppColors.inkMuted,
    fontSize: 13.5,
    height: 1.45,
    fontWeight: FontWeight.w500);

class _Header extends StatelessWidget {
  const _Header(
      {required this.job,
      required this.category,
      required this.status,
      required this.heroTag});
  final JobPreview job;
  final JobCategory category;
  final ApplicationStatus? status;
  final String heroTag;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColors.line)),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Hero(
              tag: heroTag,
              child: JobCategoryIcon(
                  category: category,
                  size: 72,
                  borderRadius: 19,
                  iconSize: 30)),
          const SizedBox(width: 14),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(job.title,
                    style: const TextStyle(
                        color: AppColors.navy,
                        fontSize: 20,
                        fontWeight: FontWeight.w800)),
                const SizedBox(height: 5),
                Text(job.employer,
                    style: const TextStyle(
                        color: AppColors.inkMuted,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                if (job.verifiedEmployer) const _VerifiedBadge(),
                if (status case final appliedStatus?)
                  Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: ApplicationStatusChip(status: appliedStatus)),
              ])),
        ]),
      );
}

class _VerifiedBadge extends StatelessWidget {
  const _VerifiedBadge();
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
            color: AppColors.green.withValues(alpha: .14),
            borderRadius: BorderRadius.circular(8)),
        child: const Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.verified_rounded, size: 15, color: AppColors.green),
          SizedBox(width: 4),
          Text('Verified employer',
              style: TextStyle(
                  color: AppColors.green,
                  fontSize: 11,
                  fontWeight: FontWeight.w800)),
        ]),
      );
}

class _DetailsGrid extends StatelessWidget {
  const _DetailsGrid({required this.job});
  final JobPreview job;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth > 600
              ? (constraints.maxWidth - 12) / 2
              : constraints.maxWidth;
          final items = [
            (Icons.currency_rupee_rounded, job.pay, 'Salary'),
            (
              Icons.place_rounded,
              '${job.location} · ${job.distanceKm}',
              'Location'
            ),
            (
              Icons.work_outline_rounded,
              JobTypeMapper.displayName(job.jobType),
              'Job type'
            ),
            (
              Icons.workspace_premium_outlined,
              ExperienceLevelMapper.displayName(job.experienceLevel),
              'Experience'
            ),
            (
              Icons.schedule_rounded,
              job.workingHours ?? _workingHours(job),
              'Working hours'
            ),
            (
              Icons.calendar_month_rounded,
              job.duration ?? _duration(job),
              'Duration'
            ),
            (Icons.history_rounded, job.postedAgo, 'Posted'),
          ];
          return Wrap(spacing: 12, runSpacing: 12, children: [
            for (final item in items)
              SizedBox(
                  width: width,
                  child:
                      _InfoTile(icon: item.$1, value: item.$2, label: item.$3))
          ]);
        },
      );
}

class _InfoTile extends StatelessWidget {
  const _InfoTile(
      {required this.icon, required this.value, required this.label});
  final IconData icon;
  final String value;
  final String label;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.line)),
        child: Row(children: [
          Icon(icon, color: AppColors.blue, size: 20),
          const SizedBox(width: 10),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(label,
                    style: const TextStyle(
                        color: AppColors.inkMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(value,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: AppColors.navy,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800)),
              ])),
        ]),
      );
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});
  final String title;
  final Widget child;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.line)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title,
              style: const TextStyle(
                  color: AppColors.navy,
                  fontSize: 16,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          child,
        ]),
      );
}

class _SkillChip extends StatelessWidget {
  const _SkillChip(this.label);
  final String label;
  @override
  Widget build(BuildContext context) => Chip(
      label: Text(label),
      backgroundColor: AppColors.paleBlue,
      side: BorderSide.none,
      labelStyle: const TextStyle(
          color: AppColors.blue, fontSize: 12, fontWeight: FontWeight.w700));
}

class _BulletList extends StatelessWidget {
  const _BulletList({required this.items});
  final List<String> items;
  @override
  Widget build(BuildContext context) => Column(children: [
        for (final item in items)
          Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child:
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Padding(
                    padding: EdgeInsets.only(top: 5),
                    child: Icon(Icons.circle, size: 6, color: AppColors.blue)),
                const SizedBox(width: 9),
                Expanded(child: Text(item, style: _bodyStyle))
              ]))
      ]);
}

class _ContactCard extends StatelessWidget {
  const _ContactCard({required this.employer, required this.onContact});
  final String employer;
  final VoidCallback onContact;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
            color: AppColors.paleBlue, borderRadius: BorderRadius.circular(20)),
        child: Row(children: [
          const CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(Icons.business_rounded, color: AppColors.blue)),
          const SizedBox(width: 12),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                const Text('Contact employer',
                    style: TextStyle(
                        color: AppColors.navy, fontWeight: FontWeight.w800)),
                Text(employer,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _bodyStyle)
              ])),
          TextButton(onPressed: onContact, child: const Text('Contact')),
        ]),
      );
}

String _workingHours(JobPreview job) =>
    job.jobType == JobType.partTime ? '4–6 hours / day' : '8 hours / day';
String _duration(JobPreview job) =>
    job.jobType == JobType.temporary ? '1–3 days' : 'Ongoing';
String _description(JobPreview job) =>
    '${job.employer} is looking for a reliable ${JobCategoryMapper.displayName(job.category).toLowerCase()} professional for ${job.title.toLowerCase()} work in ${job.location}.';
List<String> _responsibilities(JobPreview job) => [
      'Complete ${job.title.toLowerCase()} work safely and on time.',
      'Keep the work area clean and communicate progress with the employer.',
      'Follow agreed quality standards for every task.'
    ];
List<String> _requirements(JobPreview job) => [
      '${ExperienceLevelMapper.displayName(job.experienceLevel)} experience preferred.',
      'Bring relevant tools and valid identification where required.',
      'Be available during the agreed working hours.'
    ];
