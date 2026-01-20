import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/services.dart';

class DashboardScreen extends StatefulWidget {
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final db = FirebaseDatabase.instance.ref();
  User? user = FirebaseAuth.instance.currentUser;
  String referral = "";
  int reward = 0;

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    final snap = await db.child('users/${user!.uid}').get();
    if (snap.exists) {
      final data = Map<String, dynamic>.from(snap.value as Map);
      setState(() {
        referral = data['referralCode'];
        reward = data['reward'];
      });
    }
  }

  void logout() async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Dashboard"),
        actions: [
          IconButton(onPressed: logout, icon: const Icon(Icons.logout)),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Email: ${user!.email}", style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 10),
            Text(
              "Referral Code: $referral",
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                ElevatedButton(
                  onPressed: () => Share.share(referral),
                  child: const Text("Share"),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: referral));
                  },
                  child: const Text("Copy"),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              "Reward Points: $reward",
              style: const TextStyle(fontSize: 20),
            ),
          ],
        ),
      ),
    );
  }
}
