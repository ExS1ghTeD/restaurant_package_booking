import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart'; // Package 2
import 'package:flutter_spinkit/flutter_spinkit.dart'; // Package 3
import 'user_detail_page.dart';

class UserListPage extends StatefulWidget {
  const UserListPage({super.key});

  @override
  State<UserListPage> createState() => _UserListPageState();
}

class _UserListPageState extends State<UserListPage> {
  String _searchQuery = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text(
          'Manage Users',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          // Step 2: Updated Search Bar with logic
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: TextField(
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
              decoration: InputDecoration(
                hintText: 'Search users by name...',
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // Step 3: Dynamic Filtered User List with Premium UI
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .orderBy('fullName')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(child: Text('Something went wrong'));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  // Using flutter_spinkit for premium loading
                  return const Center(
                    child: SpinKitFadingCircle(
                      color: Color(0xFFC084FC),
                      size: 50.0,
                    ),
                  );
                }

                final filteredUsers = snapshot.data!.docs.where((doc) {
                  String name = (doc['fullName'] ?? '')
                      .toString()
                      .toLowerCase();
                  return name.contains(_searchQuery);
                }).toList();

                if (filteredUsers.isEmpty) {
                  return const Center(
                    child: Text('No users found matching your search.'),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: filteredUsers.length,
                  itemBuilder: (context, index) {
                    var data =
                        filteredUsers[index].data() as Map<String, dynamic>;
                    return _buildUserCard(
                      context,
                      name: data['fullName'] ?? 'No Name',
                      email: data['email'] ?? 'No Email',
                      userId: filteredUsers[index].id,
                      role: data['role'] ?? 'user',
                      // Optional: Pass an image URL if stored in Firestore
                      profileImg: data['profileImg'],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserCard(
    BuildContext context, {
    required String name,
    required String email,
    required String userId,
    required String role,
    String? profileImg,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 10,
        ),
        // Use CachedNetworkImage for performance if an image exists
        leading: CircleAvatar(
          radius: 25,
          backgroundColor: const Color(0xFFC084FC).withOpacity(0.1),
          child: profileImg != null
              ? ClipOval(
                  child: CachedNetworkImage(
                    imageUrl: profileImg,
                    placeholder: (context, url) =>
                        const SpinKitPulse(color: Color(0xFFC084FC), size: 20),
                    errorWidget: (context, url, error) =>
                        const Icon(Icons.person, color: Color(0xFFC084FC)),
                    fit: BoxFit.cover,
                    width: 50,
                    height: 50,
                  ),
                )
              : const Icon(Icons.person, color: Color(0xFFC084FC)),
        ),
        title: Row(
          children: [
            Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(width: 8),
            if (role == 'admin')
              const Icon(Icons.verified, color: Colors.blue, size: 16),
          ],
        ),
        subtitle: Text(
          email,
          style: const TextStyle(color: Colors.grey, fontSize: 13),
        ),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => UserDetailPage(
                name: name,
                email: email,
                userId: userId,
                role: role,
              ),
            ),
          );
        },
      ),
    );
  }
}
