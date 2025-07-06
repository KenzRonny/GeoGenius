import 'package:cloud_firestore/cloud_firestore.dart';

/*A service that handles Firestore operations for the daily challenge.
 *Each challenge is stored under users/<uid>/daily_challenges/<YYYY-MM-DD>.
 */
class DailyChallengeService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Returns today's date key in "YYYY-MM-DD" format.
  static String get todayKey {
    final now = DateTime.now();
    final y = now.year.toString().padLeft(4, '0');
    final m = now.month.toString().padLeft(2, '0');
    final d = now.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  /////// Ensures a document exists for today's challenge.
  /// If none exists, creates an empty record with default fields.
  static Future<void> ensureDailyChallengeExists(String uid) async {
    final docRef = _firestore
        .collection('users')
        .doc(uid)
        .collection('daily_challenges')
        .doc(todayKey);

    final snapshot = await docRef.get();
    if (!snapshot.exists) {
      await docRef.set({
        'score': null,        
        'answers': [],        
        'completedAt': null,  
      });
    }
  }

  /// Returns true if today's challenge has been submitted.
  static Future<bool> isChallengeDone(String uid) async {
    final doc = await _firestore
        .collection('users')
        .doc(uid)
        .collection('daily_challenges')
        .doc(todayKey)
        .get();

    return doc.exists && doc.data()?['score'] != null;
  }

  /// Submits today's challenge: saves score and answers, sets completedAt.
  static Future<void> submitChallenge({
    required String uid,
    required int score,
    required List<dynamic> answers,
  }) async {
    final docRef = _firestore
        .collection('users')
        .doc(uid)
        .collection('daily_challenges')
        .doc(todayKey);

    await docRef.set({
      'score': score,
      'answers': answers,
      'completedAt': Timestamp.now(),
    });
  }

  /* Retrieves all daily challenges completed by the user.
  Returns a map of DateTime to score (only days with valid scores).*/
  static Future<Map<DateTime, int>> getMonthlyChallenges(String uid) async {
    final snapshot = await _firestore
        .collection('users')
        .doc(uid)
        .collection('daily_challenges')
        .get();

    Map<DateTime, int> result = {};
    for (final doc in snapshot.docs) {
      try {
        /// Parse the document ID (YYYY-MM-DD) into a DateTime.
        final date = DateTime.parse(doc.id);
        final score = doc.data()['score'];
        if (score != null) {
          result[date] = score as int;
        }
      } catch (_) {
        // If the doc ID isn't a valid date, ignore it.
      }
    }
    return result;
  }
}
