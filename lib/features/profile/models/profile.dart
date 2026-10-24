/// What the profile screens show about the signed-in student.
///
/// Name, email, bio and photo come from the account on the server. The course
/// and learning numbers on the Profile screen are calculated from the real
/// progress (see DashboardService)
class UserProfile {
  final String name;
  final String email;
  final String bio;

  /// A file path on phones, a data: URI on web, empty when there is no photo.
  final String avatarUrl;

  const UserProfile({
    required this.name,
    required this.email,
    required this.bio,
    required this.avatarUrl,
  });

  UserProfile copyWith({
    String? name,
    String? email,
    String? bio,
    String? avatarUrl,
  }) {
    return UserProfile(
      name: name ?? this.name,
      email: email ?? this.email,
      bio: bio ?? this.bio,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }
}