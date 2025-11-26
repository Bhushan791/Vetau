class FilterState {
  final Set<String> categories;
  final String? type;
  final bool nearMe;
  final double? latitude;
  final double? longitude;
  final bool highReward;

  const FilterState({
    this.categories = const {},
    this.type,
    this.nearMe = false,
    this.latitude,
    this.longitude,
    this.highReward = false,
  });

  FilterState copyWith({
    Set<String>? categories,
    String? type,
    bool? nearMe,
    double? latitude,
    double? longitude,
    bool? highReward,
  }) {
    return FilterState(
      categories: categories ?? this.categories,
      type: type ?? this.type,
      nearMe: nearMe ?? this.nearMe,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      highReward: highReward ?? this.highReward,
    );
  }
}
