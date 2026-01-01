import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; //
import 'package:intl/intl.dart';

class AdminHomePage extends StatelessWidget {
  final Function(int) onTabChange;

  const AdminHomePage({super.key, required this.onTabChange});

  @override
  Widget build(BuildContext context) {
    // Format today's date to match our Firestore 'date' field format
    String todayStr = DateFormat('dd / MM / yyyy').format(DateTime.now());

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(25.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Admin Dashboard',
                    style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 30),

              const Text(
                'Status',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 15),

              // 1. Dynamic Status Card
              _buildDynamicStatusCard(todayStr),

              const SizedBox(height: 40),

              const Text(
                'Manage',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 15),

              _buildManageCard(
                title: 'Manage Menu package',
                onTap: () => onTabChange(1),
              ),
              _buildManageCard(
                title: 'Manage User',
                onTap: () => onTabChange(2),
              ),
              _buildManageCard(
                title: 'View Reservation',
                onTap: () => onTabChange(3),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 2. Helper to fetch real counts from Firestore
  Widget _buildDynamicStatusCard(String todayDate) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Row for Today's Bookings
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('reservations')
                .where('date', isEqualTo: todayDate)
                .snapshots(),
            builder: (context, snapshot) {
              String count = snapshot.hasData
                  ? snapshot.data!.docs.length.toString()
                  : '...';
              return _buildStatusRow('New Reservations\n(Today)', count);
            },
          ),
          const Divider(height: 30),
          // Row for Total All-Time Bookings
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('reservations')
                .snapshots(),
            builder: (context, snapshot) {
              String count = snapshot.hasData
                  ? snapshot.data!.docs.length.toString()
                  : '...';
              return _buildStatusRow('Total Bookings\n(Overall)', count);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatusRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFF3E8FF), // Light purple for value background
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFFC084FC),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildManageCard({
    required String title,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
              child: Image.network(
                'https://images.squarespace-cdn.com/content/v1/570a72d222482e7442eda206/6f3b5a32-cd75-4e09-abff-18a0257db569/annette-dining-room-hero.jpg',
                height: 150,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_ios,
                    size: 18,
                    color: Color(0xFFC084FC),
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
