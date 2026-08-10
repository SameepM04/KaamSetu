import '../../repositories/household_repository.dart';
import '../../repositories/jobs_repository.dart';
import '../demo_workers.dart' show kDemoHouseholdProfile;

/// Two realistic completed jobs used whenever the signed-in household has
/// no real completed job in Firestore yet (see
/// [HouseholdRepository.myJobsStream]) — so the "Completed" tab, the Job
/// Summary screen, and the household rating flow are all demoable out of
/// the box for the hackathon without any manual Firestore seeding.
///
/// Deliberately mixed rating state:
///
/// * `demo_job_completed_01` is already rated by the household, so the Job
///   Summary screen's "already rated" view (stars + thumb + review) has
///   something real to show immediately.
///
/// * `demo_job_completed_02` is NOT yet rated, so the "Rate Worker" button
///   and its bottom sheet (stars, thumb, comment, submit) can be
///   demonstrated live.
///
/// Both link to a real [WorkerProfile] id from `kDemoWorkers`
/// (`lib/data/demo_workers.dart`) via [HouseholdJob.selectedWorkerId], so
/// the Job Summary screen's worker header (photo + name) resolves through
/// the same [HouseholdRepository.workerById] lookup real jobs use.

final kDemoCompletedJobs = [
  HouseholdJob(
    id: 'demo_job_completed_01',
    title: 'Deep House Cleaning',
    category: 'cleaning',
    status: 'completed',
    budget: '₹900',
    location: 'Kothrud, Pune',
    postedAt: DateTime(2026, 7, 2),
    applicants: 3,
    selectedWorkerId: 'demo_w02',
    selectedWorkerName: 'Sunita Devi',
    duration: '4 hours',
    date: '2 Jul 2026',
    description:
        'Full deep clean of a 2BHK — kitchen degreasing, bathroom '
        'sanitization, and floor polishing.',
    householdRating: 5,
    householdReview:
        'Sunita did an amazing job — spotless kitchen and bathrooms. '
        'Punctual and very thorough. Highly recommended!',
    householdThumbUp: true,
  ),

  HouseholdJob(
    id: 'demo_job_completed_02',
    title: 'Kitchen Sink Pipe Leak Repair',
    category: 'plumbing',
    status: 'completed',
    budget: '₹1,200',
    location: 'Kothrud, Pune',
    postedAt: DateTime(2026, 6, 18),
    applicants: 2,
    selectedWorkerId: 'demo_w03',
    selectedWorkerName: 'Vikram Singh',
    duration: '2 hours',
    date: '18 Jun 2026',
    description:
        'Under-sink pipe was leaking and had started damaging the '
        'cabinet base — needed a same-day fix.',

    // Left unrated on purpose — this is the job to tap in a fresh demo to
    // show the "Rate Worker" flow end-to-end.
  ),
];

/// Worker-side mirror of [kDemoCompletedJobs], in the shape the Worker
/// module's Applications tab already renders (`ApplicationEntry`).
///
/// Same `jobId`s, so submitting a "Rate Household" from the worker side
/// and a "Rate Worker" from the household side both land on the same
/// underlying job document (see [JobsRepository.rateHousehold] /
/// [HouseholdRepository.rateJob]).
///
/// Both are left unrated by the worker, so "Rate Household" is demoable
/// from either demo entry.

final kDemoCompletedApplications = [
  ApplicationEntry(
    jobId: 'demo_job_completed_01',
    title: 'Deep House Cleaning',
    category: 'cleaning',
    company: kDemoHouseholdProfile.name,
    salary: '₹900',
    location: 'Kothrud, Pune',
    appliedAt: DateTime(2026, 6, 30),
    acceptedAt: DateTime(2026, 7, 1),
    completedAt: DateTime(2026, 7, 2),
    status: ApplicationStatus.completed,
    hasKnownStatus: true,
    jobType: 'Temporary',
    distance: '1.2 km',
  ),

  ApplicationEntry(
    jobId: 'demo_job_completed_02',
    title: 'Kitchen Sink Pipe Leak Repair',
    category: 'plumbing',
    company: kDemoHouseholdProfile.name,
    salary: '₹1,200',
    location: 'Kothrud, Pune',
    appliedAt: DateTime(2026, 6, 16),
    acceptedAt: DateTime(2026, 6, 17),
    completedAt: DateTime(2026, 6, 18),
    status: ApplicationStatus.completed,
    hasKnownStatus: true,
    jobType: 'Temporary',
    distance: '2.1 km',
  ),
];