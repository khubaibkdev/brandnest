import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:brandnest/core/api_client.dart';
import 'package:brandnest/core/auth_service.dart';

/// Shaadi Squad (US-21). Nothing here is cached in Drift: a board is shared
/// and changes under you, so an offline copy would show votes and pins that
/// are already wrong.

enum SquadEventType {
  mehndi('Mehndi'),
  baraat('Baraat'),
  walima('Walima'),
  eid('Eid'),
  other('Other');

  const SquadEventType(this.label);

  final String label;

  static SquadEventType parse(String value) => SquadEventType.values.firstWhere(
    (type) => type.name == value,
    orElse: () => SquadEventType.other,
  );
}

class SquadSummary {
  const SquadSummary({
    required this.id,
    required this.name,
    required this.eventType,
    required this.eventDate,
    required this.memberCount,
    required this.itemCount,
  });

  final int id;
  final String name;
  final SquadEventType eventType;
  final DateTime? eventDate;
  final int memberCount;
  final int itemCount;

  factory SquadSummary.fromJson(Map<String, dynamic> json) => SquadSummary(
    id: json['id'] as int,
    name: json['name'] as String,
    eventType: SquadEventType.parse(json['event_type'] as String),
    eventDate: _date(json['event_date']),
    memberCount: json['member_count'] as int,
    itemCount: json['item_count'] as int,
  );
}

class SquadInvite {
  const SquadInvite({
    required this.squadId,
    required this.name,
    required this.eventType,
    required this.eventDate,
    required this.memberCount,
    required this.alreadyMember,
  });

  final int squadId;
  final String name;
  final SquadEventType eventType;
  final DateTime? eventDate;
  final int memberCount;
  final bool alreadyMember;

  factory SquadInvite.fromJson(Map<String, dynamic> json) => SquadInvite(
    squadId: json['squad_id'] as int,
    name: json['name'] as String,
    eventType: SquadEventType.parse(json['event_type'] as String),
    eventDate: _date(json['event_date']),
    memberCount: json['member_count'] as int,
    alreadyMember: json['already_member'] as bool,
  );
}

class SquadMember {
  const SquadMember({
    required this.id,
    required this.displayName,
    required this.isOwner,
    required this.budget,
    required this.planned,
  });

  final int id;
  final String displayName;
  final bool isOwner;
  final double? budget;

  /// The current price of everything assigned to this person.
  final double planned;

  factory SquadMember.fromJson(Map<String, dynamic> json) => SquadMember(
    id: json['id'] as int,
    displayName: json['display_name'] as String,
    isOwner: json['role'] == 'owner',
    budget: _money(json['budget_personal']),
    planned: _money(json['planned']) ?? 0,
  );
}

class SquadComment {
  const SquadComment({
    required this.id,
    required this.memberId,
    required this.body,
    required this.createdAt,
  });

  final int id;
  final int memberId;
  final String body;
  final DateTime createdAt;

  factory SquadComment.fromJson(Map<String, dynamic> json) => SquadComment(
    id: json['id'] as int,
    memberId: json['member_id'] as int,
    body: json['body'] as String,
    createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
  );
}

class SquadItem {
  const SquadItem({
    required this.id,
    required this.brandSlug,
    required this.brandName,
    required this.url,
    required this.title,
    required this.imageUrl,
    required this.price,
    required this.addedBy,
    required this.assignedTo,
    required this.note,
    required this.score,
    required this.myVote,
    required this.comments,
  });

  final int id;
  final String brandSlug;
  final String brandName;
  final String url;
  final String title;
  final String? imageUrl;
  final double? price;
  final int addedBy;
  final int? assignedTo;
  final String? note;
  final int score;

  /// -1, 0 or +1.
  final int myVote;
  final List<SquadComment> comments;

  factory SquadItem.fromJson(Map<String, dynamic> json) => SquadItem(
    id: json['id'] as int,
    brandSlug: json['brand_slug'] as String,
    brandName: json['brand_name'] as String,
    url: json['url'] as String,
    title: json['title'] as String,
    imageUrl: json['image_url'] as String?,
    price: _money(json['price']),
    addedBy: json['added_by'] as int,
    assignedTo: json['assigned_to'] as int?,
    note: json['note'] as String?,
    score: json['score'] as int,
    myVote: json['my_vote'] as int,
    comments: (json['comments'] as List)
        .map((comment) => SquadComment.fromJson(comment as Map<String, dynamic>))
        .toList(),
  );
}

class SquadBoard {
  const SquadBoard({
    required this.id,
    required this.name,
    required this.eventType,
    required this.eventDate,
    required this.budgetTotal,
    required this.plannedTotal,
    required this.inviteCode,
    required this.inviteUrl,
    required this.myMemberId,
    required this.members,
    required this.items,
  });

  final int id;
  final String name;
  final SquadEventType eventType;
  final DateTime? eventDate;
  final double? budgetTotal;
  final double plannedTotal;
  final String inviteCode;
  final String inviteUrl;
  final int myMemberId;
  final List<SquadMember> members;
  final List<SquadItem> items;

  SquadMember get me => members.firstWhere((member) => member.id == myMemberId);

  SquadMember? memberById(int? id) =>
      members.where((member) => member.id == id).firstOrNull;

  factory SquadBoard.fromJson(Map<String, dynamic> json) => SquadBoard(
    id: json['id'] as int,
    name: json['name'] as String,
    eventType: SquadEventType.parse(json['event_type'] as String),
    eventDate: _date(json['event_date']),
    budgetTotal: _money(json['budget_total']),
    plannedTotal: _money(json['planned_total']) ?? 0,
    inviteCode: json['invite_code'] as String,
    inviteUrl: json['invite_url'] as String,
    myMemberId: json['my_member_id'] as int,
    members: (json['members'] as List)
        .map((member) => SquadMember.fromJson(member as Map<String, dynamic>))
        .toList(),
    items: (json['items'] as List)
        .map((item) => SquadItem.fromJson(item as Map<String, dynamic>))
        .toList(),
  );
}

