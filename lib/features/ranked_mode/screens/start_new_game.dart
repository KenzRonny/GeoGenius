import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:geo_genius/features/ranked_mode/screens/ranked_lobby_screen.dart';
import 'game_screen.dart';

class StartNewGameScreen extends StatefulWidget {
  const StartNewGameScreen({super.key});

  @override
  State<StartNewGameScreen> createState() => _StartNewGameScreenState();
}

Future<String> getRandomCountryId() async {
  final String jsonString = await rootBundle.loadString('assets/json/countries/countries.json');
  final List<dynamic> countries = json.decode(jsonString);
  final random = Random();
  final country = countries[random.nextInt(countries.length)];
  return country['cca3'];
}

class _StartNewGameScreenState extends State<StartNewGameScreen> {
  final TextEditingController _inviteCodeController = TextEditingController();
  bool _isLoading = false;

  String _generateInviteCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ123456789';
    final rand = Random();
    return List.generate(6, (index) => chars[rand.nextInt(chars.length)]).join();
  }

  Future<void> _createInvite() async {
    setState(() => _isLoading = true);
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final code = _generateInviteCode();

    await FirebaseFirestore.instance.collection('matchInvites').add({
      'creator': uid,
      'inviteCode': code,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });

    setState(() => _isLoading = false);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Einladungscode"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Teile diesen Code mit deinem Gegner:"),
            const SizedBox(height: 12),
            SelectableText(
              code,
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: 2),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => RankedRivalPage()),),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  Future<void> _acceptInvite() async {
    final code = _inviteCodeController.text.trim().toUpperCase();
    final uid = FirebaseAuth.instance.currentUser!.uid;

    setState(() => _isLoading = true);

    try {
      final query = await FirebaseFirestore.instance
          .collection('matchInvites')
          .where('inviteCode', isEqualTo: code)
          .where('status', isEqualTo: 'pending')
          .limit(1)
          .get();

      if (query.docs.isEmpty) throw Exception("Einladung nicht gefunden oder bereits angenommen.");

      final doc = query.docs.first;
      final creatorUid = doc['creator'];

      if (creatorUid == uid) {
        throw Exception("Du kannst deinem eigenen Code nicht beitreten.");
      }

      // zufälliges land laden
      final String jsonString = await rootBundle.loadString('assets/json/countries/countries.json');
      final List<dynamic> countries = json.decode(jsonString);
      final random = Random();
      final country = countries[random.nextInt(countries.length)];
      final countryId = country['cca3']; // z.B. "DEU"

      final creatorSnapshot = await FirebaseFirestore.instance.collection('users').doc(creatorUid).get();
      final creatorName = creatorSnapshot.data()?['name'] ?? 'Unbekannt';

      final currentUserSnapshot = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      final currentUserName = currentUserSnapshot.data()?['name'] ?? 'Unbekannt';

      // Match in Firestore erstellen
      final matchDoc = await FirebaseFirestore.instance.collection('matches').add({
        'players': {
          'player1': {
            'id': creatorUid,
            'name': creatorName,
            'score': 0,
          },
          'player2': {
            'id': uid,
            'name': currentUserName,
            'score': 0,
          },
        },
        'status': 'playing',
        'countryId': countryId,
        'timeLimitSeconds': 60,
        'startedAt': FieldValue.serverTimestamp(),
      });

      // Einladung aktualisieren
      await doc.reference.update({'status': 'accepted'});

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => GameScreen(matchId: matchDoc.id)),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Fehler: ${e.toString()}")),
        );
      }
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const darkText = Color(0xFF181411);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: BackButton(color: darkText),
        title: Text(
          'Neues Spiel starten',
          style: theme.textTheme.titleLarge?.copyWith(color: darkText),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text("Spielmodus: Asynchron", style: theme.textTheme.titleMedium?.copyWith(color: darkText)),
            const SizedBox(height: 4),
            Text(
              "Spiele jederzeit, dein Gegner wird benachrichtigt.",
              style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[800]),
            ),
            const SizedBox(height: 24),

            _buildCard(
              icon: Icons.person_add_alt_1,
              title: "Code erstellen",
              subtitle: "Teile den Code mit deinem Gegner.",
              buttonText: "Code generieren",
              onPressed: _createInvite,
            ),
            const SizedBox(height: 20),

            _buildCard(
              icon: Icons.vpn_key,
              title: "Code eingeben",
              subtitle: "Gib den Einladungscode deines Gegners ein.",
              content: TextField(
                controller: _inviteCodeController,
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(
                  hintText: 'Einladungscode',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              buttonText: "Beitreten",
              onPressed: _acceptInvite,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard({
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? content,
    required String buttonText,
    required VoidCallback onPressed,
  }) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: const Color(0xFFF1A059)),
                const SizedBox(width: 8),
                Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 8),
            Text(subtitle, style: const TextStyle(fontSize: 14, color: Colors.grey)),
            if (content != null) ...[
              const SizedBox(height: 12),
              content,
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF1A059),
                  foregroundColor: const Color(0xFF181411),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: onPressed,
                child: Text(buttonText),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
