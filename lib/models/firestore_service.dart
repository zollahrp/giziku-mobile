import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class FirestoreService {
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  // USERS COLLECTION
  CollectionReference get users =>
      _firestore.collection('users');

  // CREATE USER
  Future<void> createUser(UserModel user) async {
    await users.doc(user.id).set({
      ...user.toJson(),
      'createdAt': Timestamp.now(),
    });
  }

  // GET USER
  Future<UserModel?> getUser(String userId) async {
    final doc = await users.doc(userId).get();

    if (doc.exists) {
      return UserModel.fromJson(
        doc.data() as Map<String, dynamic>,
      );
    }

    return null;
  }
}