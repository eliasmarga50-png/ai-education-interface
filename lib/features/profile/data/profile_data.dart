import '../models/profile.dart';

class ProfileData {
  ProfileData._();

  static const UserProfile currentUser = UserProfile(
    name: 'Elias',
    email: 'elias@example.com',
    bio: 'Learning, building, and exploring new ideas.',
    avatarUrl: '',
    enrolledCourses: 5,
    completedCourses: 1,
    learningHours: 18,
    currentStreak: 7,
  );
}