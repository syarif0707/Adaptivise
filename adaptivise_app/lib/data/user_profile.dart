class UserProfile {
  final String id;
  final String? fullName;
  final String? primaryVarkStyle;
  final Map<String, dynamic>? varkScores;

  UserProfile({
    required this.id,
    this.fullName,
    this.primaryVarkStyle,
    this.varkScores,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'],
      fullName: json['fullname'],
      primaryVarkStyle: json['primary_vark_style'],
      varkScores: json['vark_scores'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fullname': fullName,
      'primary_vark_style': primaryVarkStyle,
      'vark_scores': varkScores,
    };
  }
}