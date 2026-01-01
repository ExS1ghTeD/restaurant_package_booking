import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NewPackagePage extends StatefulWidget {
  const NewPackagePage({super.key});

  @override
  State<NewPackagePage> createState() => _NewPackagePageState();
}

class _NewPackagePageState extends State<NewPackagePage> {
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  // 1. Added controller for Image URL to satisfy CRUD requirements
  final TextEditingController _imageController = TextEditingController();

  bool _isLoading = false;

  Future<void> _savePackage() async {
    // 2. Updated validation to include the image field
    if (_categoryController.text.trim().isEmpty ||
        _nameController.text.trim().isEmpty ||
        _priceController.text.trim().isEmpty ||
        _imageController.text.trim().isEmpty ||
        _descController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await FirebaseFirestore.instance.collection('packages').add({
        'category': _categoryController.text.trim(),
        'packageName': _nameController.text.trim(),
        'price': double.parse(_priceController.text.trim()),
        'description': _descController.text.trim(),
        // 3. Save the actual URL entered by the Admin
        'imageUrl': _imageController.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Package added successfully!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error saving package: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _categoryController.dispose();
    _nameController.dispose();
    _priceController.dispose();
    _descController.dispose();
    _imageController.dispose(); //
    super.dispose();
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
          'Add New Package',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(25.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildImagePlaceholder(),
            const SizedBox(height: 30),

            _buildLabel('Package Category'),
            _buildTextField(_categoryController, 'e.g., Shell Out'),

            const SizedBox(height: 20),
            _buildLabel('Package Name'),
            _buildTextField(
              _nameController,
              'e.g., The Spicy Cajun Garlic Butter',
            ),

            const SizedBox(height: 20),
            _buildLabel('Price (RM) per Pax'),
            _buildTextField(_priceController, 'e.g., 35', isNumber: true),

            const SizedBox(height: 20),
            // 4. Added Image URL input field
            _buildLabel('Image URL'),
            _buildTextField(
              _imageController,
              'Paste image direct link here...',
            ),

            const SizedBox(height: 20),
            _buildLabel('Description'),
            _buildTextField(
              _descController,
              'Describe the menu contents...',
              maxLines: 4,
            ),

            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _savePackage,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFC084FC),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  elevation: 5,
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Save Package',
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

  // UI Helpers remain same...
  Widget _buildImagePlaceholder() {
    return Container(
      height: 150,
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFC084FC).withOpacity(0.3)),
      ),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.image_search, size: 40, color: Color(0xFFC084FC)),
          SizedBox(height: 10),
          Text(
            'Enter URL below to set image',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String hint, {
    bool isNumber = false,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      maxLines: maxLines,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: const Color(0xFFF9FAFB),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
