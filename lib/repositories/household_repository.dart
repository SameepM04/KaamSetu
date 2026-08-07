import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/painting.dart';

import '../data/demo_workers.dart';
import '../services/local_worker_session.dart';

/// Resolves a worker/household photo path to the right [ImageProvider].
///
/// Demo data and any bundled worker photos are stored as local assets
/// (paths starting with `assets/`), while real Firestore profiles store a
/// remote download URL. This lets every avatar in the app render either
/// kind identically without the UI needing to know which one it got.
ImageProvider? workerAvatarImage(String? path) {
  if (path == null || path.isEmpty) return null;
  if (path.startsWith('assets/')) return AssetImage(path);
  return NetworkImage(path);
}

/// Firestore-backed data access for the household experience.  The UI reads
/// these streams directly; no household profile or worker catalogue is cached.
class HouseholdRepository {
  HouseholdRepository({FirebaseFirestore? firestore, FirebaseAuth? auth})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  static final instance = HouseholdRepository();

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  String? get currentUserId => _auth.currentUser?.uid;

  /// Returns the uid to use for repository operations.  In Fake-OTP mode the
  /// real Firebase user is always null, so we fall back to the stable local id.
  String? _uid() {
    final firebaseUid = _auth.currentUser?.uid;
    if (firebaseUid != null) return firebaseUid;
    // Fake-OTP dev mode — use the local session identity.
    final localUid = LocalWorkerSession.userId;
    return localUid.isNotEmpty ? localUid : null;
  }

  Stream<HouseholdProfile> profileStream() {
    final uid = _uid();
    if (uid == null) {
      return Stream.value(HouseholdProfile.fromMap(LocalWorkerSession.data));
    }
    return _firestore.collection('households').doc(uid).snapshots().map(
          (doc) => HouseholdProfile.fromMap(doc.data() ?? const {}, id: doc.id),
        );
  }

  /// Live list of workers.  When Firestore's `workers` collection is empty
  /// (typical for local/demo Firebase projects), falls back to 12 realistic
  /// demo profiles defined in `lib/data/demo_workers.dart`.
  Stream<List<WorkerProfile>> workersStream() =>
      _firestore.collection('workers').snapshots().map(
        (s) {
          final firestoreWorkers = s.docs
              .map((d) => WorkerProfile.fromMap(d.data(), id: d.id))
              .toList();
          return firestoreWorkers.isEmpty ? kDemoWorkers : firestoreWorkers;
        },
      );

  Stream<List<WorkerProfile>> savedWorkersStream() {
    final uid = _uid();
    if (uid == null) return Stream.value(const []);
    return _firestore
        .collection('households')
        .doc(uid)
        .collection('savedWorkers')
        .snapshots()
        .asyncMap((saved) async {
      if (saved.docs.isEmpty) return <WorkerProfile>[];
      final workers = await Future.wait(
        saved.docs.map(
          (entry) => _firestore.collection('workers').doc(entry.id).get(),
        ),
      );
      return workers
          .where((d) => d.exists)
          .map((d) => WorkerProfile.fromMap(d.data()!, id: d.id))
          .toList();
    });
  }

  Stream<Set<String>> savedWorkerIdsStream() {
    final uid = _uid();
    if (uid == null) return Stream.value(const {});
    return _firestore
        .collection('households')
        .doc(uid)
        .collection('savedWorkers')
        .snapshots()
        .map((s) => s.docs.map((d) => d.id).toSet());
  }

  Stream<List<HouseholdJob>> myJobsStream() {
    final uid = _uid();
    if (uid == null) return Stream.value(const []);
    return _firestore
        .collection('jobs')
        .where('householdId', isEqualTo: uid)
        .snapshots()
        .map(
          (s) => s.docs
              .map((d) => HouseholdJob.fromMap(d.data(), id: d.id))
              .toList()
            ..sort((a, b) => b.postedAt.compareTo(a.postedAt)),
        );
  }

  Stream<List<JobApplication>> applicationsForJobStream(String jobId) =>
      _firestore
          .collectionGroup('applications')
          .where('jobId', isEqualTo: jobId)
          .snapshots()
          .asyncMap((s) async {
        final apps = await Future.wait(
          s.docs.map((d) async {
            final workerId = d.reference.parent.parent?.id ?? '';
            final worker =
                await _firestore.collection('workers').doc(workerId).get();
            return JobApplication.fromMap(
              d.data(),
              id: d.id,
              workerId: workerId,
              worker: worker.exists
                  ? WorkerProfile.fromMap(worker.data()!, id: workerId)
                  : null,
            );
          }),
        );
        return apps;
      });

