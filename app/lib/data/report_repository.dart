import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:brandnest/core/api_client.dart';
import 'package:brandnest/core/auth_service.dart';

/// A deal someone sent in, and what the desk decided (US-14).
enum ReportStatus {
  /// Waiting on the deals desk.
  waiting,

  /// Verified — the points are in the reporter's balance.
  accepted,

  /// The desk could not verify it. Nothing was awarded.
  rejected;

  static ReportStatus parse(String value) => switch (value) {
    'accepted' => ReportStatus.accepted,
    'rejected' => ReportStatus.rejected,
    _ => ReportStatus.waiting,
  };
}

class DealReport {
  const DealReport({
    required this.id,
    required this.text,
    required this.screenshotUrl,
    required this.status,
    required this.pointsAwarded,
    required this.createdAt,
  });

  final int id;
  final String? text;
  final String? screenshotUrl;
  final ReportStatus status;
  final int pointsAwarded;
  final DateTime createdAt;

  factory DealReport.fromJson(Map<String, dynamic> json) => DealReport(
    id: json['id'] as int,
    text: json['text'] as String?,
    screenshotUrl: json['screenshot_url'] as String?,
    status: ReportStatus.parse(json['status'] as String),
    pointsAwarded: json['points_awarded'] as int,
    createdAt: DateTime.parse(json['created_at'] as String),
  );
}

class ReportRepository {
  ReportRepository(this._apiClient, [this._getIdToken = noIdToken]);

  final ApiClient _apiClient;
  final IdTokenProvider _getIdToken;

  Future<DealReport> send({required String text, String? screenshotPath}) async =>
      DealReport.fromJson(
        await _apiClient.createReport(
          await _requireIdToken(),
          text: text,
          screenshotPath: screenshotPath,
        ),
      );

  Future<List<DealReport>> myReports() async => [
    for (final report in await _apiClient.fetchMyReports(await _requireIdToken()))
      DealReport.fromJson(report),
  ];

  Future<String> _requireIdToken() async {
    final idToken = await _getIdToken();
    if (idToken == null) throw StateError('Not signed in yet');
    return idToken;
  }
}

final reportRepositoryProvider = Provider<ReportRepository>(
  (ref) => ReportRepository(
    ref.watch(apiClientProvider),
    ref.watch(authServiceProvider).idToken,
  ),
);

/// Not cached in Drift: the list is short, personal, and only worth reading
/// when it is fresh — a stale "waiting" that the desk decided hours ago would
/// be worse than a spinner.
final myReportsProvider = FutureProvider<List<DealReport>>(
  (ref) => ref.watch(reportRepositoryProvider).myReports(),
);