class SquadRepository {
  SquadRepository(this._apiClient, [this._getIdToken = noIdToken]);

  final ApiClient _apiClient;
  final IdTokenProvider _getIdToken;

  Future<List<SquadSummary>> mySquads() async =>
      (await _apiClient.fetchMySquads(await _requireIdToken()))
          .map(SquadSummary.fromJson)
          .toList();

  Future<SquadBoard> create({
    required String name,
    required SquadEventType eventType,
    required DateTime? eventDate,
    required double? budgetTotal,
    required String displayName,
  }) async => SquadBoard.fromJson(
    await _apiClient.createSquad(await _requireIdToken(), {
      'name': name,
      'event_type': eventType.name,
      'event_date': ?_dateParam(eventDate),
      'budget_total': ?budgetTotal,
      'display_name': displayName,
    }),
  );

  Future<SquadInvite?> invite(String inviteCode) async {
    final json = await _apiClient.fetchInvite(await _requireIdToken(), inviteCode);
    return json == null ? null : SquadInvite.fromJson(json);
  }

  Future<SquadBoard> join(String inviteCode, String displayName) async =>
      SquadBoard.fromJson(
        await _apiClient.joinSquad(await _requireIdToken(), inviteCode, displayName),
      );

  Future<SquadBoard> board(int squadId) async => SquadBoard.fromJson(
    await _apiClient.fetchSquadBoard(await _requireIdToken(), squadId),
  );

  /// A null [budget] clears it.
  Future<SquadBoard> setMyBudget(int squadId, double? budget) async =>
      SquadBoard.fromJson(
        await _apiClient.updateSquadMe(await _requireIdToken(), squadId, {
          'budget_personal': budget,
        }),
      );

  Future<SquadBoard> pin(
    int squadId, {
    required String brandSlug,
    required String url,
    required String title,
    String? imageUrl,
    String? priceText,
  }) async => SquadBoard.fromJson(
    await _apiClient.pinToSquad(await _requireIdToken(), squadId, {
      'brand_slug': brandSlug,
      'url': url,
      'title': title,
      'image_url': ?imageUrl,
      'price': ?parsePagePrice(priceText),
    }),
  );

  /// A null [memberId] unassigns the item.
  Future<SquadBoard> assign(int squadId, int itemId, int? memberId) async =>
      SquadBoard.fromJson(
        await _apiClient.updateSquadItem(await _requireIdToken(), squadId, itemId, {
          'assigned_to': memberId,
        }),
      );

  Future<SquadBoard> setNote(int squadId, int itemId, String note) async =>
      SquadBoard.fromJson(
        await _apiClient.updateSquadItem(await _requireIdToken(), squadId, itemId, {
          'note': note,
        }),
      );

  Future<SquadBoard> remove(int squadId, int itemId) async => SquadBoard.fromJson(
    await _apiClient.removeSquadItem(await _requireIdToken(), squadId, itemId),
  );

  Future<SquadBoard> vote(int squadId, int itemId, int value) async =>
      SquadBoard.fromJson(
        await _apiClient.voteOnSquadItem(
          await _requireIdToken(),
          squadId,
          itemId,
          value,
        ),
      );

  Future<SquadBoard> comment(int squadId, int itemId, String body) async =>
      SquadBoard.fromJson(
        await _apiClient.commentOnSquadItem(
          await _requireIdToken(),
          squadId,
          itemId,
          body,
        ),
      );

  Future<String> _requireIdToken() async {
    final idToken = await _getIdToken();
    if (idToken == null) throw StateError('Not signed in yet');
    return idToken;
  }
}

/// A storefront's own price text, e.g. "12,990.00", as a number.
double? parsePagePrice(String? text) {
  if (text == null) return null;
  return double.tryParse(text.replaceAll(',', '').trim());
}

/// The `/i/{code}` invite in a shared link, if [uri] is one.
String? inviteCodeFromLink(Uri uri) {
  final segments = uri.pathSegments;
  if (segments.length != 2 || segments.first != 'i') return null;
  return segments.last.isEmpty ? null : segments.last.toUpperCase();
}

DateTime? _date(Object? value) =>
    value == null ? null : DateTime.parse(value as String);

String? _dateParam(DateTime? date) => date == null
    ? null
    : '${date.year.toString().padLeft(4, '0')}-'
          '${date.month.toString().padLeft(2, '0')}-'
          '${date.day.toString().padLeft(2, '0')}';

double? _money(Object? value) =>
    value == null ? null : double.parse(value as String);

final squadRepositoryProvider = Provider<SquadRepository>(
  (ref) => SquadRepository(
    ref.watch(apiClientProvider),
    ref.watch(authServiceProvider).idToken,
  ),
);

final mySquadsProvider = FutureProvider.autoDispose<List<SquadSummary>>(
  (ref) => ref.watch(squadRepositoryProvider).mySquads(),
);

/// An invite link that arrived while the app was open or launched it — the
/// Squads tab picks it up and shows the join sheet.
final pendingInviteProvider = NotifierProvider<PendingInvite, String?>(
  PendingInvite.new,
);

class PendingInvite extends Notifier<String?> {
  @override
  String? build() => null;

  void arrive(String inviteCode) => state = inviteCode;

  void handled() => state = null;
}
