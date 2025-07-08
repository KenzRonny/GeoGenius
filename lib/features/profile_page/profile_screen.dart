import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../main.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text("Nicht eingeloggt")),
      );
    }

    final userDoc = FirebaseFirestore.instance.collection('users').doc(user.uid);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: FutureBuilder<DocumentSnapshot>(
          future: userDoc.get(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || !snapshot.data!.exists) {
              return const Center(child: Text("Keine Profildaten gefunden."));
            }

            final data = snapshot.data!.data() as Map<String, dynamic>;
            final name = data['name'] ?? 'Unbekannt';
            final email = user.email ?? '';
            final avatarUrl = data['avatarurl'];
            final int points = (data['rankedPoints'] is int)
                ? data['rankedPoints']
                : int.tryParse(data['rankedPoints']?.toString() ?? '0') ?? 0;
            String rank = '';
            if (points >= 200) {
              rank = 'Gold 🥇';
            } else if (points >= 100) {
              rank = 'Silber 🥈';
            } else if (points >= 1) {
              rank = 'Bronze 🥉';
            }

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                children: [
                  const SizedBox(height: 40),
                  CircleAvatar(
                    radius: 60,
                    backgroundImage: avatarUrl != null
                        ? NetworkImage(avatarUrl)
                        : const AssetImage('lib/assets/default_avatar.png') as ImageProvider,
                  ),
                  const SizedBox(height: 20),
                  Text(name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(email, style: const TextStyle(color: Colors.grey, fontSize: 16)),
                  const SizedBox(height: 32),

                  // Rank & Points Box
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.emoji_events, size: 48, color: Colors.amber),
                        const SizedBox(height: 12),
                        Text(rank.isNotEmpty ? "Rang: $rank" : "Noch kein Rang",
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Text("Punkte: $points",
                            style: const TextStyle(fontSize: 16, color: Colors.black87)),
                      ],
                    ),
                  ),

                  const Spacer(),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Logout bestätigen'),
                            content: const Text(
                              'Bist du sicher, dass du dich abmelden möchtest? '
                                  'Wenn du als Gast angemeldet bist, gehen deine Daten verloren.',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('Abbrechen'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text('Sicher'),
                              ),
                            ],
                          ),
                        );

                        if (confirmed == true) {
                          await FirebaseAuth.instance.signOut();
                          if (!context.mounted) return;
                          // Alle alten Routen löschen und zu AuthGate zurück
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(builder: (_) => const AuthGate()),
                                (route) => false,
                          );

                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[100],
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
                        padding: const EdgeInsets.symmetric(vertical: 18),
                      ),
                      child: const Text("Sign Out", style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
