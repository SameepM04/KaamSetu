import 'dart:async';

import 'package:firebase_core/firebase_core.dart' show FirebaseException;

/// Single shared source of truth for every "Firestore write failed, keep the
/// demo working" fallback across the app.
///
/// This is deliberately the *only* place that fallback state lives. Both
/// [HouseholdRepository] and [JobsRepository] read/write through here so a
/// single application record, a single job's rating state, and a single
/// worker's average rating never disagree between the Worker and Household
/// sides — exactly like they wouldn't disagree if Firestore itself had
/// accepted the write.
///
/// Nothing in here is persisted to disk: it exists only to keep the running
/// app usable end-to-end for the duration of a demo session when Firestore
/// writes are rejected (typically `permission-denied` because Fake-OTP mode
/// — see `dev_config.dart` — never creates a real signed-in Firebase Auth
/// user, so authenticated security rules reject every write).
class DemoRepositoryState {
  DemoRepositoryState._();

  static final DemoRepositoryState instance = DemoRepositoryState._();

  final StreamController<void> _bus = StreamController<void>.broadcast();

  /// Fires whenever any patch below changes. Every overlay-aware stream in
  /// the two repositories listens to this to know when to re-emit.
  Stream<void> get changes => _bus.stream;

  void _bump() {
    if (!_bus.isClosed) _bus.add(null);
  }

  // ---------------------------------------------------------------------
  // Job field patches — keyed by jobId. Holds whatever a Firestore
  // `jobs/{jobId}` merge-write would have set: status transitions,
  // acceptance, and both sides' ratings.
  // ---------------------------------------------------------------------
  final Map<String, Map<String, dynamic>> jobPatches = {};

  Map<String, dynamic> _patchFor(String jobId) =>
      Map<String, dynamic>.from(jobPatches[jobId] ?? const {});

  void patchJob(String jobId, Map<String, dynamic> fields) {
    final patch = _patchFor(jobId)..addAll(fields);
    jobPatches[jobId] = patch;
    _bump();
  }

  // ---------------------------------------------------------------------
  // Worker rating patches — keyed by workerId. Mirrors
  // HouseholdRepository._bumpWorkerRating's running-average math.
  // ---------------------------------------------------------------------
  final Map<String, Map<String, dynamic>> workerRatingPatches = {};

  void bumpWorkerRating(
    String workerId,
    double newRating, {
    required double fallbackBaseRating,
    required int fallbackBaseReviews,
  }) {
    final existing = workerRatingPatches[workerId];
    final baseRating =
        (existing?['averageRating'] as num?)?.toDouble() ?? fallbackBaseRating;
    final baseReviews =
        (existing?['reviews'] as num?)?.toInt() ?? fallbackBaseReviews;
    final updatedReviews = baseReviews + 1;
    final updatedRating = baseReviews == 0
        ? newRating
        : ((baseRating * baseReviews) + newRating) / updatedReviews;
    workerRatingPatches[workerId] = {
      'averageRating': double.parse(updatedRating.toStringAsFixed(2)),
      'reviews': updatedReviews,
    };
    _bump();
  }

  // ---------------------------------------------------------------------
  // Applications — ONE record per (jobId, workerId), read by both the
  // worker's Applications tab and the household's Applications-for-a-job
  // view. This is the demo-mode analogue of the single Firestore
  // application document requirement.
  // ---------------------------------------------------------------------
  final Map<String, DemoApplicationRecord> _applications = {};

  String _key(String jobId, String workerId) => '$jobId|$workerId';

  DemoApplicationRecord? existingApplication(String jobId, String workerId) =>
      _applications[_key(jobId, workerId)];

  /// Creates the application if one doesn't already exist for this
  /// (jobId, workerId) pair. Returns the (possibly pre-existing) record so
  /// callers can show "Already Applied" instead of creating a duplicate.
  DemoApplicationRecord applyForJob({
    required String jobId,
    required String workerId,
    required String title,
    required String category,
    required String company,
    required String salary,
    required String location,
    required String jobType,
    required String distance,
  }) {
    final key = _key(jobId, workerId);
    final current = _applications[key];
    if (current != null) return current;
    final record = DemoApplicationRecord(
      jobId: jobId,
      workerId: workerId,
      title: title,
      category: category,
      company: company,
      salary: salary,
      location: location,
      jobType: jobType,
      distance: distance,
      appliedAt: DateTime.now(),
    );
    _applications[key] = record;
    final baseCount = (jobPatches[jobId]?['applicants'] as int?) ??
        _applicationsForJobCountExcluding(jobId, key);
    patchJob(jobId, {'applicants': baseCount + 1});
    return record;
  }

