class UserModel {
  final String uid;
  final String email;
  final String displayName;
  final String? bio;
  final String? photoURL;
  final String? bvnSimulation;
  final bool isVerified;
  final String? verificationTxnRef;
  final DateTime? joinedAt;

  UserModel({
    required this.uid,
    required this.email,
    required this.displayName,
    this.bio,
    this.photoURL,
    this.bvnSimulation,
    this.isVerified = false,
    this.verificationTxnRef,
    this.joinedAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        uid: json['uid'] as String,
        email: json['email'] as String,
        displayName: json['displayName'] as String,
        bio: json['bio'] as String?,
        photoURL: json['photoURL'] as String?,
        bvnSimulation: json['bvnSimulation'] as String?,
        isVerified: json['isVerified'] as bool? ?? false,
        verificationTxnRef: json['verificationTxnRef'] as String?,
        joinedAt: json['joinedAt'] != null
            ? DateTime.parse(json['joinedAt'] as String)
            : null,
      );

  Map<String, dynamic> toJson() => {
        'uid': uid,
        'email': email,
        'displayName': displayName,
        if (bio != null) 'bio': bio,
        if (photoURL != null) 'photoURL': photoURL,
        if (bvnSimulation != null) 'bvnSimulation': bvnSimulation,
        'isVerified': isVerified,
        if (verificationTxnRef != null)
          'verificationTxnRef': verificationTxnRef,
        if (joinedAt != null) 'joinedAt': joinedAt?.toIso8601String(),
      };
}
