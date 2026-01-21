import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final user = FirebaseAuth.instance.currentUser!;
  final db = FirebaseDatabase.instance.ref("users");

  bool loading = true;
  String userName = "";
  String userEmail = "";
  String referralCode = "";
  int reward = 0;
  int referredCount = 0;

  List<Map<String, String>> referredUsers = [];

  @override
  void initState() {
    super.initState();
    loadProfile();
  }

  Future<void> loadProfile() async {
    try {
      final snap = await db.child(user.uid).get();

      if (!snap.exists || snap.value == null) {
        setState(() => loading = false);
        return;
      }

      final data = Map<String, dynamic>.from(snap.value as Map);

      userName = data["name"] ?? "User";
      userEmail = data["email"] ?? user.email ?? "";
      referralCode = data["referralCode"] ?? "";
      reward = data["rewardPoints"] ?? 0;
      referredCount = data["peopleReferred"] ?? 0;

      referredUsers.clear();
      final raw = data["referredUsers"];

      if (raw != null && raw is Map) {
        raw.forEach((key, value) {
          if (value is Map) {
            referredUsers.add({
              "name": value["name"] ?? "Unknown",
              "email": value["email"] ?? "Unknown",
              "joinedAt": value["joinedAt"] ?? "",
            });
          }
        });
      }

      setState(() => loading = false);
    } catch (e) {
      debugPrint("Profile error: $e");
      setState(() => loading = false);
    }
  }

  String formatDate(String? isoDate) {
    if (isoDate == null || isoDate.isEmpty) return "Recently";
    try {
      final date = DateTime.parse(isoDate);
      return "${date.day}/${date.month}/${date.year}";
    } catch (e) {
      return "Recently";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: loadProfile,
              child: CustomScrollView(
                slivers: [
                  // App Bar with gradient
                  SliverAppBar(
                    expandedHeight: 200,
                    pinned: true,
                    backgroundColor: Colors.deepPurple,
                    flexibleSpace: FlexibleSpaceBar(
                      background: Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.deepPurple, Colors.purpleAccent],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(height: 40),
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 3,
                                ),
                              ),
                              child: const CircleAvatar(
                                radius: 45,
                                backgroundColor: Colors.white,
                                child: Icon(
                                  Icons.person,
                                  size: 50,
                                  color: Colors.deepPurple,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              userName,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              userEmail,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white.withOpacity(0.9),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Content
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Stats Overview Card
                          Container(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Colors.deepPurple, Colors.purple],
                              ),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.deepPurple.withOpacity(0.3),
                                  blurRadius: 10,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _buildMiniStat(
                                          icon: Icons.stars,
                                          label: "Points",
                                          value: "$reward",
                                        ),
                                      ),
                                      Container(
                                        width: 1,
                                        height: 50,
                                        color: Colors.white.withOpacity(0.3),
                                      ),
                                      Expanded(
                                        child: _buildMiniStat(
                                          icon: Icons.people,
                                          label: "Referrals",
                                          value: "$referredCount",
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const Icon(
                                          Icons.card_giftcard,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        const Text(
                                          "Your Code: ",
                                          style: TextStyle(
                                            color: Colors.white70,
                                            fontSize: 14,
                                          ),
                                        ),
                                        Text(
                                          referralCode,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 1.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Referred Users Section
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                "Your Referrals",
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (referredUsers.isNotEmpty)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.deepPurple,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    "${referredUsers.length}",
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                            ],
                          ),

                          const SizedBox(height: 16),

                          // Referred Users List
                          referredUsers.isEmpty
                              ? _buildEmptyState()
                              : Column(
                                  children: referredUsers
                                      .map((u) => _buildReferralCard(u))
                                      .toList(),
                                ),

                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildMiniStat({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 30),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.8)),
        ),
      ],
    );
  }

  Widget _buildReferralCard(Map<String, String> user) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Colors.green, Colors.lightGreen],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.person_add, color: Colors.white),
        ),
        title: Text(
          user["name"]!,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              user["email"]!,
              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 12, color: Colors.grey[500]),
                const SizedBox(width: 4),
                Text(
                  "Joined: ${formatDate(user["joinedAt"])}",
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
              ],
            ),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.amber[50],
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.amber),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.stars, size: 16, color: Colors.amber),
              SizedBox(width: 4),
              Text(
                "+10",
                style: TextStyle(
                  color: Colors.amber,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.people_outline,
              size: 60,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            "No Referrals Yet",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Share your referral code to start earning rewards!",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}
