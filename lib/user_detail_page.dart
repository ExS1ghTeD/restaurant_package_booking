import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; //
import 'package:firebase_auth/firebase_auth.dart';

class UserDetailPage extends StatefulWidget {
  final String name;
  final String email;
  final String userId;
  final String role;

  const UserDetailPage({
    super.key,
    required this.name,
    required this.email,
    required this.userId,
    required this.role,
  });

  @override
  State<UserDetailPage> createState() => _UserDetailPageState();
}

class _UserDetailPageState extends State<UserDetailPage> {
  bool _isProcessing = false;
  final String? currentAdminId = FirebaseAuth.instance.currentUser?.uid;

  // 1. Logic to Promote/Demote User
  Future<void> _toggleAdminRole() async {
    if (widget.userId == currentAdminId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("You cannot demote yourself.")),
      );
      return;
    }
    setState(() => _isProcessing = true);
    String newRole = widget.role == 'admin' ? 'user' : 'admin';
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .update({'role': newRole});
      if (mounted) Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  // 2. Logic to Delete User Profile
  Future<void> _deleteUser() async {
    if (widget.userId == currentAdminId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("You cannot delete your own account.")),
      );
      return;
    }
    setState(() => _isProcessing = true);
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .delete();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('User profile deleted.')));
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isSelf = widget.userId == currentAdminId;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFFC084FC)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'User Profile',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // User Header Info
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    const CircleAvatar(
                      radius: 40,
                      backgroundColor: Color(0xFFF3E8FF),
                      child: Icon(
                        Icons.person,
                        size: 40,
                        color: Color(0xFFC084FC),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      widget.name,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      widget.email,
                      style: const TextStyle(color: Colors.grey),
                    ),
                    if (isSelf)
                      const Text(
                        "(You)",
                        style: TextStyle(color: Colors.blue, fontSize: 12),
                      ),
                  ],
                ),
              ),

              const Divider(),

              // Order History Section
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 25, vertical: 10),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Order History',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),

              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('reservations')
                      .where('userId', isEqualTo: widget.userId)
                      .orderBy('createdAt', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Center(
                        child: Text("No orders found for this user."),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: snapshot.data!.docs.length,
                      itemBuilder: (context, index) {
                        var order =
                            snapshot.data!.docs[index].data()
                                as Map<String, dynamic>;
                        return _buildHistoryCard(order);
                      },
                    );
                  },
                ),
              ),

              // Admin Action Buttons
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                child: Column(
                  children: [
                    _buildActionButton(
                      title: widget.role == 'admin'
                          ? 'Remove Admin Rights'
                          : 'Make Admin',
                      color: isSelf ? Colors.grey : const Color(0xFFC084FC),
                      onPressed: isSelf ? () {} : _toggleAdminRole,
                    ),
                    const SizedBox(height: 12),
                    _buildActionButton(
                      title: 'Delete User Profile',
                      color: isSelf ? Colors.grey : const Color(0xFF6A1B9A),
                      onPressed: isSelf
                          ? () {}
                          : () => _showDeleteConfirmDialog(context),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (_isProcessing) const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required String title,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _isProcessing ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryCard(Map<String, dynamic> order) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                order['packageName'] ?? 'N/A',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                order['date'] ?? '',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          Text(
            order['totalPrice'] ?? '',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFFC084FC),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete User?'),
        content: const Text(
          'This will remove the user profile from the database.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _deleteUser();
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
