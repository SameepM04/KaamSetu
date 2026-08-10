import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../data/demo/demo_jobs.dart';
import '../data/job_categories.dart';
import '../data/job_previews.dart';
import '../data/profile_completion.dart';
import '../config/dev_config.dart';
import '../repositories/demo_state.dart';
import '../repositories/household_repository.dart';
import '../services/local_worker_session.dart';
import '../services/worker_auth_service.dart';

/// Denormalized snapshot of a saved job, as stored at
/// `users/{uid}/saved_jobs/{jobId}`. Carries only the metadata Task 2
/// requires so the Saved Jobs screen never has to look the source job up
/// elsewhere (the source is `const` demo data today and may be a live
/// Firestore-backed collection later).
class SavedJobEntry {
  const SavedJobEntry({
    required this.jobId,
    required this.title,
    required this.company,
    required this.location,
    required this.salary,
    required this.distance,
    required this.postedAt,
    required this.category,
    required this.savedAt,
  });

  final String jobId;
  final String title;
  final String company;
  final String location;
  final String salary;
  final String distance;
  final String postedAt;
  final String category;
  final DateTime? savedAt;

  factory SavedJobEntry.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const {};
    return SavedJobEntry(
      jobId: (data['jobId'] as String?) ?? doc.id,
      title: (data['title'] as String?) ?? '',
      company: (data['company'] as String?) ?? '',
      location: (data['location'] as String?) ?? '',
      salary: (data['salary'] as String?) ?? '',
      distance: (data['distance'] as String?) ?? '',
      postedAt: (data['postedAt'] as String?) ?? '',
      category: (data['category'] as String?) ?? '',
      savedAt: (data['savedAt'] as Timestamp?)?.toDate(),
    );
  }

  factory SavedJobEntry.fromPreview(JobPreview job, DateTime savedAt) =>
      SavedJobEntry(
        jobId: job.id,
        title: job.title,
        company: job.employer,
        location: job.location,
        salary: job.pay,
        distance: job.distanceKm,
        postedAt: job.postedAgo,
        category: JobCategoryMapper.filterValue(job.category),
        savedAt: savedAt,
      );

  /// Reconstructs a [JobPreview] so the exact same [JobPreviewCard] widget
  /// used everywhere else in the app can render saved jobs too — no
  /// separate "saved job" UI is created.
  JobPreview toJobPreview() => JobPreview(
        id: jobId,
        title: title,
        employer: company,
        location: location,
        distanceKm: distance,
        postedAgo: postedAt,
        pay: salary,
        categoryOverride: JobCategoryMapper.fromStorage(category),
      );
}

/// Thrown by [JobsRepository.applyForJob] when the worker's profile is not
/// 100% complete. Carries the actual percentage (0-99) so the UI can show
/// it in the existing-style "Complete your profile" dialog without a
/// second read. This is a repository-level gate — it fires before any
/// duplicate-check or Firestore write, so no caller (button state, screen,
/// or future entry point) can bypass it by skipping a UI-only check.
class ProfileIncompleteException implements Exception {
  const ProfileIncompleteException(this.completionPercent);

  /// 0-99 — always < 100, since 100% never throws.
  final int completionPercent;

  @override
  String toString() =>
      'ProfileIncompleteException($completionPercent% complete)';
}

/// Owns every Firestore read/write for job data. Job listings themselves
/// stay as [kJobPreviews] const data for now (Phase 2B is Wishlist +
/// Saved Jobs only) — this repository's scope is the `saved_jobs`
/// subcollection and the wishlist state derived from it.
///
/// A single app-wide instance ([instance]) is used everywhere so there is
/// only ever one Firestore listener for saved jobs, per Task 8.
class JobsRepository {
  JobsRepository._({FirebaseFirestore? firestore, FirebaseAuth? auth})
      : _providedFirestore = firestore,
        _providedAuth = auth;

  static final JobsRepository instance = JobsRepository._();

  final FirebaseFirestore? _providedFirestore;
  final FirebaseAuth? _providedAuth;

  FirebaseFirestore get _firestore =>
      _providedFirestore ?? FirebaseFirestore.instance;
  FirebaseAuth get _auth => _providedAuth ?? FirebaseAuth.instance;

  bool get _firebaseAvailable =>
      _providedFirestore != null || Firebase.apps.isNotEmpty;

  /// Live jobs from `jobs/{jobId}`. The existing previews remain available
  /// until the collection is populated, keeping the established marketplace
  /// usable in local/demo Firebase projects.
  final ValueNotifier<List<JobPreview>> jobs =
      ValueNotifier<List<JobPreview>>(kJobPreviews);
  final ValueNotifier<bool> jobsLoaded = ValueNotifier<bool>(false);

  /// Saved job ids, kept in sync with Firestore and updated optimistically
  /// on toggle. Every bookmark button across the app listens to this same
  /// notifier instead of opening its own Firestore stream.
  final ValueNotifier<Set<String>> savedJobIds = ValueNotifier<Set<String>>({});

