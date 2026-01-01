import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class EditReservationPage extends StatefulWidget {
  final String reservationId;
  final Map<String, dynamic> currentData;

  const EditReservationPage({
    super.key,
    required this.reservationId,
    required this.currentData,
  });

  @override
  State<EditReservationPage> createState() => _EditReservationPageState();
}

class _EditReservationPageState extends State<EditReservationPage> {
  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;
  late int _pax;
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    try {
      // 1. Safely parse existing date
      _selectedDate = DateFormat('dd / MM / yyyy').parse(
        widget.currentData['date'] ??
            DateFormat('dd / MM / yyyy').format(DateTime.now()),
      );

      // 2. Safely parse existing time
      final timeStr = widget.currentData['time'] ?? "12:00 PM";
      _selectedTime = TimeOfDay.fromDateTime(DateFormat.jm().parse(timeStr));

      // 3. Ensure we use 'pax' to match your Firestore field
      _pax = widget.currentData['pax'] ?? 1;
    } catch (e) {
      _selectedDate = DateTime.now();
      _selectedTime = const TimeOfDay(hour: 12, minute: 0);
      _pax = 1;
      debugPrint("Parsing error: $e");
    }
  }

  // 4. Robust price cleaning logic
  double get _numericPrice {
    String priceStr = widget.currentData['packagePrice']?.toString() ?? "0";
    // Keep only numbers and decimal points to avoid RM170.64 errors
    String cleanPrice = priceStr.replaceAll(RegExp(r'[^0-9.]'), '');
    return double.tryParse(cleanPrice) ?? 0.0;
  }

  // 5. Logic to pick a new date
  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(DateTime.now().year + 5),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  // 6. Logic to change number of people
  void _selectPax() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Number of Pax'),
        content: TextField(
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(hintText: "Enter number of people"),
          onChanged: (value) => _pax = int.tryParse(value) ?? _pax,
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {}); // Recalculates the total in build()
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  // 7. Save changes to Firebase
  Future<void> _updateBooking() async {
    if (_numericPrice == 0.0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error: Could not retrieve base package price.'),
        ),
      );
      return;
    }

    setState(() => _isUpdating = true);

    double baseCalculation = _pax * _numericPrice;
    double newTotal = baseCalculation * 1.08; // Math: (Price * Pax) + 8%

    try {
      await FirebaseFirestore.instance
          .collection('reservations')
          .doc(widget.reservationId)
          .update({
            'date': DateFormat('dd / MM / yyyy').format(_selectedDate),
            'time': _selectedTime.format(context),
            'pax': _pax, // Corrected field name
            'totalPrice': 'RM ${newTotal.toStringAsFixed(2)}',
          });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Reservation Updated!')));
      }
    } catch (e) {
      debugPrint("Update error: $e");
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // This recalculates automatically whenever setState is called
    double currentTotal = _pax * _numericPrice * 1.08;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "Edit Reservation",
          style: TextStyle(color: Colors.black),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFFC084FC)),
      ),
      body: _isUpdating
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFC084FC)),
            )
          : Padding(
              padding: const EdgeInsets.all(25.0),
              child: Column(
                children: [
                  ListTile(
                    title: const Text("Date"),
                    subtitle: Text(
                      DateFormat('dd / MM / yyyy').format(_selectedDate),
                    ),
                    trailing: const Icon(Icons.edit, color: Color(0xFFC084FC)),
                    onTap: _pickDate,
                  ),
                  const Divider(),
                  ListTile(
                    title: const Text("Number of Pax"),
                    subtitle: Text("$_pax People"),
                    trailing: const Icon(Icons.group, color: Color(0xFFC084FC)),
                    onTap: _selectPax,
                  ),
                  const Divider(),
                  const Spacer(),
                  Text(
                    "New Total: RM ${currentTotal.toStringAsFixed(2)}",
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: _updateBooking,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFC084FC),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      child: const Text(
                        "Confirm Changes",
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
}
