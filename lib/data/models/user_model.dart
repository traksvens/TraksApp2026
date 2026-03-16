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
  final String? kycStatus;
  final String? kycProvider;
  final String? kycReferenceId;
  final String? kycDocumentType;
  final String? kycCountry;
  final DateTime? kycSubmittedAt;

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
    this.kycStatus,
    this.kycProvider,
    this.kycReferenceId,
    this.kycDocumentType,
    this.kycCountry,
    this.kycSubmittedAt,
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
        kycStatus: json['kycStatus'] as String?,
        kycProvider: json['kycProvider'] as String?,
        kycReferenceId: json['kycReferenceId'] as String?,
        kycDocumentType: json['kycDocumentType'] as String?,
        kycCountry: json['kycCountry'] as String?,
        kycSubmittedAt: json['kycSubmittedAt'] != null
            ? DateTime.tryParse(json['kycSubmittedAt'].toString())
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
        if (kycStatus != null) 'kycStatus': kycStatus,
        if (kycProvider != null) 'kycProvider': kycProvider,
        if (kycReferenceId != null) 'kycReferenceId': kycReferenceId,
        if (kycDocumentType != null) 'kycDocumentType': kycDocumentType,
        if (kycCountry != null) 'kycCountry': kycCountry,
        if (kycSubmittedAt != null) 'kycSubmittedAt': kycSubmittedAt?.toIso8601String(),
      };
}