  int _applicationsForJobCountExcluding(String jobId, String excludeKey) =>
      _applications.entries
          .where((e) => e.key != excludeKey && e.value.jobId == jobId)
          .length;

  List<DemoApplicationRecord> applicationsForWorker(String workerId) =>
      _applications.values.where((a) => a.workerId == workerId).toList();

  List<DemoApplicationRecord> applicationsForJob(String jobId) =>
      _applications.values.where((a) => a.jobId == jobId).toList();

  /// Household accepts/rejects, or either side marks a job completed.
  void updateApplicationStatus(String jobId, String workerId, String status) {
    final record = _applications[_key(jobId, workerId)];
    final now = DateTime.now();
    if (record != null) {
      record.status = status;
      switch (status) {
        case 'accepted':
          record.acceptedAt = now;
          break;
        case 'completed':
          record.completedAt = now;
          break;
        case 'rejected':
          record.rejectedAt = now;
          break;
        case 'withdrawn':
          record.withdrawnAt = now;
          break;
      }
    }
    if (status == 'accepted') {
      // 'selectedWorkerName' is set separately via [setSelectedWorkerName]
      // once the caller resolves the worker's profile — this method only
      // knows the id.
      patchJob(jobId, {
        'status': 'inProgress',
        'selectedWorkerId': workerId,
      });
    } else if (status == 'completed') {
      patchJob(jobId, {'status': 'completed'});
    } else if (status == 'cancelled') {
      patchJob(jobId, {'status': 'cancelled'});
    }
    _bump();
  }

  void setSelectedWorkerName(String jobId, String name) {
    patchJob(jobId, {'selectedWorkerName': name});
  }

  /// Household rates the worker for [jobId].
  void rateFromHousehold(
    String jobId, {
    required double rating,
    required String review,
    bool? thumbUp,
  }) {
    patchJob(jobId, {
      'householdRating': rating,
      'householdReview': review,
      if (thumbUp != null) 'householdThumbUp': thumbUp,
    });
  }

  /// Worker rates the household for [jobId]. Also denormalizes onto the
  /// worker's own application record, mirroring
  /// `JobsRepository.rateHousehold`'s Firestore write.
  void rateFromWorker(
    String jobId,
    String workerId, {
    required double rating,
    required String review,
    bool? thumbUp,
  }) {
    patchJob(jobId, {
      'workerRating': rating,
      'workerReview': review,
      if (thumbUp != null) 'workerThumbUp': thumbUp,
    });
    final record = _applications[_key(jobId, workerId)];
    if (record != null) {
      record.workerRating = rating;
      record.workerReview = review;
      record.workerThumbUp = thumbUp;
      record.workerRatedAt = DateTime.now();
      record.status = 'completed';
    }
    _bump();
  }

  /// Firestore errors that mean "keep the demo alive locally" rather than
  /// "surface this to the user". Scoped to the specific codes a
  /// mis-configured or fake-auth session would actually produce, so real
  /// programmer errors (null checks, bad casts, StateError validation such
  /// as "Not signed in.") still propagate normally.
  static bool isFallbackError(Object error) {
    if (error is FirebaseException) {
      final code = error.code.toLowerCase();
      return code == 'permission-denied' ||
          code == 'permission_denied' ||
          code == 'unavailable' ||
          code == 'unauthenticated' ||
          code == 'not-found' ||
          code == 'failed-precondition' ||
          code == 'deadline-exceeded';
    }
    // Any other unexpected error talking to Firestore (e.g. the web SDK
    // throwing a plain Exception for a denied request, or being offline)
    // also falls back rather than showing a raw error during the demo.
    return true;
  }
}

class DemoApplicationRecord {
  DemoApplicationRecord({
    required this.jobId,
    required this.workerId,
    required this.title,
    required this.category,
    required this.company,
    required this.salary,
    required this.location,
    required this.jobType,
    required this.distance,
    required this.appliedAt,
    this.status = 'pending',
  });

  final String jobId;
  final String workerId;
  final String title;
  final String category;
  final String company;
  final String salary;
  final String location;
  final String jobType;
  final String distance;
  final DateTime appliedAt;

  String status;
  DateTime? acceptedAt;
  DateTime? completedAt;
  DateTime? rejectedAt;
  DateTime? withdrawnAt;

  double? workerRating;
  String? workerReview;
  bool? workerThumbUp;
  DateTime? workerRatedAt;
}
