import 'package:flutter_test/flutter_test.dart';

import 'package:brandnest/core/notifications_service.dart';
import 'package:brandnest/data/report_repository.dart';

Map<String, dynamic> _json({
  String status = 'new',
  int points = 0,
  String? text = 'Meezan 20% at J.',
}) => {
  'id': 1,
  'text': text,
  'screenshot_url': '/uploads/abc.png',
  'status': status,
  'points_awarded': points,
  'created_at': '2026-08-31T10:00:00Z',
};

void main() {
  group('reading a report', () {
    test('a new report is still waiting on the desk', () {
      final report = DealReport.fromJson(_json());

      expect(report.status, ReportStatus.waiting);
      expect(report.pointsAwarded, 0);
      expect(report.screenshotUrl, '/uploads/abc.png');
    });

    test('an accepted report carries the points it paid', () {
      final report = DealReport.fromJson(_json(status: 'accepted', points: 50));

      expect(report.status, ReportStatus.accepted);
      expect(report.pointsAwarded, 50);
    });

    test('a rejected report paid nothing', () {
      final report = DealReport.fromJson(_json(status: 'rejected'));

      expect(report.status, ReportStatus.rejected);
      expect(report.pointsAwarded, 0);
    });

    test('an unrecognised status never claims to be decided', () {
      expect(
        DealReport.fromJson(_json(status: 'something_new')).status,
        ReportStatus.waiting,
      );
    });
  });

  group('a decision push', () {
    test('opens the tab My reports hangs off', () {
      expect(homeTabIndexForNotification({'type': 'report'}), 3);
    });
  });
}
