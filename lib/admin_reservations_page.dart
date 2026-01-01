import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'admin_reservation_detail_page.dart';

class AdminReservationsPage extends StatelessWidget {
  const AdminReservationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    String todayDate = DateFormat('dd / MM / yyyy').format(DateTime.now());

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(25, 20, 25, 10),
                child: Text(
                  'Reservation List',
                  style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
                ),
              ),
              _buildSearchBar(),
              const TabBar(
                labelColor: Color(0xFFC084FC),
                unselectedLabelColor: Colors.grey,
                indicatorColor: Color(0xFFC084FC),
                indicatorSize: TabBarIndicatorSize.label,
                isScrollable: true,
                labelStyle: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
                tabs: [
                  Tab(text: 'TODAY'),
                  Tab(text: 'ALL'),
                  Tab(text: 'COMPLETED'),
                  Tab(text: 'CANCELLED'),
                ],
              ),
              const Divider(height: 1, color: Colors.grey),
              Expanded(
                child: TabBarView(
                  children: [
                    _buildFirestoreReservationList(
                      dateFilter: todayDate,
                      statusFilter: 'upcoming',
                    ),
                    _buildFirestoreReservationList(statusFilter: 'upcoming'),
                    _buildFirestoreReservationList(statusFilter: 'completed'),
                    _buildFirestoreReservationList(statusFilter: 'cancelled'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFirestoreReservationList({
    String? dateFilter,
    String? statusFilter,
  }) {
    Query query = FirebaseFirestore.instance.collection('reservations');

    if (dateFilter != null) {
      query = query.where('date', isEqualTo: dateFilter);
    }
    if (statusFilter != null) {
      query = query.where('status', isEqualTo: statusFilter);
    }

    return StreamBuilder<QuerySnapshot>(
      stream: query.orderBy('createdAt', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text('Error loading reservations'));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFFC084FC)),
          );
        }
        if (snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text(
              'No reservations found',
              style: TextStyle(color: Colors.grey),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(25),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            var doc = snapshot.data!.docs[index];
            var data = doc.data() as Map<String, dynamic>;
            return _buildReservationCard(context, data, doc.id);
          },
        );
      },
    );
  }

  Widget _buildReservationCard(
    BuildContext context,
    Map<String, dynamic> data,
    String docId,
  ) {
    String status = data['status'] ?? 'upcoming';
    Color statusColor = status == 'completed'
        ? Colors.green
        : const Color(0xFFC084FC);
    String userId = data['userId'] ?? ''; // Added to fetch user info

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.network(
              data['imageUrl'] ??
                  'https://img.freepik.com/free-photo/shrimp-cajun-butter-sauce_1147-458.jpg',
              height: 60,
              width: 60,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Logic to show the Customer Name
                FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance
                      .collection('users')
                      .doc(userId)
                      .get(),
                  builder: (context, userSnapshot) {
                    String customerName = "Loading...";
                    if (userSnapshot.hasData && userSnapshot.data!.exists) {
                      var userData =
                          userSnapshot.data!.data() as Map<String, dynamic>;
                      customerName = userData['fullName'] ?? 'Unknown User';
                    }
                    return Text(
                      customerName,
                      style: const TextStyle(
                        color: Color(0xFFC084FC),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 2),
                // Status Badge Row
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text(
                        status.toUpperCase(),
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  data['packageName'] ?? 'N/A',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Color(0xFF1F2937),
                  ),
                ),
                Text(
                  'ID: ${data['orderId']}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 11),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 35,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AdminReservationDetailPage(
                      reservationId: docId,
                      data: data,
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFC084FC),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'View',
                style: TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25.0, vertical: 10),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Search by Order ID',
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
