class UserProfile {
  const UserProfile({
    required this.id,
    required this.email,
    required this.role,
    required this.createdAt,
  });

  final int id;
  final String email;
  final String role;
  final DateTime createdAt;

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        id: json['id'] as int,
        email: json['email'] as String,
        role: json['role'] as String,
        createdAt: DateTime.parse(json['created_at'] as String),
      );
}

class Market {
  const Market({
    required this.id,
    required this.name,
    required this.slug,
    required this.description,
    required this.isActive,
    required this.createdAt,
  });

  final int id;
  final String name;
  final String slug;
  final String? description;
  final bool isActive;
  final DateTime createdAt;

  factory Market.fromJson(Map<String, dynamic> json) => Market(
        id: json['id'] as int,
        name: json['name'] as String,
        slug: json['slug'] as String,
        description: json['description'] as String?,
        isActive: json['is_active'] as bool,
        createdAt: DateTime.parse(json['created_at'] as String),
      );
}

class MarketSchedule {
  const MarketSchedule({
    required this.id,
    required this.marketId,
    required this.weekday,
    required this.opensAt,
    required this.closesAt,
    required this.isActive,
  });

  final int id;
  final int marketId;
  final int weekday;
  final String opensAt;
  final String closesAt;
  final bool isActive;

  factory MarketSchedule.fromJson(Map<String, dynamic> json) => MarketSchedule(
        id: json['id'] as int,
        marketId: json['market_id'] as int,
        weekday: json['weekday'] as int,
        opensAt: json['opens_at'] as String,
        closesAt: json['closes_at'] as String,
        isActive: json['is_active'] as bool,
      );
}

class PublishedResult {
  const PublishedResult({
    required this.id,
    required this.marketId,
    required this.resultDate,
    required this.value,
    required this.publishedAt,
  });

  final int id;
  final int marketId;
  final DateTime resultDate;
  final String value;
  final DateTime publishedAt;

  factory PublishedResult.fromJson(Map<String, dynamic> json) => PublishedResult(
        id: json['id'] as int,
        marketId: json['market_id'] as int,
        resultDate: DateTime.parse(json['result_date'] as String),
        value: json['value'] as String,
        publishedAt: DateTime.parse(json['published_at'] as String),
      );
}

class MarketDetail {
  const MarketDetail({required this.market, required this.schedules});

  final Market market;
  final List<MarketSchedule> schedules;
}