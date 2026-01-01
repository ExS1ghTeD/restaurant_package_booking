import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'new_package_page.dart';
import 'admin_package_detail_page.dart';

class AdminPackagesPage extends StatelessWidget {
  const AdminPackagesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Header Section
            Padding(
              padding: const EdgeInsets.fromLTRB(25, 20, 25, 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Packages',
                    style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const NewPackagePage(),
                      ),
                    ),
                    icon: const Icon(
                      Icons.add_circle_outline,
                      size: 32,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),

            // 2. Search Bar
            _buildSearchBar(),

            // 3. Dynamic Firestore List
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('packages')
                    .orderBy('createdAt', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const Center(child: Text('Something went wrong'));
                  }
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  // Grouping packages by category locally
                  Map<String, List<QueryDocumentSnapshot>> groupedPackages = {};
                  for (var doc in snapshot.data!.docs) {
                    String category = doc['category'] ?? 'General';
                    groupedPackages.putIfAbsent(category, () => []).add(doc);
                  }

                  if (groupedPackages.isEmpty) {
                    return const Center(
                      child: Text('No packages found. Add one!'),
                    );
                  }

                  return ListView(
                    padding: const EdgeInsets.only(bottom: 20),
                    children: groupedPackages.keys.map((category) {
                      return _buildPackageCategory(
                        context,
                        category,
                        groupedPackages[category]!,
                      );
                    }).toList(),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPackageCategory(
    BuildContext context,
    String title,
    List<QueryDocumentSnapshot> docs,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(25, 20, 25, 10),
          child: Text(
            title,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
        SizedBox(
          height: 240,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.only(left: 25),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              // Extract the document snapshot
              var doc = docs[index];
              var data = doc.data() as Map<String, dynamic>;

              // Pass the document ID to the card builder
              return _buildAdminPackageCard(context, data, doc.id);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAdminPackageCard(
    BuildContext context,
    Map<String, dynamic> data,
    String packageId, // Added packageId parameter
  ) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AdminPackageDetailPage(
              packageId: packageId, // CRITICAL: Pass the Firestore ID
              initialCategory: data['category'] ?? '',
              initialName: data['packageName'] ?? '',
              initialPrice: data['price'].toString(),
              initialDescription: data['description'] ?? '',
              imageUrl: data['imageUrl'] ?? '',
            ),
          ),
        );
      },
      child: Container(
        width: 300,
        margin: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
                child: Image.network(
                  data['imageUrl'] ?? '',
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      const Center(child: Icon(Icons.broken_image)),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(15.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'RM${data['price']}/Pax',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    data['packageName'] ?? 'Unnamed Package',
                    style: const TextStyle(fontSize: 16, color: Colors.grey),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25.0, vertical: 10),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Search',
          prefixIcon: const Icon(Icons.search, color: Colors.grey),
          filled: true,
          fillColor: const Color(0xFFF3F4F6),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}
