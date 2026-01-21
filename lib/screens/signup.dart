import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final referralController = TextEditingController();

  final auth = FirebaseAuth.instance;
  final DatabaseReference db = FirebaseDatabase.instance.ref("users");

  bool loading = false;

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    referralController.dispose();
    super.dispose();
  }

  String generateReferralCode(String uid) {
    return "REF${uid.substring(0, 6)}";
  }

  /// Find UID from referral code
  Future<String?> getReferrerUid(String code) async {
    try {
      final snap = await db.orderByChild("referralCode").equalTo(code).get();

      if (snap.exists && snap.value != null) {
        final data = snap.value as Map;
        return data.keys.first.toString();
      }
      return null;
    } catch (e) {
      debugPrint("Error finding referrer: $e");
      return null;
    }
  }

  Future<void> signup() async {
    // Validation
    if (nameController.text.trim().isEmpty ||
        emailController.text.trim().isEmpty ||
        passwordController.text.trim().isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please fill all required fields"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => loading = true);

    try {
      // 1️⃣ Create auth user
      final cred = await auth.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      final uid = cred.user!.uid;
      final myReferralCode = generateReferralCode(uid);

      // 2️⃣ Save NEW USER data
      await db.child(uid).set({
        "name": nameController.text.trim(),
        "email": emailController.text.trim(),
        "referralCode": myReferralCode,
        "rewardPoints": 0,
        "peopleReferred": 0,
        "referredUsers": {},
      });

      // 3️⃣ Apply referral (IF ENTERED)
      String? referralMessage;
      if (referralController.text.trim().isNotEmpty) {
        final refCode = referralController.text.trim();
        final refUid = await getReferrerUid(refCode);

        if (refUid != null && refUid != uid) {
          // Get referrer's current data
          final refSnap = await db.child(refUid).get();

          if (refSnap.exists && refSnap.value != null) {
            final refData = Map<String, dynamic>.from(refSnap.value as Map);

            // Calculate new values
            final int currentReward = (refData["rewardPoints"] ?? 0) as int;
            final int currentPeople = (refData["peopleReferred"] ?? 0) as int;
            final Map<String, dynamic> currentReferred =
                Map<String, dynamic>.from(refData["referredUsers"] ?? {});

            // Update values
            final int newReward = currentReward + 10;
            final int newPeople = currentPeople + 1;

            currentReferred[uid] = {
              "name": nameController.text.trim(),
              "email": emailController.text.trim(),
              "joinedAt": DateTime.now().toIso8601String(),
            };

            // Update referrer's data
            await db.child(refUid).update({
              "rewardPoints": newReward,
              "peopleReferred": newPeople,
              "referredUsers": currentReferred,
            });

            referralMessage = "Referral applied! Your referrer got 10 points.";
          } else {
            referralMessage = "Referral code not found.";
          }
        } else if (refUid == uid) {
          referralMessage = "You cannot use your own referral code!";
        } else {
          referralMessage = "Invalid referral code.";
        }
      }

      // 4️⃣ Show success message and navigate
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(referralMessage ?? "Account created successfully!"),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );

      // Navigate to login
      Navigator.pushReplacementNamed(context, '/login');
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      String errorMessage;
      switch (e.code) {
        case 'email-already-in-use':
          errorMessage = 'This email is already registered.';
          break;
        case 'weak-password':
          errorMessage = 'Password should be at least 6 characters.';
          break;
        case 'invalid-email':
          errorMessage = 'Invalid email address.';
          break;
        default:
          errorMessage = 'Error: ${e.message}';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Unexpected error: ${e.toString()}"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Create Account"), centerTitle: true),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              const Text(
                "Sign Up",
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: "Full Name",
                  prefixIcon: Icon(Icons.person),
                  border: OutlineInputBorder(),
                ),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: "Email",
                  prefixIcon: Icon(Icons.email),
                  border: OutlineInputBorder(),
                ),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: "Password",
                  prefixIcon: Icon(Icons.lock),
                  border: OutlineInputBorder(),
                  helperText: "At least 6 characters",
                ),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: referralController,
                decoration: const InputDecoration(
                  labelText: "Referral Code (optional)",
                  prefixIcon: Icon(Icons.card_giftcard),
                  border: OutlineInputBorder(),
                  helperText: "Enter a friend's referral code",
                ),
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => signup(),
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: loading ? null : signup,
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: loading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text("Sign Up", style: TextStyle(fontSize: 16)),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Already have an account? "),
                  TextButton(
                    onPressed: loading
                        ? null
                        : () {
                            Navigator.pushReplacementNamed(context, '/login');
                          },
                    child: const Text(
                      "Login",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
