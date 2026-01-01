import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart'; //
import 'package:flutter_spinkit/flutter_spinkit.dart'; //
import 'package_detail_page.dart';

class PackagesPage extends StatefulWidget {
  const PackagesPage({super.key});

  @override
  State<PackagesPage> createState() => _PackagesPageState();
}

class _PackagesPageState extends State<PackagesPage> {
  // 1. Variable to store the search query
  String _searchQuery = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 20, 20, 10),
              child: Text(
                'Packages',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
            ),

            // 2. Search Bar with logic
            _buildSearchBar(),

            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('packages')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    // Premium Spinner
                    return const Center(
                      child: SpinKitFadingCircle(
                        color: Color(0xFFC084FC),
                        size: 50.0,
                      ),
                    );
                  }

                  // 3. Filter and Group logic
                  Map<String, List<QueryDocumentSnapshot>> grouped = {};

                  // Filter based on search query first
                  final filteredDocs = snapshot.data!.docs.where((doc) {
                    String name = (doc['packageName'] ?? '')
                        .toString()
                        .toLowerCase();
                    return name.contains(_searchQuery);
                  }).toList();

                  for (var doc in filteredDocs) {
                    String cat = doc['category'] ?? 'General';
                    grouped.putIfAbsent(cat, () => []).add(doc);
                  }

                  if (filteredDocs.isEmpty) {
                    return const Center(
                      child: Text("No packages match your search."),
                    );
                  }

                  return ListView(
                    children: grouped.keys.map((category) {
                      return _buildCategorySection(
                        context,
                        category,
                        grouped[category]!,
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

  Widget _buildCategorySection(
    BuildContext context,
    String title,
    List<QueryDocumentSnapshot> docs,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
          child: Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        SizedBox(
          height: 220,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.only(left: 20),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              var data = docs[index].data() as Map<String, dynamic>;
              return _buildPackageCard(context, data);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPackageCard(BuildContext context, Map<String, dynamic> data) {
    return Container(
      width: 280,
      margin: const EdgeInsets.only(right: 15, bottom: 10),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PackageDetailPage(
                packageName: data['packageName'] ?? 'N/A',
                price: 'RM${data['price']}/Pax',
                imageUrl: data['imageUrl'] ?? '',
                description: data['description'] ?? 'No description available.',
                category: data['category'] ?? 'General',
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(15),
        child: Container(
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(15),
                  ),
                  // Cached Image for Premium UX
                  child: CachedNetworkImage(
                    imageUrl: data['imageUrl'] ?? '',
                    width: double.infinity,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => const Center(
                      child: SpinKitPulse(color: Color(0xFFC084FC), size: 30.0),
                    ),
                    errorWidget: (context, url, error) =>
                        const Icon(Icons.error),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'RM${data['price']}/Pax',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      data['packageName'] ?? 'N/A',
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10),
      child: TextField(
        onChanged: (value) {
          setState(() {
            _searchQuery = value.toLowerCase(); // Triggers real-time filter
          });
        },
        decoration: InputDecoration(
          hintText: 'Search packages...',
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
