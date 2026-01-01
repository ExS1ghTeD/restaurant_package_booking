import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'edit_reservation_page.dart'; // Import the new edit page

class MyReservationsPage extends StatelessWidget {
  final VoidCallback onExplorePackages;
  const MyReservationsPage({super.key, required this.onExplorePackages});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(25, 30, 25, 10),
                child: Text(
                  'My Reservation',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
              const TabBar(
                labelColor: Color(0xFFC084FC),
                unselectedLabelColor: Colors.grey,
                indicatorColor: Color(0xFFC084FC),
                indicatorSize: TabBarIndicatorSize.tab,
                labelStyle: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                tabs: [
                  Tab(text: 'UPCOMING'),
                  Tab(text: 'PAST'),
                ],
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    _buildReservationList(context, 'upcoming'),
                    _buildReservationList(context, 'completed'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReservationList(BuildContext context, String status) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Center(child: Text("Please login to see reservations"));
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('reservations')
          .where('userId', isEqualTo: user.uid)
          .where('status', isEqualTo: status)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFFC084FC)),
          );
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyState(context);
        }

        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            var doc = snapshot.data!.docs[index];
            var data = doc.data() as Map<String, dynamic>;
            return _buildReservationCard(context, data, doc.id, status);
          },
        );
      },
    );
  }

  // logic to show Delete Confirmation
  void _showDeleteDialog(BuildContext context, String docId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Reservation?'),
        content: const Text(
          'Are you sure you want to cancel this booking? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await FirebaseFirestore.instance
                  .collection('reservations')
                  .doc(docId)
                  .update({'status': 'cancelled'});
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Reservation cancelled.')),
                );
              }
            },
            child: const Text(
              'Yes, Cancel',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReservationCard(
    BuildContext context,
    Map<String, dynamic> data,
    String docId,
    String status,
  ) {
    bool isUpcoming = status == 'upcoming'; //

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                data['packageName'] ?? 'N/A',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              // Edit and Delete Icons for Upcoming Only
              // Inside _buildReservationCard Row
              if (isUpcoming)
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.edit_note,
                        color: Colors.blue,
                        size: 22,
                      ),
                      onPressed: () {
                        // Use a simple navigate to avoid context loops
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => EditReservationPage(
                              reservationId: docId,
                              currentData: Map<String, dynamic>.from(
                                data,
                              ), // Pass a copy
                            ),
                          ),
                        );
                      },
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.delete_outline,
                        color: Colors.red,
                        size: 22,
                      ),
                      onPressed: () => _showDeleteDialog(context, docId),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 5),
          Row(
            children: [
              const Icon(Icons.calendar_month, size: 16, color: Colors.grey),
              const SizedBox(width: 5),
              Text(
                data['date'] ?? '',
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(width: 15),
              const Icon(Icons.access_time, size: 16, color: Colors.grey),
              const SizedBox(width: 5),
              Text(
                data['time'] ?? '',
                style: const TextStyle(color: Colors.grey),
              ),
            ],
          ),
          const Divider(height: 25),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${data['pax']} Pax',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              Text(
                data['totalPrice'] ?? '',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Color(0xFFC084FC),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.calendar_today_outlined,
            size: 100,
            color: Colors.grey.withOpacity(0.3),
          ),
          const SizedBox(height: 20),
          const Text(
            'No Reservations Yet',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 30),
          OutlinedButton.icon(
            onPressed: onExplorePackages,
            icon: const Icon(Icons.search, color: Color(0xFFC084FC)),
            label: const Text(
              'Explore Packages',
              style: TextStyle(color: Color(0xFFC084FC), fontSize: 16),
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              side: const BorderSide(color: Color(0xFFC084FC)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
