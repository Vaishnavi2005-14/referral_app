import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final referralController = TextEditingController();

  final DatabaseReference db = FirebaseDatabase.instance.ref();
  bool isLoading = false;

  Future<void> signup() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    final referral = referralController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("All fields required")));
      return;
    }

    if (password.length < 6) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Password min 6 chars")));
      return;
    }

    setState(() => isLoading = true);

    try {
      UserCredential cred = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);

      final String uid = cred.user!.uid;
      int reward = 0;

      if (referral.isNotEmpty) {
        final snapshot = await db
            .child('users')
            .orderByChild('referralCode')
            .equalTo(referral)
            .get();

        if (snapshot.exists && snapshot.value != null) {
          final data = snapshot.value as Map<dynamic, dynamic>;
          final String refUid = data.keys.first.toString();

          final refRewardSnap = await db.child('users/$refUid/reward').get();

          int currentReward = (refRewardSnap.value ?? 0) as int;

          await db.child('users/$refUid').update({
            'reward': currentReward + 50,
          });

          reward = 50;
        }
      }

      await db.child('users/$uid').set({
        'email': email,
        'referralCode': uid.substring(0, 6),
        'reward': reward,
        'createdAt': DateTime.now().toIso8601String(),
      });

      Navigator.pushReplacementNamed(context, '/dashboard');
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Signup failed: $e")));
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    referralController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Signup")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                hintText: "Email",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                hintText: "Password",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: referralController,
              decoration: const InputDecoration(
                hintText: "Referral code (optional)",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            isLoading
                ? const CircularProgressIndicator()
                : SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: signup,
                      child: const Text("Signup"),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
