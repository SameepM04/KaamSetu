import 'dart:async';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/painting.dart';

import '../data/demo/demo_jobs.dart';
import '../data/demo_workers.dart';
import '../services/imagekit_service.dart';
import '../services/local_worker_session.dart';
import 'demo_state.dart';

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
  HouseholdRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    ImageKitService? imageKit,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance,
        _imageKit = imageKit ?? ImageKitService();

  static final instance = HouseholdRepository();

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final ImageKitService _imageKit;

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

  /// Live household profile. Falls back to [kDemoHouseholdProfile] whenever
  /// there's no real name to show yet — no signed-in session, or a
  /// signed-in household whose Firestore document hasn't been written (or
  /// doesn't have a name) — so Home never falls back to a bare "Guest"
  /// greeting. Once the real profile has a name, this switches to it
  /// automatically; the UI never needs to change.
  Stream<HouseholdProfile> profileStream() {
    final uid = _uid();
    if (uid == null) {
      final local = HouseholdProfile.fromMap(LocalWorkerSession.data);
      return Stream.value(
          local.name.isEmpty ? kDemoHouseholdProfile : local);
    }
    return _firestore.collection('households').doc(uid).snapshots().map(
      (doc) {
        final profile =
            HouseholdProfile.fromMap(doc.data() ?? const {}, id: doc.id);
        return profile.name.isEmpty ? kDemoHouseholdProfile : profile;
      },
    );
  }

  /// Quick photo-only update for the household profile avatar's pencil
  /// button. Uploads [bytes] to ImageKit (not Firebase Storage — see
  /// `imagekit_service.dart` for why), then persists `profilePhotoURL`
  /// (clearing any preset `selectedAvatar`) — to `households/{uid}` in
  /// Firestore when a real Firebase user is signed in, or to
  /// [LocalWorkerSession] when running in Fake-OTP/dev mode (there is no
  /// authenticated household user in that mode, so a Firestore write would
  /// just fail with permission-denied). Every other profile field (name,
  /// address, etc.) is left untouched.
  ///
  /// Errors propagate — there is no valid URL to fall back to, so the
  /// caller (`ProfileAvatarEditor`) surfaces the failure and keeps the
  /// previous avatar in place, per the existing "don't show a broken
  /// image" error-handling pattern.
  Future<void> updateProfilePhoto(Uint8List bytes) async {
    final uid = _uid();
    if (uid == null) {
      throw StateError('You need to be signed in to update your photo.');
    }
    final url = await _imageKit.uploadProfilePhoto(
      bytes: bytes,
      fileName: '$uid.jpg',
      folder: '/profile-photos/households',
    );

    if (_auth.currentUser != null) {
      await _firestore.collection('households').doc(uid).set({
        'profilePhotoURL': url,
        'selectedAvatar': null,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } else {
      // Fake-OTP/dev mode — no Firebase user, no Firestore document.
      LocalWorkerSession.save({'profilePhotoURL': url, 'selectedAvatar': null});
    }
  }

  /// Live list of workers.  When Firestore's `workers` collection is empty
  /// (typical for local/demo Firebase projects), falls back to 12 realistic
  /// demo profiles defined in `lib/data/demo_workers.dart`.
  WorkerProfile _withWorkerRatingPatch(WorkerProfile worker) {
    final patch = DemoRepositoryState.instance.workerRatingPatches[worker.id];
    if (patch == null) return worker;
    return WorkerProfile(
      id: worker.id,
      name: worker.name,
      photoUrl: worker.photoUrl,
      avatar: worker.avatar,
      skills: worker.skills,
      categories: worker.categories,
      languages: worker.languages,
      wage: worker.wage,
      rating: (patch['averageRating'] as num?)?.toDouble() ?? worker.rating,
      reviews: (patch['reviews'] as num?)?.toInt() ?? worker.reviews,
      completedJobs: worker.completedJobs,
      availability: worker.availability,
      distance: worker.distance,
      verified: worker.verified,
    );
  }

  Stream<List<WorkerProfile>> workersStream() {
    return Stream.multi((controller) {
      var firestoreWorkers = <WorkerProfile>[];

      void emit() {
        final base = firestoreWorkers.isEmpty ? kDemoWorkers : firestoreWorkers;
        controller.add(base.map(_withWorkerRatingPatch).toList());
      }

      final sub = _firestore.collection('workers').snapshots().listen((s) {
        firestoreWorkers =
            s.docs.map((d) => WorkerProfile.fromMap(d.data(), id: d.id)).toList();
        emit();
      }, onError: (_) {
        firestoreWorkers = [];
        emit();
      });
      final demoSub = DemoRepositoryState.instance.changes.listen((_) => emit());
      emit();

      controller.onCancel = () {
        sub.cancel();
        demoSub.cancel();
      };
    });
  }

  Stream<Set<String>> savedWorkerIdsStream() {
    final uid = _uid();
    if (uid == null) return Stream.value(const {});
    return Stream.multi((controller) {
      var firestoreIds = <String>{};
      void emit() =>
          controller.add({...firestoreIds, ..._demoSavedWorkerIds});
      final sub = _firestore
          .collection('households')
          .doc(uid)
          .collection('savedWorkers')
          .snapshots()
          .listen((s) {
        firestoreIds = s.docs.map((d) => d.id).toSet();
        emit();
      }, onError: (_) => emit());
      final demoSub = _demoSavedWorkersBus.stream.listen((_) => emit());
      emit();
      controller.onCancel = () {
        sub.cancel();
        demoSub.cancel();
      };
    });
  }

  Stream<List<WorkerProfile>> savedWorkersStream() {
    return savedWorkerIdsStream().asyncMap((ids) async {
      if (ids.isEmpty) return <WorkerProfile>[];
      final workers = await Future.wait(ids.map(workerById));
      return workers.whereType<WorkerProfile>().toList();
    });
  }

  /// Applies whatever [DemoRepositoryState.jobPatches] holds for a job on
  /// top of the value Firestore (or the bundled demo data) supplied. This is
  /// the read-side of the rating/status demo fallback: every write that
  /// falls back also patches state here, and every screen that shows a
  /// [HouseholdJob] goes through this stream, so a rating/acceptance/
  /// completion saved in demo mode is reflected immediately everywhere,
  /// exactly as a successful Firestore write would be.
  HouseholdJob _withJobPatch(HouseholdJob job) {
    final patch = DemoRepositoryState.instance.jobPatches[job.id];
    if (patch == null) return job;
    return HouseholdJob(
      id: job.id,
      title: job.title,
      category: job.category,
      status: (patch['status'] as String?) ?? job.status,
      budget: job.budget,
      location: job.location,
      postedAt: job.postedAt,
      applicants: (patch['applicants'] as int?) ?? job.applicants,
      selectedWorkerName:
          (patch['selectedWorkerName'] as String?) ?? job.selectedWorkerName,
      selectedWorkerId:
          (patch['selectedWorkerId'] as String?) ?? job.selectedWorkerId,
      description: job.description,
      schedule: job.schedule,
      date: job.date,
      workingHours: job.workingHours,
      duration: job.duration,
      additionalNotes: job.additionalNotes,
      householdRating:
          (patch['householdRating'] as num?)?.toDouble() ?? job.householdRating,
      workerRating:
          (patch['workerRating'] as num?)?.toDouble() ?? job.workerRating,
      householdReview:
          (patch['householdReview'] as String?) ?? job.householdReview,
      workerReview: (patch['workerReview'] as String?) ?? job.workerReview,
      householdThumbUp: patch.containsKey('householdThumbUp')
          ? patch['householdThumbUp'] as bool?
          : job.householdThumbUp,
      workerThumbUp: patch.containsKey('workerThumbUp')
          ? patch['workerThumbUp'] as bool?
          : job.workerThumbUp,
    );
  }

  /// Live list of the signed-in household's jobs, merged with any demo-mode
  /// patches (see [_withJobPatch]) and re-emitted whenever either the
  /// Firestore listener fires or [DemoRepositoryState] changes.
  ///
  /// If Firestore itself can't be reached (permission-denied on the query,
  /// offline, etc.) the stream never errors out to the UI — it falls back
  /// to the bundled demo jobs so "My Jobs" always has something real to
  /// show and the rating/complete flows stay demoable end to end.
  Stream<List<HouseholdJob>> myJobsStream() {
    final uid = _uid();
    if (uid == null) return Stream.value(const []);
    return Stream.multi((controller) {
      var firestoreJobs = <HouseholdJob>[];
      var firestoreOk = false;

      void emit() {
        final hasRealCompleted =
            firestoreOk && firestoreJobs.any((j) => j.status == 'completed');
        final base = hasRealCompleted
            ? firestoreJobs
            : [...firestoreJobs, ...kDemoCompletedJobs];
        controller.add(base.map(_withJobPatch).toList());
      }

      final sub = _firestore
          .collection('jobs')
          .where('householdId', isEqualTo: uid)
          .snapshots()
          .listen((s) {
        firestoreJobs = s.docs
            .map((d) => HouseholdJob.fromMap(d.data(), id: d.id))
            .toList()
          ..sort((a, b) => b.postedAt.compareTo(a.postedAt));
        firestoreOk = true;
        emit();
      }, onError: (_) {
        // Demo-mode fallback (req. #2/#16/#17) — never let a raw Firestore
        // error reach My Jobs; fall back to demo data instead.
        firestoreOk = false;
        firestoreJobs = [];
        emit();
      });
      final demoSub = DemoRepositoryState.instance.changes.listen((_) => emit());
      emit();

      controller.onCancel = () {
        sub.cancel();
        demoSub.cancel();
      };
    });
  }

  /// Resolves a worker by id for detail/summary screens. Tries the live
  /// `workers` collection first and falls back to the bundled demo roster
  /// (covers both a genuinely offline read and a demo completed job whose
  /// `selectedWorkerId` only exists in [kDemoWorkers]).
  Future<WorkerProfile?> workerById(String id) async {
    if (id.isEmpty) return null;
    WorkerProfile? result;
    try {
      final doc = await _firestore.collection('workers').doc(id).get();
      if (doc.exists) result = WorkerProfile.fromMap(doc.data()!, id: doc.id);
    } catch (_) {
      // Fall through to the demo lookup below (e.g. offline/permission).
    }
    if (result == null) {
      for (final worker in kDemoWorkers) {
        if (worker.id == id) {
          result = worker;
          break;
        }
      }
    }
    if (result == null) return null;
    return _withWorkerRatingPatch(result);
  }

  /// Resolves the demo-mode applications for [jobId] (req. #3/#4/#15 —
  /// household must see a worker's application immediately, with no manual
  /// refresh, even when the underlying Firestore write/read is rejected).
  Future<List<JobApplication>> _demoApplicationsForJob(String jobId) async {
    final records = DemoRepositoryState.instance.applicationsForJob(jobId);
    final apps = <JobApplication>[];
    for (final record in records) {
      final worker = await workerById(record.workerId);
      apps.add(JobApplication(
        id: '${record.jobId}_${record.workerId}',
        jobId: record.jobId,
        workerId: record.workerId,
        status: record.status,
        worker: worker,
      ));
    }
    return apps;
  }

  Stream<List<JobApplication>> applicationsForJobStream(String jobId) {
    return Stream.multi((controller) {
      var firestoreApps = <JobApplication>[];
      var firestoreOk = false;

      Future<void> emit() async {
        final demoApps = await _demoApplicationsForJob(jobId);
        // Firestore apps take precedence by workerId; demo apps fill in
        // anything Firestore doesn't have (or everything, if Firestore is
        // unreachable) so the same worker never appears twice.
        final seenWorkerIds = firestoreOk
            ? firestoreApps.map((a) => a.workerId).toSet()
            : <String>{};
        final merged = [
          if (firestoreOk) ...firestoreApps,
          ...demoApps.where((a) => !seenWorkerIds.contains(a.workerId)),
        ];
        if (!controller.isClosed) controller.add(merged);
      }

      final sub = _firestore
          .collectionGroup('applications')
          .where('jobId', isEqualTo: jobId)
          .snapshots()
          .listen((s) async {
        try {
          firestoreApps = await Future.wait(
            s.docs.map((d) async {
              // Prefer the explicit `workerId` field written by
              // JobsRepository.applyForJob() (req. #2/#3 — canonical
              // source of truth for who applied). Older application docs
              // written before this field existed fall back to the
              // worker's uid derived from the doc path
              // (`users/{workerId}/applications/{jobId}`), so existing
              // applications keep working unchanged (req. #12).
              final data = d.data();
              final workerId = (data['workerId'] as String?) ??
                  d.reference.parent.parent?.id ??
                  '';
              // Resolve the applicant's profile defensively: a transient
              // read failure (permissions/offline) for a single worker
              // must not blank out every other real application for this
              // job — it only means this one applicant's profile falls
              // back to the card's existing "Applicant" placeholder.
              WorkerProfile? worker;
              try {
                final workerDoc =
                    await _firestore.collection('workers').doc(workerId).get();
                if (workerDoc.exists) {
                  worker = WorkerProfile.fromMap(workerDoc.data()!,
                      id: workerId);
                }
              } catch (_) {
                worker = null;
              }
              return JobApplication.fromMap(
                data,
                id: d.id,
                workerId: workerId,
                worker: worker,
              );
            }),
          );
          firestoreOk = true;
        } catch (_) {
          firestoreOk = false;
        }
        emit();
      }, onError: (_) {
        firestoreOk = false;
        emit();
      });
      final demoSub =
          DemoRepositoryState.instance.changes.listen((_) => emit());
      emit();

      controller.onCancel = () {
        sub.cancel();
        demoSub.cancel();
      };
    });
  }

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
    try {
      if (saved) {
        await ref.delete();
      } else {
        await ref.set({
          'workerId': worker.id,
          'savedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      if (!DemoRepositoryState.isFallbackError(e)) rethrow;
      // Demo fallback (req. #6/#19) — the caller (a ValueListenableBuilder
      // over savedWorkerIdsStream) still needs a real state change, so this
      // repo keeps its own demo overlay rather than silently doing nothing.
      if (saved) {
        _demoSavedWorkerIds.remove(worker.id);
      } else {
        _demoSavedWorkerIds.add(worker.id);
      }
      _demoSavedWorkersBus.add(null);
    }
  }

  final Set<String> _demoSavedWorkerIds = {};
  final StreamController<void> _demoSavedWorkersBus =
      StreamController<void>.broadcast();

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
    try {
      await _firestore.collection('jobs').doc(jobId).update({
        'status': 'cancelled',
        'cancelledAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      if (!DemoRepositoryState.isFallbackError(e)) rethrow;
      DemoRepositoryState.instance.patchJob(jobId, {'status': 'cancelled'});
    }
  }

  /// Marks a job as completed by the household.
  Future<void> markJobComplete(String jobId) async {
    try {
      await _firestore.collection('jobs').doc(jobId).update({
        'status': 'completed',
        'completedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      if (!DemoRepositoryState.isFallbackError(e)) rethrow;
      DemoRepositoryState.instance.patchJob(jobId, {'status': 'completed'});
    }
  }

  /// Submits a rating (and optional thumb / review) for a completed job.
  ///
  /// Takes the full [job] rather than just an id so a job that only exists
  /// as bundled demo data (see `lib/data/demo/demo_jobs.dart`) can be
  /// backfilled into a complete, correctly-statused Firestore document on
  /// first rating — a bare `update()` would fail with "not found", and a
  /// rating-only patch would leave a sparse doc with no title/category/etc.
  /// on subsequent reads.
  Future<void> rateJob({
    required HouseholdJob job,
    required double rating,
    String review = '',
    bool? thumbUp,
    required bool isHouseholdRating,
  }) async {
    final prefix = isHouseholdRating ? 'household' : 'worker';
    try {
      final ref = _firestore.collection('jobs').doc(job.id);
      // Preserve the real owning household's id rather than blindly
      // stamping whichever identity happens to be calling this method —
      // JobsRepository.rateHousehold() also calls rateJob() (worker rating
      // the household), and stamping the worker's own uid here would break
      // myJobsStream()'s `householdId == uid` query for the actual
      // household.
      final existing = await ref.get();
      final existingHouseholdId = existing.data()?['householdId'] as String?;
      final householdId = (existingHouseholdId?.isNotEmpty ?? false)
          ? existingHouseholdId
          : (isHouseholdRating ? (_uid() ?? '') : '');
      await ref.set({
        'householdId': householdId,
        'title': job.title,
        'category': job.category,
        'status': job.status,
        'salary': job.budget,
        'location': job.location,
        'description': job.description,
        'workingHours': job.workingHours,
        'duration': job.duration,
        'date': job.date,
        'additionalNotes': job.additionalNotes,
        'applicants': job.applicants,
        if (job.selectedWorkerId != null)
          'selectedWorkerId': job.selectedWorkerId,
        if (job.selectedWorkerName != null)
          'selectedWorkerName': job.selectedWorkerName,
        'postedAt': Timestamp.fromDate(job.postedAt),
        '${prefix}Rating': rating,
        '${prefix}Review': review,
        if (thumbUp != null) '${prefix}ThumbUp': thumbUp,
        '${prefix}RatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (isHouseholdRating &&
          rating > 0 &&
          (job.selectedWorkerId ?? '').isNotEmpty) {
        await _bumpWorkerRating(job.selectedWorkerId!, rating);
      }
    } catch (e) {
      if (!DemoRepositoryState.isFallbackError(e)) rethrow;
      // Demo fallback (req. #2/#7/#8/#9) — this is the exact failure the
      // bug report describes ("Couldn't submit your rating"). Store the
      // rating locally instead of losing it, and roll it into the
      // worker's/household's running average exactly as the Firestore path
      // would have.
      if (isHouseholdRating) {
        DemoRepositoryState.instance.rateFromHousehold(job.id,
            rating: rating, review: review, thumbUp: thumbUp);
      } else {
        DemoRepositoryState.instance.patchJob(job.id, {
          'workerRating': rating,
          'workerReview': review,
          if (thumbUp != null) 'workerThumbUp': thumbUp,
        });
      }
      if (isHouseholdRating &&
          rating > 0 &&
          (job.selectedWorkerId ?? '').isNotEmpty) {
        _bumpWorkerRatingDemo(job.selectedWorkerId!, rating);
      }
    }
  }

  /// Rolls a new rating into a worker's running average. Only touches the
  /// `workers` doc when one already exists in Firestore — writing a
  /// rating-only doc for a pure demo worker would otherwise make
  /// `workersStream()`'s collection look non-empty and replace the full
  /// curated demo roster with a single sparse entry. Falls back to the
  /// shared demo overlay if Firestore rejects the read/write.
  Future<void> _bumpWorkerRating(String workerId, double newRating) async {
    try {
      final ref = _firestore.collection('workers').doc(workerId);
      final snap = await ref.get();
      if (!snap.exists) {
        // No real worker doc — still keep the running average correct in
        // demo mode (e.g. rating a bundled demo worker).
        _bumpWorkerRatingDemo(workerId, newRating);
        return;
      }
      final data = snap.data() ?? const <String, dynamic>{};
      final baseRating = (data['averageRating'] as num?)?.toDouble() ??
          (data['rating'] as num?)?.toDouble() ??
          0;
      final baseReviews = (data['reviews'] as num?)?.toInt() ?? 0;
      final updatedReviews = baseReviews + 1;
      final updatedRating = baseReviews == 0
          ? newRating
          : ((baseRating * baseReviews) + newRating) / updatedReviews;
      await ref.set({
        'averageRating': double.parse(updatedRating.toStringAsFixed(2)),
        'reviews': updatedReviews,
      }, SetOptions(merge: true));
    } catch (e) {
      if (!DemoRepositoryState.isFallbackError(e)) rethrow;
      _bumpWorkerRatingDemo(workerId, newRating);
    }
  }

  void _bumpWorkerRatingDemo(String workerId, double newRating) {
    var baseRating = 0.0;
    var baseReviews = 0;
    for (final worker in kDemoWorkers) {
      if (worker.id == workerId) {
        baseRating = worker.rating;
        baseReviews = worker.reviews;
        break;
      }
    }
    DemoRepositoryState.instance.bumpWorkerRating(
      workerId,
      newRating,
      fallbackBaseRating: baseRating,
      fallbackBaseReviews: baseReviews,
    );
  }

  /// Accepts/rejects/completes a worker's application for a job. Reused by
  /// both a real Firestore-backed application and one that only exists in
  /// the demo overlay (see [DemoRepositoryState]) — in the latter case the
  /// `users/{workerId}/applications/{id}` document simply doesn't exist, so
  /// the transaction below fails with `not-found`, which is one of the
  /// codes [DemoRepositoryState.isFallbackError] treats as "fall back"
  /// rather than "show an error" (req. #3/#4/#15).
  Future<void> updateApplication(
    JobApplication application,
    String status,
  ) async {
    try {
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
    } catch (e) {
      if (!DemoRepositoryState.isFallbackError(e)) rethrow;
      DemoRepositoryState.instance.updateApplicationStatus(
        application.jobId,
        application.workerId,
        status,
      );
      if (status == 'accepted') {
        DemoRepositoryState.instance.setSelectedWorkerName(
          application.jobId,
          application.worker?.name ?? '',
        );
      }
    }
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
    this.duration = '',
    this.additionalNotes = '',
    this.householdRating,
    this.workerRating,
    this.householdReview,
    this.workerReview,
    this.householdThumbUp,
    this.workerThumbUp,
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
      duration,
      additionalNotes;
  final DateTime postedAt;
  final int applicants;
  final String? selectedWorkerName, selectedWorkerId;
  final double? householdRating, workerRating;
  final String? householdReview, workerReview;
  final bool? householdThumbUp, workerThumbUp;

  bool get isRatedByHousehold => householdRating != null && householdRating! > 0;
  bool get isRatedByWorker => workerRating != null && workerRating! > 0;

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
        duration: map['duration'] as String? ?? '',
        additionalNotes: map['additionalNotes'] as String? ?? '',
        applicants: (map['applicants'] as num?)?.toInt() ?? 0,
        selectedWorkerName: map['selectedWorkerName'] as String?,
        selectedWorkerId: map['selectedWorkerId'] as String?,
        householdRating: (map['householdRating'] as num?)?.toDouble(),
        workerRating: (map['workerRating'] as num?)?.toDouble(),
        householdReview: map['householdReview'] as String?,
        workerReview: map['workerReview'] as String?,
        householdThumbUp: map['householdThumbUp'] as bool?,
        workerThumbUp: map['workerThumbUp'] as bool?,
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
        workerId: (map['workerId'] as String?) ?? workerId,
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
