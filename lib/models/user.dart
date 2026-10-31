
class User {
  final String id;
  final String fullName;
  final String email;

  User({
    required this.id,
    required this.fullName,
    required this.email,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      fullName: (json['fullName'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
    );
  }
}
