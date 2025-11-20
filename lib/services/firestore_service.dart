// lib/services/firestore_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Firestore에서 사용자 정보가 있는지 확인
  Future<bool> userProfileExists(String uid) async {
    try {
      // 'users' 컬렉션에서 해당 UID의 문서를 참조
      final docRef = _db.collection('users').doc(uid);
      final doc = await docRef.get();
      // 문서가 존재하고 내용이 비어있지 않은지 확인
      return doc.exists && doc.data() != null && doc.data()!.isNotEmpty;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Firestore Error (userProfileExists): $e');
      }
      return false;
    }
  }

  // 신규 가입자의 기본 정보를 Firestore에 저장
  Future<void> saveUserProfile({
    required String uid,
    required double height,
    required double weight,
    required int age,
    required String gender,
    required bool hasCaffeine,
    required bool hasSmoke,
    required List<String> sleepHabits,
    required String goal,
  }) async {
    try {
      await _db.collection('users').doc(uid).set({
        'uid': uid,
        'height': height,
        'weight': weight,
        'age': age,
        'gender': gender,
        'hasCaffeine': hasCaffeine,
        'hasSmoke': hasSmoke,
        'sleepHabits': sleepHabits,
        'goal': goal,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Firestore Error (saveUserProfile): $e');
      }
    }
  }
}