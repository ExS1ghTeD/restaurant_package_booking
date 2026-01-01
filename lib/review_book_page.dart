import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore
import 'package:firebase_auth/firebase_auth.dart'; // Import Auth to track who is booking
import 'success_page.dart';

class ReviewBookPage extends StatefulWidget {
  final String packageName;
  final String packagePrice;
  final String date;
  final String time;
  final int pax;
  final String totalPrice;
  final String imageUrl;

  const ReviewBookPage({
    super.key,
    required this.packageName,
    required this.packagePrice,
    required this.date,
    required this.time,
    required this.pax,
    required this.totalPrice,
    required this.imageUrl,
  });

  @override
  State<ReviewBookPage> createState() => _ReviewBookPageState();
}

class _ReviewBookPageState extends State<ReviewBookPage> {
  bool _isConfirming = false;

  // Logic to save reservation to Firestore
  Future<void> _confirmBooking() async {
    setState(() => _isConfirming = true);

    try {
      final user = FirebaseAuth.instance.currentUser; // Identify the user

      if (user == null) throw 'User not logged in';

      // Create a unique Order ID
      String orderId = DateTime.now().millisecondsSinceEpoch.toString();

      // Save to 'reservations' collection
      await FirebaseFirestore.instance.collection('reservations').add({
        'userId': user.uid,
        'orderId': orderId,
        'packageName': widget.packageName,
        'imageUrl': widget.imageUrl,
        'packagePrice': widget.packagePrice,
        'date': widget.date,
        'time': widget.time,
        'pax': widget.pax,
        'totalPrice': widget.totalPrice,
        'status': 'upcoming', // Default status for new bookings
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const SuccessPage()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Booking failed: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isConfirming = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios,
            color: Color(0xFFC084FC),
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Review Booking',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(25.0),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFFDF4FF),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFFC084FC).withOpacity(0.2),
                ),
              ),
              child: Column(
                children: [
                  _buildReviewRow('Package', widget.packageName),
                  _buildReviewRow('Date', widget.date),
                  _buildReviewRow('Time', widget.time),
                  _buildReviewRow('Pax', '${widget.pax} People'),
                  const Divider(height: 30),
                  _buildReviewRow(
                    'Total Price',
                    widget.totalPrice,
                    isBold: true,
                  ),
                ],
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _isConfirming ? null : _confirmBooking,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFC084FC),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                child: _isConfirming
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Confirm Booking',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 16)),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
