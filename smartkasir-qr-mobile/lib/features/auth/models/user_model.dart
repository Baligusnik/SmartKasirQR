/// Model pengguna kasir dari response Laravel.
class UserModel {
  /// Membuat model user dengan data aman untuk UI.
  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
  });

  /// ID user dari backend.
  final int id;

  /// Nama kasir.
  final String name;

  /// Email login kasir.
  final String email;

  /// Role user, misalnya cashier.
  final String role;

  /// Membentuk UserModel dari JSON Laravel.
  ///
  /// Field tidak valid diberi nilai aman agar UI tetap dapat dirender.
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] is int
          ? json['id'] as int
          : int.tryParse('${json['id']}') ?? 0,
      name: json['name']?.toString() ?? '-',
      email: json['email']?.toString() ?? '-',
      role: json['role']?.toString() ?? 'cashier',
    );
  }

  /// Mengubah model user menjadi Map sederhana untuk kebutuhan test atau cache ringan.
  Map<String, Object> toJson() {
    return <String, Object>{
      'id': id,
      'name': name,
      'email': email,
      'role': role,
    };
  }

  /// Membuat salinan user dengan sebagian field diperbarui.
  UserModel copyWith({int? id, String? name, String? email, String? role}) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
    );
  }
}
