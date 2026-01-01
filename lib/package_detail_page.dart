import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Add this for Guest check
import 'review_book_page.dart';
import 'login_page.dart'; // Add this to navigate guests to login

class PackageDetailPage extends StatefulWidget {
  final String packageName;
  final String price;
  final String imageUrl;
  final String description;
  final String category;

  const PackageDetailPage({
    super.key,
    required this.packageName,
    required this.price,
    required this.imageUrl,
    required this.description,
    required this.category,
  });

  @override
  State<PackageDetailPage> createState() => _PackageDetailPageState();
}

class _PackageDetailPageState extends State<PackageDetailPage> {
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  int _pax = 0;

  double get _numericPrice {
    String cleanPrice = widget.price.replaceAll(RegExp(r'[^0-9.]'), '');
    return double.tryParse(cleanPrice) ?? 0.0;
  }

  // Helper to show the Guest Login Guide
  void _showLoginRequiredDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Login Required'),
        content: const Text(
          'You need to be registered or logged in to make a booking. Would you like to go to the login page?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const LoginPage()),
              );
            },
            child: const Text(
              'Login',
              style: TextStyle(color: Color(0xFFC084FC)),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickDate() async {
    final DateTime now = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: now,
      // Users can pick starting from today
      firstDate: now,
      // Users can pick any date up to 5 years from now
      lastDate: DateTime(now.year + 5),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFFC084FC), // Selection color
              onPrimary: Colors.white, // Text color on selection
              onSurface: Colors.black, // Default text color
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _pickTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) setState(() => _selectedTime = picked);
  }

  void _selectPax() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Number of Pax'),
        content: TextField(
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: const InputDecoration(hintText: "Enter number of people"),
          onChanged: (value) => _pax = int.tryParse(value) ?? 0,
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {});
            },
            child: const Text('OK', style: TextStyle(color: Color(0xFFC084FC))),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    String dateText = _selectedDate == null
        ? 'DD/MM/YYYY'
        : DateFormat('dd/MM/yyyy').format(_selectedDate!);
    String timeText = _selectedTime == null
        ? '00:00 AM'
        : _selectedTime!.format(context);
    String paxText = _pax == 0 ? '00 PAX' : '$_pax PAX';

    double total = _pax * _numericPrice * 1.08;

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
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 25.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.packageName,
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              widget.price,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFFC084FC),
              ),
            ),
            // Inside your build method, replace the hardcoded text:
            Text(
              widget.category, // Use the dynamic variable here
              style: const TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(height: 20),
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.network(
                widget.imageUrl,
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              widget.description, // 3. Use the dynamic variable
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 30),

            _buildBookingInput(
              label: 'Date',
              value: dateText,
              onTap: _pickDate,
            ),
            _buildBookingInput(
              label: 'Time',
              value: timeText,
              onTap: _pickTime,
            ),
            _buildBookingInput(label: 'Pax', value: paxText, onTap: _selectPax),
            _buildBookingInput(
              label: 'Total + 8%',
              value: 'RM ${total.toStringAsFixed(2)}',
              isTotal: true,
            ),

            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: () {
                  // Check if user is logged in
                  final user = FirebaseAuth.instance.currentUser;

                  if (user == null) {
                    // Show guide for Guest
                    _showLoginRequiredDialog();
                  } else if (_selectedDate != null &&
                      _selectedTime != null &&
                      _pax > 0) {
                    // Inside PackageDetailPage Book Now button
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ReviewBookPage(
                          packageName: widget.packageName,
                          packagePrice:
                              widget.price, // Pass the per-pax price here!
                          date: DateFormat(
                            'dd / MM / yyyy',
                          ).format(_selectedDate!),
                          time: _selectedTime!.format(context),
                          pax: _pax,
                          totalPrice: 'RM ${total.toStringAsFixed(2)}',
                          imageUrl: widget.imageUrl,
                        ),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Please select Date, Time, and Pax first',
                        ),
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFC084FC),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  elevation: 5,
                ),
                child: const Text(
                  'Book Now',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingInput({
    required String label,
    required String value,
    bool isTotal = false,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        decoration: BoxDecoration(
          color: isTotal ? const Color(0xFFF3E8FF) : Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: const Color(0xFFC084FC).withOpacity(0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            Text(
              value,
              style: const TextStyle(
                color: Color(0xFFC084FC),
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
