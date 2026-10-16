class UserModel {
  final String id;
  final String? email;
  final String displayName;
  final int? fplTeamId;
  final String status;
  final DateTime? emailVerifiedAt;
  final DateTime? deletionRequestedAt;
  final String? provider;

  const UserModel({
    required this.id,
    this.email,
    required this.displayName,
    this.fplTeamId,
    required this.status,
    this.emailVerifiedAt,
    this.deletionRequestedAt,
    this.provider,
  });

  bool get isEmailVerified => emailVerifiedAt != null || status == 'active';
  bool get hasSquad => fplTeamId != null && fplTeamId! > 0;
  bool get isPendingDeletion => status == 'pending_deletion' || deletionRequestedAt != null;

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String?,
      displayName: (json['display_name'] as String?) ?? 'Manager',
      fplTeamId: json['fpl_team_id'] as int?,
      status: (json['status'] as String?) ?? 'active',
      emailVerifiedAt: json['email_verified_at'] != null
          ? DateTime.tryParse(json['email_verified_at'] as String)
          : null,
      deletionRequestedAt: json['deletion_requested_at'] != null
          ? DateTime.tryParse(json['deletion_requested_at'] as String)
          : null,
      provider: json['provider'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'display_name': displayName,
      'fpl_team_id': fplTeamId,
      'status': status,
      'email_verified_at': emailVerifiedAt?.toIso8601String(),
      'deletion_requested_at': deletionRequestedAt?.toIso8601String(),
      'provider': provider,
    };
  }
}
