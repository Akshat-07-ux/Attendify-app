import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:attendance/models/user_model.dart';

class AuthMethods {
  final FirebaseAuth firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore firebaseFirestore = FirebaseFirestore.instance;

  Future<String> loginUser({
    required String email,
    required String password,
  }) async {
    String result = "Some error occurred";
    try {
      await firebaseAuth.signInWithEmailAndPassword(email: email, password: password);
      result = "Success";
    } on FirebaseAuthException catch (e) {
      result = e.message ?? "An unknown error occurred";
    }
    return result;
  }

  Future<String> signUpUser({
    required String email,
    required String password,
  }) async {
    String result = "Some error occurred";
    try {
      UserCredential credential = await firebaseAuth.createUserWithEmailAndPassword(email: email, password: password);
      UserModel userModel = UserModel(
        credential.user!.uid,
        "", // Name
        email,
         "", // Phone
        "", // Address
        0,  // Presents
        0,  // Absents
        0,  // CL
        0,  // EL
        0,  // SL
        hasNotification: false
      );
      await firebaseFirestore.collection('users').doc(credential.user!.uid).set(userModel.toJson());
      
      // Create an attendance subcollection for the user
      await firebaseFirestore.collection('users').doc(credential.user!.uid)
          .collection('attendance').doc('records').set({});
      
      result = "Success";
    } on FirebaseAuthException catch (e) {
      result = e.message ?? "An unknown error occurred";
    }
    return result;
  }

  

 Future<void> markAttendance(String userId, String date, bool isPresent, String time) async {
    try {
      DocumentReference userAttendanceRef = firebaseFirestore
          .collection('users')
          .doc(userId)
          .collection('attendance')
          .doc('records');

      await firebaseFirestore.runTransaction((transaction) async {
        DocumentSnapshot snapshot = await transaction.get(userAttendanceRef);

        if (snapshot.exists) {
          Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
          if (data.containsKey(date)) {
            int count = data[date]['count'] ?? 0;
            if (count < 2) {
              transaction.update(userAttendanceRef, {
                date: {
                  'status': isPresent,
                  'time': time,
                  'count': count + 1,
                }
              });
            }
          } else {
            transaction.update(userAttendanceRef, {
              date: {
                'status': isPresent,
                'time': time,
                'count': 1,
              }
            });
          }
        } else {
          transaction.set(userAttendanceRef, {
            date: {
              'status': isPresent,
              'time': time,
              'count': 1,
            }
          });
        }
      });
    } catch (e) {
      print("Error marking attendance: $e");
      throw e;
    }
  }

  Future<Map<String, dynamic>> getAttendanceRecords(String userId) async {
    try {
      DocumentSnapshot snapshot = await firebaseFirestore
          .collection('users')
          .doc(userId)
          .collection('attendance')
          .doc('records')
          .get();

      if (snapshot.exists && snapshot.data() != null) {
        return snapshot.data() as Map<String, dynamic>;
      }
    } catch (e) {
      print("Error getting attendance records: $e");
      throw e;
    }
    return {};
  }

  Future<Map<String, dynamic>?> getAttendanceForDate(String userId, String date) async {
    try {
      DocumentSnapshot snapshot = await firebaseFirestore
          .collection('users')
          .doc(userId)
          .collection('attendance')
          .doc('records')
          .get();

      if (snapshot.exists && snapshot.data() != null) {
        Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
        return data[date] as Map<String, dynamic>?;
      }
      return null;
    } catch (e) {
      print("Error getting attendance for date: $e");
      throw e;
    }
  }
}

