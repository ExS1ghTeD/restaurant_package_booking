import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore
import 'package_detail_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Header Section
              const Padding(
                padding: EdgeInsets.all(20.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Home',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              // 2. Main Banner
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: Image.network(
                    'https://www.smithandwollensky.com/wp-content/uploads/2022/12/Chicago-private-evetns-hero-2000x1335.jpg',
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // // 3. Promo Section (Still static for specific featured deals)
              // _buildSectionHeader('Promo'),
              // const SizedBox(height: 15),
              // SizedBox(
              //   height: 160,
              //   child: ListView.builder(
              //     scrollDirection: Axis.horizontal,
              //     padding: const EdgeInsets.only(left: 20),
              //     itemCount: 3,
              //     itemBuilder: (context, index) => _buildPromoCard(context),
              //   ),
              // ),
              const SizedBox(height: 30),

              // 4. Hot Selling Section (NOW DYNAMIC FROM FIRESTORE)
              _buildSectionHeader('Hot Selling'),
              const SizedBox(height: 15),
              SizedBox(
                height: 220,
                child: StreamBuilder<QuerySnapshot>(
                  // Fetching packages sorted by creation time
                  stream: FirebaseFirestore.instance
                      .collection('packages')
                      .orderBy('createdAt', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return const Center(child: Text('Error loading data'));
                    }
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final docs = snapshot.data!.docs;

                    if (docs.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.only(left: 20),
                        child: Text(
                          'No packages available yet.',
                          style: TextStyle(color: Colors.grey),
                        ),
                      );
                    }

                    return ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.only(left: 20),
                      itemCount: docs.length,
                      itemBuilder: (context, index) {
                        var data = docs[index].data() as Map<String, dynamic>;
                        return _buildHotSellingCard(context, data);
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const Icon(
            Icons.arrow_forward_ios,
            color: Color(0xFFC084FC),
            size: 18,
          ),
        ],
      ),
    );
  }

  // Widget _buildPromoCard(BuildContext context) {
  //   return GestureDetector(
  //     onTap: () {
  //       Navigator.push(
  //         context,
  //         MaterialPageRoute(
  //           builder: (context) => const PackageDetailPage(
  //             packageName: 'Shell Out (Promo)',
  //             price: 'RM25/Pax',
  //             imageUrl:
  //                 'https://img.freepik.com/free-photo/shrimp-cajun-butter-sauce_1147-458.jpg',
  //             description:
  //                 'Enjoy our special Shell Out promo with a variety of seafood and sides, perfect for any occasion.',
  //           ),
  //         ),
  //       );
  //     },
  //     child: Container(
  //       width: 280,
  //       margin: const EdgeInsets.only(right: 15),
  //       child: ClipRRect(
  //         borderRadius: BorderRadius.circular(15),
  //         child: Image.network(
  //           'https://img.freepik.com/free-photo/shrimp-cajun-butter-sauce_1147-458.jpg',
  //           fit: BoxFit.cover,
  //         ),
  //       ),
  //     ),
  //   );
  // }

  // UPDATED: Now accepts dynamic Firestore data
  Widget _buildHotSellingCard(BuildContext context, Map<String, dynamic> data) {
    return InkWell(
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
      child: Container(
        width: 280,
        margin: const EdgeInsets.only(right: 15),
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
                child: Image.network(
                  data['imageUrl'] ?? '',
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      const Icon(Icons.broken_image),
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
                  Text(
                    data['packageName'] ?? 'Unnamed Package',
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
    );
  }
}
