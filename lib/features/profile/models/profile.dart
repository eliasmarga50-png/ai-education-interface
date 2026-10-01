class UserProfile {
  final String name;
  final String email;
  final String bio;
  final String avatarUrl;
  final int enrolledCourses;
  final int completedCourses;
  final int learningHours;
  final int currentStreak;

  const UserProfile({
    required this.name,
    required this.email,
    required this.bio,
    required this.avatarUrl,
    required this.enrolledCourses,
    required this.completedCourses,
    required this.learningHours,
    required this.currentStreak,
  });
}