  /// Saved job metadata from the same listener that keeps bookmark state in
  /// sync. This lets the Saved Jobs screen reuse one Firestore query.
  final ValueNotifier<List<SavedJobEntry>> savedJobs =
      ValueNotifier<List<SavedJobEntry>>(const []);
  final ValueNotifier<bool> savedJobsLoaded = ValueNotifier<bool>(false);

  /// Shared cache for application state. Job cards use this notifier instead
  /// of each creating their own Firestore subscription.
  final ValueNotifier<Map<String, ApplicationEntry>> applications =
      ValueNotifier<Map<String, ApplicationEntry>>({});
  final ValueNotifier<bool> applicationsLoaded = ValueNotifier<bool>(false);

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _jobsSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _savedIdsSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _applicationsSub;
  String? _listeningUid;
  String? _applicationsListeningUid;
  final StreamController<List<SavedJobEntry>> _savedJobsController =
      StreamController<List<SavedJobEntry>>.broadcast();
  final StreamController<List<ApplicationEntry>> _applicationsController =
      StreamController<List<ApplicationEntry>>.broadcast();

  /// Resolves a repository identity without authenticating as a side effect.
  ///
  /// The existing [WorkerAuthService] intentionally never creates a real
  /// Firebase Auth user in debug builds (see its class doc), which would
  /// otherwise leave `FirebaseAuth.instance.currentUser` null and make
  /// per-user Firestore paths impossible. Anonymous auth is Firebase
  /// itself, not a new architecture, so this stays inside "reuse
  /// Firebase" — it just guarantees a `uid` exists for `users/{uid}/...`.
  String? _uid() {
    if (kUseFakeOtp) return LocalWorkerSession.userId;
    if (!_firebaseAvailable) return null;
    return _auth.currentUser?.uid;
  }

  /// Whether this repository currently has a usable worker identity. In
  /// release/profile this is false until Phone Authentication has completed;
  /// callers can show a signed-out state without triggering authentication.
  bool get isSignedIn => _uid() != null;

  void _publishSignedOutSavedJobs() {
    savedJobIds.value = {};
    savedJobs.value = const [];
    savedJobsLoaded.value = true;
    _savedJobsController.add(const []);
  }

  void _publishSignedOutApplications() {
    applications.value = {};
    applicationsLoaded.value = true;
    _applicationsController.add(const []);
  }

  CollectionReference<Map<String, dynamic>> _savedJobsCol(String uid) =>
      _firestore.collection('users').doc(uid).collection('saved_jobs');

  CollectionReference<Map<String, dynamic>> _applicationsCol(String uid) =>
      _firestore.collection('users').doc(uid).collection('applications');

  /// Starts the app-wide Jobs collection listener once. Filtering unavailable
  /// statuses locally avoids excluding older documents that have no status.
  void ensureJobsListening() {
    if (_jobsSub != null) return;
    if (!_firebaseAvailable) {
      jobsLoaded.value = true;
      return;
    }
    _jobsSub = _firestore.collection('jobs').snapshots().listen((snapshot) {
      final firestoreJobs = snapshot.docs
          .map(_jobFromDoc)
          .where((job) => _isAvailableStatus(job.status))
          .toList()
        ..sort((a, b) =>
            (b.postedAt ?? DateTime(0)).compareTo(a.postedAt ?? DateTime(0)));
      jobs.value = firestoreJobs.isEmpty ? kJobPreviews : firestoreJobs;
      jobsLoaded.value = true;
    }, onError: (_) {
      // The existing previews remain visible if Firestore is temporarily
      // unavailable; saved jobs and applications surface their own errors.
      jobsLoaded.value = true;
    });
  }

  static bool _isAvailableStatus(String status) =>
      switch (status.trim().toLowerCase()) {
        'closed' || 'filled' || 'inactive' || 'draft' => false,
        _ => true,
      };

