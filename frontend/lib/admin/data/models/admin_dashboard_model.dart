class AdminDashboardModel {
  final AdminUserStats users;
  final AdminContentStats content;
  final AdminTripStats trips;
  final List<AdminRecentPlan> recentPlans;

  const AdminDashboardModel({
    required this.users,
    required this.content,
    required this.trips,
    required this.recentPlans,
  });

  factory AdminDashboardModel.fromJson(Map<String, dynamic> json) {
    return AdminDashboardModel(
      users: AdminUserStats.fromJson(json['users'] as Map<String, dynamic>),
      content: AdminContentStats.fromJson(
        json['content'] as Map<String, dynamic>,
      ),
      trips: AdminTripStats.fromJson(json['trips'] as Map<String, dynamic>),
      recentPlans: (json['recent_plans'] as List<dynamic>? ?? [])
          .map((item) => AdminRecentPlan.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}

class AdminUserStats {
  final int total;
  final int active;
  final int inactive;
  final int admins;
  final int normalUsers;

  const AdminUserStats({
    required this.total,
    required this.active,
    required this.inactive,
    required this.admins,
    required this.normalUsers,
  });

  factory AdminUserStats.fromJson(Map<String, dynamic> json) {
    return AdminUserStats(
      total: json['total'] ?? 0,
      active: json['active'] ?? 0,
      inactive: json['inactive'] ?? 0,
      admins: json['admins'] ?? 0,
      normalUsers: json['normal_users'] ?? 0,
    );
  }
}

class AdminContentStats {
  final AdminBannerStats banners;
  final AdminDestinationStats destinations;
  final AdminCityStats cities;
  final AdminPlaceStats places;

  const AdminContentStats({
    required this.banners,
    required this.destinations,
    required this.cities,
    required this.places,
  });

  factory AdminContentStats.fromJson(Map<String, dynamic> json) {
    return AdminContentStats(
      banners: AdminBannerStats.fromJson(
        json['banners'] as Map<String, dynamic>,
      ),
      destinations: AdminDestinationStats.fromJson(
        json['destinations'] as Map<String, dynamic>,
      ),
      cities: AdminCityStats.fromJson(json['cities'] as Map<String, dynamic>),
      places: AdminPlaceStats.fromJson(json['places'] as Map<String, dynamic>),
    );
  }
}

class AdminBannerStats {
  final int total;
  final int active;

  const AdminBannerStats({required this.total, required this.active});

  factory AdminBannerStats.fromJson(Map<String, dynamic> json) {
    return AdminBannerStats(
      total: json['total'] ?? 0,
      active: json['active'] ?? 0,
    );
  }
}

class AdminDestinationStats {
  final int total;
  final int active;
  final int featured;

  const AdminDestinationStats({
    required this.total,
    required this.active,
    required this.featured,
  });

  factory AdminDestinationStats.fromJson(Map<String, dynamic> json) {
    return AdminDestinationStats(
      total: json['total'] ?? 0,
      active: json['active'] ?? 0,
      featured: json['featured'] ?? 0,
    );
  }
}

class AdminCityStats {
  final int total;
  final int active;

  const AdminCityStats({required this.total, required this.active});

  factory AdminCityStats.fromJson(Map<String, dynamic> json) {
    return AdminCityStats(
      total: json['total'] ?? 0,
      active: json['active'] ?? 0,
    );
  }
}

class AdminPlaceStats {
  final int total;
  final int active;
  final int featured;

  const AdminPlaceStats({
    required this.total,
    required this.active,
    required this.featured,
  });

  factory AdminPlaceStats.fromJson(Map<String, dynamic> json) {
    return AdminPlaceStats(
      total: json['total'] ?? 0,
      active: json['active'] ?? 0,
      featured: json['featured'] ?? 0,
    );
  }
}

class AdminTripStats {
  final int total;
  final int draft;
  final int planned;
  final int completed;
  final int cancelled;

  const AdminTripStats({
    required this.total,
    required this.draft,
    required this.planned,
    required this.completed,
    required this.cancelled,
  });

  factory AdminTripStats.fromJson(Map<String, dynamic> json) {
    return AdminTripStats(
      total: json['total'] ?? 0,
      draft: json['draft'] ?? 0,
      planned: json['planned'] ?? 0,
      completed: json['completed'] ?? 0,
      cancelled: json['cancelled'] ?? 0,
    );
  }
}

class AdminRecentPlan {
  final String id;
  final String title;
  final String userId;
  final String destinationId;
  final String startDate;
  final String endDate;
  final int travelers;
  final String status;
  final String? createdAt;

  const AdminRecentPlan({
    required this.id,
    required this.title,
    required this.userId,
    required this.destinationId,
    required this.startDate,
    required this.endDate,
    required this.travelers,
    required this.status,
    required this.createdAt,
  });

  factory AdminRecentPlan.fromJson(Map<String, dynamic> json) {
    return AdminRecentPlan(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      userId: json['user_id'] ?? '',
      destinationId: json['destination_id'] ?? '',
      startDate: json['start_date'] ?? '',
      endDate: json['end_date'] ?? '',
      travelers: json['travelers'] ?? 0,
      status: json['status'] ?? '',
      createdAt: json['created_at'],
    );
  }
}
