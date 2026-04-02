class UserProfile {
  final String nickname;
  final String phone;
  final String avatar;

  const UserProfile({
    required this.nickname,
    required this.phone,
    this.avatar = '',
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        nickname: json['nickname'] as String? ?? '预算玩家',
        phone: json['phone'] as String? ?? '',
        avatar: json['avatar'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {
        'nickname': nickname,
        'phone': phone,
        'avatar': avatar,
      };
}