  JobPreview _jobFromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const <String, dynamic>{};
    final rawPostedAt = data['postedAt'];
    final postedAt = rawPostedAt is Timestamp
        ? rawPostedAt.toDate()
        : rawPostedAt is DateTime
            ? rawPostedAt
            : rawPostedAt is String
                ? DateTime.tryParse(rawPostedAt)
                : null;
    return JobPreview(
      id: (data['id'] as String?)?.trim().isNotEmpty == true
          ? data['id'] as String
          : doc.id,
      title: (data['title'] as String?) ?? 'Untitled job',
      employer: (data['company'] as String?) ?? '',
      location: (data['location'] as String?) ?? '',
      distanceKm: (data['distance'] as String?) ?? '',
      postedAgo: _postedLabel(rawPostedAt, postedAt),
      pay: (data['salary'] as String?) ?? '',
      skills: (data['skills'] as List<dynamic>? ?? const [])
          .whereType<String>()
          .toList(growable: false),
      jobType: _jobType(data['jobType']),
      experienceLevel: _experience(data['experience']),
      verifiedEmployer: data['verified'] == true,
      description: data['description'] as String?,
      workingHours: data['workingHours'] as String?,
      duration: data['duration'] as String?,
      status: (data['status'] as String?) ?? 'open',
      categoryOverride: JobCategoryMapper.fromStorage(data['category']),
      postedAt: postedAt,
    );
  }

  static JobType _jobType(Object? value) => JobType.values.firstWhere(
        (type) =>
            type.name == value || JobTypeMapper.displayName(type) == value,
        orElse: () => JobType.fullTime,
      );

  static ExperienceLevel _experience(Object? value) =>
      ExperienceLevel.values.firstWhere(
        (level) =>
            level.name == value ||
            ExperienceLevelMapper.displayName(level) == value,
        orElse: () => ExperienceLevel.entry,
      );

  static String _postedLabel(Object? value, DateTime? postedAt) {
    if (value is String && DateTime.tryParse(value) == null) return value;
    if (postedAt == null) return 'Recently';
    final age = DateTime.now().difference(postedAt);
    if (age.inMinutes < 60) return '${age.inMinutes.clamp(1, 59)} min ago';
    if (age.inHours < 24) return '${age.inHours} hours ago';
    if (age.inDays == 1) return 'Yesterday';
    return '${age.inDays} days ago';
  }

  /// Starts (once) the single live listener that keeps [savedJobIds] in
  /// sync with Firestore. Safe to call repeatedly — a second listener is
  /// never opened for the same user.
  Future<void> ensureListening() async {
    final uid = _uid();
    if (uid == null || !_firebaseAvailable) {
      await _savedIdsSub?.cancel();
      _savedIdsSub = null;
      _listeningUid = null;
      _publishSignedOutSavedJobs();
      return;
    }
    if (_listeningUid == uid && _savedIdsSub != null) return;
    await _savedIdsSub?.cancel();
    _listeningUid = uid;
    savedJobIds.value = {};
    savedJobs.value = const [];
    savedJobsLoaded.value = false;
    _savedIdsSub = _savedJobsCol(uid)
        .orderBy('savedAt', descending: true)
        .snapshots()
        .listen((snapshot) {
      final entries = snapshot.docs.map(SavedJobEntry.fromDoc).toList();
      savedJobIds.value = {for (final entry in entries) entry.jobId};
      savedJobs.value = entries;
      savedJobsLoaded.value = true;
      _savedJobsController.add(entries);
    }, onError: _savedJobsController.addError);
  }

  /// Restarts the single saved-jobs listener after a user-initiated refresh
  /// or retry. The prior subscription is cancelled before a new one starts.
  Future<void> refreshSavedJobs() async {
    await _savedIdsSub?.cancel();
    _savedIdsSub = null;
    _listeningUid = null;
    await ensureListening();
  }

  void dispose() {
    _jobsSub?.cancel();
    _savedIdsSub?.cancel();
    _applicationsSub?.cancel();
    _demoApplicationsSub?.cancel();
    _savedJobsController.close();
    _applicationsController.close();
  }

  bool isSavedSync(String jobId) => savedJobIds.value.contains(jobId);

  Future<bool> isSaved(String jobId) async {
    await ensureListening();
    return isSavedSync(jobId);
  }

  Future<void> saveJob(JobPreview job) async {
    final uid = _uid();
    if (uid == null) return;
    final ref = _savedJobsCol(uid).doc(job.id);
    final existing = await ref.get();
    if (existing.exists) return; // avoid duplicate writes
    await ref.set({
      'jobId': job.id,
      'title': job.title,
      'company': job.employer,
      'location': job.location,
      'salary': job.pay,
      'distance': job.distanceKm,
      'postedAt': job.postedAgo,
      'category': JobCategoryMapper.filterValue(job.category),
      'savedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> removeSavedJob(String jobId) async {
    final uid = _uid();
    if (uid == null) return;
    await _savedJobsCol(uid).doc(jobId).delete();
  }

  /// Optimistically flips the bookmark state for [job], then persists it.
  /// Rolls the local state back if the Firestore write fails and rethrows
  /// so the caller can show a SnackBar.
  Future<void> toggleWishlist(JobPreview job) async {
    await ensureListening();
    if (_uid() == null) return;
    final wasSaved = savedJobIds.value.contains(job.id);
    final optimistic = {...savedJobIds.value};
    final previousEntries = savedJobs.value;
    if (wasSaved) {
      optimistic.remove(job.id);
    } else {
      optimistic.add(job.id);
    }
    savedJobIds.value = optimistic;
    savedJobs.value = wasSaved
        ? previousEntries.where((entry) => entry.jobId != job.id).toList()
        : [SavedJobEntry.fromPreview(job, DateTime.now()), ...previousEntries];
    _savedJobsController.add(savedJobs.value);

    try {
      if (wasSaved) {
        await removeSavedJob(job.id);
      } else {
        await saveJob(job);
      }
    } catch (e) {
      if (DemoRepositoryState.isFallbackError(e)) {
        // Demo fallback (req. #5/#6/#19) — Firestore rejected the write
        // (typically permission-denied under Fake-OTP mode), but the
        // optimistic state set above is exactly what the bookmark should
        // look like, so keep it instead of rolling back. It already
        // survives navigation/tab-switch/rebuild because it lives in this
        // repository's ValueNotifier, not local widget state.
        return;
      }
      // A genuine failure — rollback so the icon doesn't lie about state.
      final rollback = {...savedJobIds.value};
      if (wasSaved) {
        rollback.add(job.id);
      } else {
        rollback.remove(job.id);
      }
      savedJobIds.value = rollback;
      savedJobs.value = previousEntries;
      _savedJobsController.add(previousEntries);
      rethrow;
    }
  }

  /// Live stream of the signed-in user's saved jobs, newest first. Used
  /// only by the Saved Jobs screen — bookmark buttons elsewhere read
  /// [savedJobIds] instead so there is exactly one Firestore listener for
  /// the whole app (Task 8).
  Stream<List<SavedJobEntry>> savedJobsStream() async* {
    await ensureListening();
    if (savedJobsLoaded.value) yield savedJobs.value;
    yield* _savedJobsController.stream;
  }

  /// Opens one live applications query for the signed-in worker and shares
  /// its results with every subscribed surface in the application.
  Future<void> ensureApplicationsListening() async {
    final uid = _uid();
    if (uid == null || !_firebaseAvailable) {
      await _applicationsSub?.cancel();
      _applicationsSub = null;
      _applicationsListeningUid = null;
      _publishSignedOutApplications();
      return;
    }
    if (_applicationsListeningUid == uid && _applicationsSub != null) return;
    await _applicationsSub?.cancel();
    _applicationsListeningUid = uid;
    applications.value = {};
    applicationsLoaded.value = false;
    var lastFirestoreEntries = <ApplicationEntry>[];
    var firestoreOk = false;

    void emit() {
      var entries = firestoreOk ? lastFirestoreEntries : <ApplicationEntry>[];
      // Hackathon-demo fallback (mirrors HouseholdRepository.myJobsStream)
      // — only kicks in while this worker has no real completed
      // application yet, so the Applications tab and the "Rate Household"
      // flow are demoable out of the box with no manual Firestore seeding.
      if (!entries.any((e) => e.status == ApplicationStatus.completed)) {
        entries = [...entries, ...kDemoCompletedApplications];
      }
      // Demo-mode applications (req. #3/#4/#15) — applications created via
      // JobsRepository.applyForJob()'s fallback, or whose status was
      // updated via HouseholdRepository.updateApplication()'s fallback,
      // live in the shared DemoRepositoryState instead of Firestore. They
      // never duplicate a real Firestore entry for the same jobId.
      final knownJobIds = entries.map((e) => e.jobId).toSet();
      final demoEntries = DemoRepositoryState.instance
          .applicationsForWorker(uid)
          .where((r) => !knownJobIds.contains(r.jobId))
          .map(_applicationEntryFromDemo);
      entries = [...entries, ...demoEntries];
      applications.value = {for (final entry in entries) entry.jobId: entry};
      applicationsLoaded.value = true;
      _applicationsController.add(entries);
    }

    _applicationsSub = _applicationsCol(uid)
        .orderBy('appliedAt', descending: true)
        .snapshots()
        .listen((snapshot) {
      lastFirestoreEntries = snapshot.docs.map(ApplicationEntry.fromDoc).toList();
      firestoreOk = true;
      emit();
    }, onError: (_) {
      firestoreOk = false;
      emit();
    });
    _demoApplicationsSub?.cancel();
    _demoApplicationsSub =
        DemoRepositoryState.instance.changes.listen((_) => emit());
  }

  StreamSubscription<void>? _demoApplicationsSub;

  ApplicationEntry _applicationEntryFromDemo(DemoApplicationRecord r) =>
      ApplicationEntry(
        jobId: r.jobId,
        title: r.title,
        category: r.category,
        company: r.company,
        salary: r.salary,
        location: r.location,
        appliedAt: r.appliedAt,
        status: ApplicationStatusMapper.fromStorage(r.status),
        hasKnownStatus: true,
        jobType: r.jobType,
        distance: r.distance,
        acceptedAt: r.acceptedAt,
        completedAt: r.completedAt,
        rejectedAt: r.rejectedAt,
        withdrawnAt: r.withdrawnAt,
        workerRating: r.workerRating,
        workerReview: r.workerReview,
        workerThumbUp: r.workerThumbUp,
        workerRatedAt: r.workerRatedAt,
      );

  bool isAppliedSync(String jobId) => applications.value.containsKey(jobId);

  ApplicationStatus? applicationStatusSync(String jobId) =>
      applications.value[jobId]?.status;

  Future<bool> isApplied(String jobId) async {
    await ensureApplicationsListening();
    return isAppliedSync(jobId);
  }

  Future<ApplicationStatus?> applicationStatus(String jobId) async {
    await ensureApplicationsListening();
    return applicationStatusSync(jobId);
  }

  /// Creates the sole document for this job. The transaction prevents a
  /// duplicate application from another device or after an app restart.
  ///
  /// Enforces the 100%-profile-completion gate first (see
  /// [ProfileIncompleteException]) — this is the actual apply action, not
  /// a UI-only check, so a worker below 100% can never create an
  /// application here regardless of which screen/button called this.
  Future<bool> applyForJob(JobPreview job) async {
    final uid = _uid();
    if (uid == null) return false;

    final completion = await _currentProfileCompletion(uid);
    if (completion < 1.0) {
      throw ProfileIncompleteException((completion * 100).round());
    }

    // Already applied in demo mode — never create a duplicate (req. #23).
    if (DemoRepositoryState.instance.existingApplication(job.id, uid) !=
        null) {
      return false;
    }
    try {
      final ref = _applicationsCol(uid).doc(job.id);
      var created = false;
      await _firestore.runTransaction((transaction) async {
        final current = await transaction.get(ref);
        if (current.exists) return;
        transaction.set(ref, {
          'jobId': job.id,
          // Explicit canonical worker id, alongside the doc's own
          // `users/{workerId}/applications/{jobId}` path — gives the
          // Household's application query a direct field to read instead
          // of relying solely on path structure (req. #2/#3/#11).
          'workerId': uid,
          'title': job.title,
          'category': JobCategoryMapper.filterValue(job.category),
          'company': job.employer,
          'salary': job.pay,
          'location': job.location,
          'appliedAt': FieldValue.serverTimestamp(),
          'status': ApplicationStatus.pending.name,
          'jobType': JobTypeMapper.displayName(job.jobType),
          'distance': job.distanceKm,
        });
        created = true;
      });
      return created;
    } catch (e) {
      if (!DemoRepositoryState.isFallbackError(e)) rethrow;
      // Demo fallback (req. #2/#3/#4/#15) — the transaction above is what
      // was throwing "You don't have permission to access...". Create the
      // single shared application record locally instead so both this
      // worker's Applications tab and the household's Applications-for-
      // this-job view pick it up immediately (both read through
      // DemoRepositoryState — see ensureApplicationsListening() and
      // HouseholdRepository.applicationsForJobStream()).
      DemoRepositoryState.instance.applyForJob(
        jobId: job.id,
        workerId: uid,
        title: job.title,
        category: JobCategoryMapper.filterValue(job.category),
        company: job.employer,
        salary: job.pay,
        location: job.location,
        jobType: JobTypeMapper.displayName(job.jobType),
        distance: job.distanceKm,
      );
      return true;
    }
  }

  /// Resolves the worker's current profile completion (0.0-1.0) from the
  /// same sources the Worker Profile screen itself reads — never a second
  /// calculation. Fake-OTP dev mode reads the synchronous
  /// [LocalWorkerSession] snapshot (there's no Firestore user to stream
  /// from); real accounts await the first emission of
  /// [WorkerAuthService.workerProfileStream], which also naturally waits
  /// out an in-flight load rather than judging against stale/empty data
  /// (edge case: "profile data is still loading — do not accidentally
  /// allow the application").
  Future<double> _currentProfileCompletion(String uid) async {
    if (kUseFakeOtp) {
      return ProfileCompletion.compute(LocalWorkerSession.data);
    }
    try {
      final data = await WorkerAuthService().workerProfileStream(uid).first;
      return ProfileCompletion.compute(data);
    } catch (_) {
      // Profile couldn't be resolved — treat as incomplete rather than
      // silently letting an application through.
      return 0;
    }
  }

  Future<void> removeApplication(String jobId) async {
    final uid = _uid();
    if (uid == null) return;
    await _applicationsCol(uid).doc(jobId).delete();
  }

  /// Task 3/5 — withdraws an application in place. The document is never
  /// deleted so its history (Task 3D "History must remain available")
  /// stays intact; only `status` and `withdrawnAt` change.
  ///
  /// Throws a [StateError] for invalid transitions (missing application,
  /// already withdrawn, or not currently Pending) and rethrows Firestore's
  /// own [FirebaseException] for offline/permission-denied so callers can
  /// show the right SnackBar (Task 7).
  Future<void> withdrawApplication(String jobId) async {
    final uid = _uid();
    if (uid == null) {
      throw StateError('Not signed in.');
    }
    final demoRecord = DemoRepositoryState.instance.existingApplication(
        jobId, uid);
    if (demoRecord != null) {
      // A demo-mode application never reached Firestore in the first
      // place, so withdraw it the same way it was created.
      if (demoRecord.status == 'withdrawn') {
        throw StateError('This application has already been withdrawn.');
      }
      if (demoRecord.status != 'pending') {
        throw StateError('This application can no longer be withdrawn.');
      }
      DemoRepositoryState.instance
          .updateApplicationStatus(jobId, uid, 'withdrawn');
      return;
    }
    final ref = _applicationsCol(uid).doc(jobId);
    try {
      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(ref);
        if (!snapshot.exists) {
          throw StateError('This application no longer exists.');
        }
        final current = ApplicationEntry.fromDoc(snapshot);
        if (current.status == ApplicationStatus.withdrawn) {
          throw StateError('This application has already been withdrawn.');
        }
        if (!current.canWithdraw) {
          throw StateError(
              'This application can no longer be withdrawn.');
        }
        transaction.update(ref, {
          'status': ApplicationStatus.withdrawn.name,
          'withdrawnAt': FieldValue.serverTimestamp(),
        });
      });
    } catch (e) {
      if (e is StateError || !DemoRepositoryState.isFallbackError(e)) {
        rethrow;
      }
      DemoRepositoryState.instance
          .updateApplicationStatus(jobId, uid, 'withdrawn');
    }
  }

  /// Task 3C/5 — pure derivation of the four-step timeline from an
  /// [ApplicationEntry] already held in memory. Reuses the same
  /// `applications` stream everywhere else in the app; introduces no new
  /// Firestore read or listener.
  List<TimelineStepData> applicationTimeline(ApplicationEntry entry) {
    if (entry.status == ApplicationStatus.withdrawn) {
      return [
        TimelineStepData(
            label: 'Applied',
            state: TimelineStepState.done,
            timestamp: entry.appliedAt),
        TimelineStepData(
            label: 'Withdrawn',
            state: TimelineStepState.terminalNegative,
            timestamp: entry.withdrawnAt),
      ];
    }
    if (entry.status == ApplicationStatus.rejected) {
      return [
        TimelineStepData(
            label: 'Applied',
            state: TimelineStepState.done,
            timestamp: entry.appliedAt),
        if (entry.viewedAt != null)
          TimelineStepData(
              label: 'Employer Viewed',
              state: TimelineStepState.done,
              timestamp: entry.viewedAt),
        TimelineStepData(
            label: 'Rejected',
            state: TimelineStepState.terminalNegative,
            timestamp: entry.rejectedAt),
      ];
    }

    TimelineStepState stateFor(bool done, bool isCurrent) {
      if (done) return TimelineStepState.done;
      if (isCurrent) return TimelineStepState.current;
      return TimelineStepState.upcoming;
    }

    final viewedDone = entry.viewedAt != null ||
        (entry.status.index >= ApplicationStatus.reviewed.index &&
            entry.status != ApplicationStatus.pending);
    final acceptedDone = entry.acceptedAt != null ||
        entry.status == ApplicationStatus.accepted ||
        entry.status == ApplicationStatus.completed;
    final completedDone =
        entry.completedAt != null || entry.status == ApplicationStatus.completed;

    // Only Applied / Employer Viewed / Accepted are shown as timeline
    // steps — completion is already communicated once via the
    // "Completed" ApplicationStatusChip, so a trailing "Completed" step
    // here would duplicate that same information in the UI.
    // `completedDone`/`entry.completedAt` remain read elsewhere (e.g. the
    // rating section) — only this display step is omitted.
    return [
      TimelineStepData(
          label: 'Applied',
          state: TimelineStepState.done,
          timestamp: entry.appliedAt),
      TimelineStepData(
          label: 'Employer Viewed',
          state: stateFor(
              viewedDone, !viewedDone && entry.status == ApplicationStatus.pending),
          timestamp: entry.viewedAt),
      TimelineStepData(
          label: 'Accepted',
          state: stateFor(
              acceptedDone || completedDone, !acceptedDone && viewedDone),
          timestamp: entry.acceptedAt),
    ];
  }

  /// Restarts the one application listener for pull-to-refresh/retry.
  Future<void> refreshApplications() async {
    await _applicationsSub?.cancel();
    _applicationsSub = null;
    _applicationsListeningUid = null;
    await ensureApplicationsListening();
  }

  /// Submits the worker's rating of the household for a completed job.
  ///
  /// Keeps the shared `jobs/{jobId}` document in sync via the existing
  /// [HouseholdRepository.rateJob] write (reused rather than duplicated —
  /// it already knows how to backfill a demo-only job into a real,
  /// correctly-statused document). Also denormalizes the same fields onto
  /// this worker's own `users/{uid}/applications/{jobId}` doc via
  /// `set(merge: true)` so the Applications tab can show "already rated"
  /// without an extra read — and, for a demo entry that doesn't exist in
  /// Firestore yet, backfills the full doc (not just the rating) so it
  /// reads back as a complete, correctly-statused application rather than
  /// a sparse rating-only patch.
  Future<void> rateHousehold({
    required ApplicationEntry entry,
    required double rating,
    bool? thumbUp,
    String review = '',
  }) async {
    final uid = _uid();
    if (uid == null) {
      throw StateError('Not signed in.');
    }
    // HouseholdRepository.rateJob() already has its own demo fallback, so
    // the shared `jobs/{jobId}` document is safe either way.
    await HouseholdRepository.instance.rateJob(
      job: HouseholdJob(
        id: entry.jobId,
        title: entry.title,
        category: entry.category,
        status: 'completed',
        budget: entry.salary,
        location: entry.location,
        postedAt: entry.appliedAt ?? DateTime.now(),
        applicants: 0,
      ),
      rating: rating,
      thumbUp: thumbUp,
      review: review,
      isHouseholdRating: false,
    );
    try {
      await _applicationsCol(uid).doc(entry.jobId).set({
        'jobId': entry.jobId,
        'title': entry.title,
        'category': entry.category,
        'company': entry.company,
        'salary': entry.salary,
        'location': entry.location,
        'status': ApplicationStatus.completed.name,
        'jobType': entry.jobType,
        'distance': entry.distance,
        if (entry.appliedAt != null)
          'appliedAt': Timestamp.fromDate(entry.appliedAt!),
        if (entry.completedAt != null)
          'completedAt': Timestamp.fromDate(entry.completedAt!),
        'workerRating': rating,
        'workerReview': review,
        if (thumbUp != null) 'workerThumbUp': thumbUp,
        'workerRatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      if (!DemoRepositoryState.isFallbackError(e)) rethrow;
      // Demo fallback (req. #2/#7/#8) — this denormalized write is what
      // let the Applications tab show "already rated" without an extra
      // read; the shared demo state now serves that same purpose. Also
      // registers/updates the shared application record so a demo-only
      // application (created via applyForJob()'s fallback, or one of the
      // bundled kDemoCompletedApplications that never had a real Firestore
      // doc) still ends up "Rated" after this call.
      if (DemoRepositoryState.instance.existingApplication(entry.jobId, uid) ==
          null) {
        DemoRepositoryState.instance.applyForJob(
          jobId: entry.jobId,
          workerId: uid,
          title: entry.title,
          category: entry.category,
          company: entry.company,
          salary: entry.salary,
          location: entry.location,
          jobType: entry.jobType,
          distance: entry.distance,
        );
      }
      DemoRepositoryState.instance.rateFromWorker(
        entry.jobId,
        uid,
        rating: rating,
        review: review,
        thumbUp: thumbUp,
      );
    }
  }

  /// A broadcast of the single cached query, not a separate Firestore read.
  Stream<List<ApplicationEntry>> applicationsStream() async* {
    await ensureApplicationsListening();
    if (applicationsLoaded.value) {
      yield applications.value.values.toList()
        ..sort((a, b) =>
            (b.appliedAt ?? DateTime(0)).compareTo(a.appliedAt ?? DateTime(0)));
    }
    yield* _applicationsController.stream;
  }
}

enum ApplicationStatus {
  pending,
  reviewed,
  accepted,
  rejected,
  completed,
  withdrawn,
}

abstract final class ApplicationStatusMapper {
  static const _labels = <ApplicationStatus, String>{
    ApplicationStatus.pending: 'Pending',
    ApplicationStatus.reviewed: 'Reviewed',
    ApplicationStatus.accepted: 'Accepted',
    ApplicationStatus.rejected: 'Rejected',
    ApplicationStatus.completed: 'Completed',
    ApplicationStatus.withdrawn: 'Withdrawn',
  };

  static String displayName(ApplicationStatus status) => _labels[status]!;

  static bool isSupportedStorage(Object? value) {
    if (value is! String) return false;
    final normalized = value.trim().toLowerCase();
    return normalized == 'applied' ||
        ApplicationStatus.values.any((status) => status.name == normalized);
  }

  static ApplicationStatus fromStorage(Object? value) {
    final normalized = value is String ? value.trim().toLowerCase() : '';
    // Existing application documents used `applied` before Pending became
    // the worker-facing status. Keep those documents compatible.
    if (normalized == 'applied') return ApplicationStatus.pending;
    return ApplicationStatus.values.firstWhere(
      (status) => status.name == normalized,
      orElse: () => ApplicationStatus.pending,
    );
  }
}

/// One step in the Phase 3C application timeline (Task 1). Pure display
/// data derived from an [ApplicationEntry] — never persisted itself.
enum TimelineStepState { done, current, upcoming, terminalNegative }

class TimelineStepData {
  const TimelineStepData({
    required this.label,
    required this.state,
    required this.timestamp,
  });

  final String label;
  final TimelineStepState state;
  final DateTime? timestamp;
}

/// Metadata persisted at `users/{uid}/applications/{jobId}`. It recreates a
/// [JobPreview] so the existing card remains the only job-card UI.
class ApplicationEntry {
  const ApplicationEntry({
    required this.jobId,
    required this.title,
    required this.category,
    required this.company,
    required this.salary,
    required this.location,
    required this.appliedAt,
    required this.status,
    required this.hasKnownStatus,
    required this.jobType,
    required this.distance,
    this.viewedAt,
    this.acceptedAt,
    this.completedAt,
    this.rejectedAt,
    this.withdrawnAt,
    this.workerRating,
    this.workerReview,
    this.workerThumbUp,
    this.workerRatedAt,
  });

  final String jobId;
  final String title;
  final String category;
  final String company;
  final String salary;
  final String location;
  final DateTime? appliedAt;
  final ApplicationStatus status;
  final bool hasKnownStatus;
  final String jobType;
  final String distance;

  // Phase 3C/3D timeline + withdraw timestamps. Reused from the same
  // `applications` document already streamed by [JobsRepository] — no new
  // Firestore query is introduced.
  final DateTime? viewedAt;
  final DateTime? acceptedAt;
  final DateTime? completedAt;
  final DateTime? rejectedAt;
  final DateTime? withdrawnAt;

  // Worker's rating of the household for a completed job — denormalized
  // onto this application doc by JobsRepository.rateHousehold() so the
  // Applications tab can show "already rated" without an extra read.
  final double? workerRating;
  final String? workerReview;
  final bool? workerThumbUp;
  final DateTime? workerRatedAt;

  bool get isRatedByWorker => workerRating != null && workerRating! > 0;

  /// True for the small set of canned, always-present demo applications
  /// (`kDemoCompletedApplications` — jobId prefix `demo_job_completed_`)
  /// that `JobsRepository` injects purely so the Applications tab/rating
  /// flow are demoable before the worker has any real completed job of
  /// their own. These were never actually applied for by this worker, so
  /// the Worker Home dashboard counters/earnings must exclude them (see
  /// KaamSetu "make dashboard data-driven" spec, section 40) — every
  /// other entry (including ones created via the demo-mode Firestore
  /// fallback in `applyForJob`/`updateApplicationStatus`) represents a
  /// real action the worker actually took and stays counted.
  bool get isSampleDemoEntry => jobId.startsWith('demo_job_completed_');

  /// Daily pay parsed out of [salary] (e.g. "₹1,500" / "₹1,500/day" ->
  /// 1500). Reuses the exact same parsing approach as
  /// `JobPreview.salaryValue` — the canonical amount already stored on
  /// every application — rather than introducing a second amount field.
  int get salaryValue => int.tryParse(
          (RegExp(r'[\d,]+').firstMatch(salary)?.group(0) ?? '0')
              .replaceAll(',', '')) ??
      0;

  factory ApplicationEntry.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const <String, dynamic>{};
    return ApplicationEntry(
      jobId: (data['jobId'] as String?) ?? doc.id,
      title: (data['title'] as String?) ?? '',
      category: (data['category'] as String?) ?? '',
      company: (data['company'] as String?) ?? '',
      salary: (data['salary'] as String?) ?? '',
      location: (data['location'] as String?) ?? '',
      appliedAt: (data['appliedAt'] as Timestamp?)?.toDate(),
      status: ApplicationStatusMapper.fromStorage(data['status']),
      hasKnownStatus:
          ApplicationStatusMapper.isSupportedStorage(data['status']),
      jobType: (data['jobType'] as String?) ?? '',
      distance: (data['distance'] as String?) ?? '',
      viewedAt: (data['viewedAt'] as Timestamp?)?.toDate(),
      acceptedAt: (data['acceptedAt'] as Timestamp?)?.toDate(),
      completedAt: (data['completedAt'] as Timestamp?)?.toDate(),
      rejectedAt: (data['rejectedAt'] as Timestamp?)?.toDate(),
      withdrawnAt: (data['withdrawnAt'] as Timestamp?)?.toDate(),
      workerRating: (data['workerRating'] as num?)?.toDouble(),
      workerReview: data['workerReview'] as String?,
      workerThumbUp: data['workerThumbUp'] as bool?,
      workerRatedAt: (data['workerRatedAt'] as Timestamp?)?.toDate(),
    );
  }

  /// Task 3 — withdrawal is only ever allowed while the application is
  /// still Pending.
  bool get canWithdraw => status == ApplicationStatus.pending;

  /// Task 2 "Last Updated" — the most recent of every timestamp Firestore
  /// has recorded for this application, falling back to when it was
  /// applied for if nothing later has happened yet.
  DateTime? get lastUpdated => [
        appliedAt,
        viewedAt,
        acceptedAt,
        completedAt,
        rejectedAt,
        withdrawnAt,
      ].whereType<DateTime>().fold<DateTime?>(
          null, (latest, ts) => latest == null || ts.isAfter(latest) ? ts : latest);

  JobPreview toJobPreview() => JobPreview(
        id: jobId,
        title: title,
        employer: company,
        location: location,
        distanceKm: distance,
        postedAgo: 'Applied',
        pay: salary,
        categoryOverride: JobCategoryMapper.fromStorage(category),
        jobType: JobType.values.firstWhere(
          (type) => JobTypeMapper.displayName(type) == jobType,
          orElse: () => JobType.fullTime,
        ),
      );
}