  Future<void> toggleSavedWorker(
    WorkerProfile worker, {
    required bool saved,
  }) async {
    final uid = _uid();
    if (uid == null) return;
    final ref = _firestore
        .collection('households')
        .doc(uid)
        .collection('savedWorkers')
        .doc(worker.id);
    if (saved) {
      await ref.delete();
    } else {
      await ref.set({
        'workerId': worker.id,
        'savedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<void> inviteWorker({
    required WorkerProfile worker,
    required HouseholdJob job,
  }) async {
    final uid = _uid();
    if (uid == null) return;
    await _firestore
        .collection('jobs')
        .doc(job.id)
        .collection('invites')
        .doc(worker.id)
        .set({
      'workerId': worker.id,
      'householdId': uid,
      'status': 'pending',
      'invitedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Posts a new job with all MVP fields.
  Future<void> postJob({
    required String title,
    required String category,
    required String description,
    required String location,
    required String budget,
    required String schedule,
    String date = '',
    String workingHours = '',
    String additionalNotes = '',
  }) async {
    final uid = _uid();
    if (uid == null) {
      throw StateError('You need to be signed in to post a job.');
    }
    await _firestore.collection('jobs').add({
      'householdId': uid,
      'title': title,
      'category': category,
      'description': description,
      'location': location,
      'salary': budget,
      'workingHours': workingHours.isNotEmpty ? workingHours : schedule,
      'date': date,
      'additionalNotes': additionalNotes,
      'status': 'open',
      'applicants': 0,
      'postedAt': FieldValue.serverTimestamp(),
      'verified': true,
    });
  }

  /// Cancels an open or in-progress job.
  Future<void> cancelJob(String jobId) async {
    await _firestore.collection('jobs').doc(jobId).update({
      'status': 'cancelled',
      'cancelledAt': FieldValue.serverTimestamp(),
    });
  }

  /// Marks a job as completed by the household.
  Future<void> markJobComplete(String jobId) async {
    await _firestore.collection('jobs').doc(jobId).update({
      'status': 'completed',
      'completedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Submits a rating and optional review for a completed job.
  Future<void> rateJob({
    required String jobId,
    required double rating,
    String review = '',
    required bool isHouseholdRating,
  }) async {
    final prefix = isHouseholdRating ? 'household' : 'worker';
    await _firestore.collection('jobs').doc(jobId).update({
      '${prefix}Rating': rating,
      '${prefix}Review': review,
      '${prefix}RatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateApplication(
    JobApplication application,
    String status,
  ) async {
    final appRef = _firestore
        .collection('users')
        .doc(application.workerId)
        .collection('applications')
        .doc(application.id);
    final jobRef = _firestore.collection('jobs').doc(application.jobId);
    final fields = <String, dynamic>{
      'status': status,
      '${status}At': FieldValue.serverTimestamp(),
    };
    await _firestore.runTransaction((transaction) async {
      transaction.update(appRef, fields);
      if (status == 'accepted') {
        transaction.update(jobRef, {
          'status': 'inProgress',
          'selectedWorkerId': application.workerId,
          'selectedWorkerName': application.worker?.name ?? '',
        });
      }
      if (status == 'completed') {
        transaction.update(jobRef, {'status': 'completed'});
      }
    });
  }
}

class HouseholdProfile {
  const HouseholdProfile({
    required this.id,
    required this.name,
    this.photoUrl,
    this.avatar,
    this.address = '',
  });
  final String id, name, address;
  final String? photoUrl, avatar;
  factory HouseholdProfile.fromMap(Map<String, dynamic> map, {String? id}) =>
      HouseholdProfile(
        id: id ?? (map['uid'] as String? ?? ''),
        name: (map['fullName'] as String? ?? '').trim(),
        photoUrl: map['profilePhotoURL'] as String?,
        avatar: map['selectedAvatar'] as String?,
        address: map['address'] as String? ?? '',
      );
  String get firstName =>
      name.isEmpty ? 'Guest' : name.split(RegExp(r'\s+')).first;
}

class WorkerProfile {
  const WorkerProfile({
    required this.id,
    required this.name,
    this.photoUrl,
    this.avatar,
    this.skills = const [],
    this.categories = const [],
    this.languages = const [],
    this.wage = 0,
    this.rating = 0,
    this.reviews = 0,
    this.completedJobs = 0,
    this.availability = const [],
    this.distance = 0,
    this.verified = false,
  });
  final String id, name;
  final String? photoUrl, avatar;
  final List<String> skills, categories, languages, availability;
  final int wage, reviews, completedJobs;
  final double rating, distance;
  final bool verified;
  factory WorkerProfile.fromMap(
    Map<String, dynamic> map, {
    required String id,
  }) =>
      WorkerProfile(
        id: id,
        name: (map['fullName'] as String? ?? 'Worker').trim(),
        photoUrl: map['profilePhotoURL'] as String?,
        avatar: map['selectedAvatar'] as String?,
        skills: _strings(map['skills']),
        categories: _strings(map['preferredCategories']),
        languages: _strings(map['languagesKnown']),
        availability: _strings(map['availability']),
        wage: (map['expectedDailyWage'] as num?)?.toInt() ?? 0,
        rating: (map['averageRating'] as num?)?.toDouble() ??
            (map['rating'] as num?)?.toDouble() ??
            0,
        reviews: (map['reviews'] as num?)?.toInt() ??
            (map['completedJobs'] as num?)?.toInt() ??
            ((map['stats'] as Map?)?['completed'] as num?)?.toInt() ??
            0,
        completedJobs: (map['completedJobs'] as num?)?.toInt() ??
            ((map['stats'] as Map?)?['completed'] as num?)?.toInt() ??
            0,
        distance: (map['distanceKm'] as num?)?.toDouble() ?? 0,
        verified: map['verified'] == true || map['isVerified'] == true,
      );
}

class HouseholdJob {
  const HouseholdJob({
    required this.id,
    required this.title,
    required this.category,
    required this.status,
    required this.budget,
    required this.location,
    required this.postedAt,
    required this.applicants,
    this.selectedWorkerName,
    this.selectedWorkerId,
    this.description = '',
    this.schedule = '',
    this.date = '',
    this.workingHours = '',
    this.additionalNotes = '',
    this.householdRating,
    this.workerRating,
    this.householdReview,
    this.workerReview,
  });
  final String id,
      title,
      category,
      status,
      budget,
      location,
      description,
      schedule,
      date,
      workingHours,
      additionalNotes;
  final DateTime postedAt;
  final int applicants;
  final String? selectedWorkerName, selectedWorkerId;
  final double? householdRating, workerRating;
  final String? householdReview, workerReview;

  bool get isRatedByHousehold => householdRating != null && householdRating! > 0;

  factory HouseholdJob.fromMap(
    Map<String, dynamic> map, {
    required String id,
  }) =>
      HouseholdJob(
        id: id,
        title: map['title'] as String? ?? 'Untitled job',
        category: map['category'] as String? ?? '',
        status: map['status'] as String? ?? 'open',
        budget: map['salary'] as String? ?? '',
        location: map['location'] as String? ?? '',
        description: map['description'] as String? ?? '',
        schedule: map['workingHours'] as String? ?? '',
        date: map['date'] as String? ?? '',
        workingHours: map['workingHours'] as String? ?? '',
        additionalNotes: map['additionalNotes'] as String? ?? '',
        applicants: (map['applicants'] as num?)?.toInt() ?? 0,
        selectedWorkerName: map['selectedWorkerName'] as String?,
        selectedWorkerId: map['selectedWorkerId'] as String?,
        householdRating: (map['householdRating'] as num?)?.toDouble(),
        workerRating: (map['workerRating'] as num?)?.toDouble(),
        householdReview: map['householdReview'] as String?,
        workerReview: map['workerReview'] as String?,
        postedAt: _date(map['postedAt']),
      );
}

class JobApplication {
  const JobApplication({
    required this.id,
    required this.jobId,
    required this.workerId,
    required this.status,
    this.worker,
  });
  final String id, jobId, workerId, status;
  final WorkerProfile? worker;
  factory JobApplication.fromMap(
    Map<String, dynamic> map, {
    required String id,
    required String workerId,
    WorkerProfile? worker,
  }) =>
      JobApplication(
        id: id,
        jobId: map['jobId'] as String? ?? id,
        workerId: workerId,
        status: map['status'] as String? ?? 'pending',
        worker: worker,
      );
}

List<String> _strings(Object? value) =>
    value is Iterable ? value.whereType<String>().toList() : const [];
DateTime _date(Object? value) => value is Timestamp
    ? value.toDate()
    : value is DateTime
        ? value
        : DateTime.fromMillisecondsSinceEpoch(0);
