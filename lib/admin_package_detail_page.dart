import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminPackageDetailPage extends StatefulWidget {
  final String packageId;
  final String initialCategory;
  final String initialName;
  final String initialPrice;
  final String initialDescription;
  final String imageUrl;

  const AdminPackageDetailPage({
    super.key,
    required this.packageId,
    required this.initialCategory,
    required this.initialName,
    required this.initialPrice,
    required this.initialDescription,
    required this.imageUrl,
  });

  @override
  State<AdminPackageDetailPage> createState() => _AdminPackageDetailPageState();
}

class _AdminPackageDetailPageState extends State<AdminPackageDetailPage> {
  late TextEditingController _categoryController;
  late TextEditingController _nameController;
  late TextEditingController _priceController;
  late TextEditingController _descController;
  // 1. Added controller for the Image URL
  late TextEditingController _imageController;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _categoryController = TextEditingController(text: widget.initialCategory);
    _nameController = TextEditingController(text: widget.initialName);
    _priceController = TextEditingController(text: widget.initialPrice);
    _descController = TextEditingController(text: widget.initialDescription);
    // 2. Initialize with existing image link
    _imageController = TextEditingController(text: widget.imageUrl);
  }

  Future<void> _updatePackage() async {
    setState(() => _isProcessing = true);
    try {
      await FirebaseFirestore.instance
          .collection('packages')
          .doc(widget.packageId)
          .update({
            'category': _categoryController.text.trim(),
            'packageName': _nameController.text.trim(),
            'price': double.parse(_priceController.text.trim()),
            'description': _descController.text.trim(),
            // 3. Save the new image URL
            'imageUrl': _imageController.text.trim(),
          });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Package Updated Successfully!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Update failed: ${e.toString()}')));
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _deletePackage() async {
    setState(() => _isProcessing = true);
    try {
      await FirebaseFirestore.instance
          .collection('packages')
          .doc(widget.packageId)
          .update({'status': 'cancelled'});

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Package Deleted.')));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Delete failed: ${e.toString()}')));
    } finally {
      if (mounted) setState(() => _isProcessing = false);
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
          'Edit Package',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                // 4. Image Preview now updates if the URL changes
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.network(
                    _imageController.text,
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: 200,
                      color: Colors.grey[200],
                      child: const Icon(
                        Icons.broken_image,
                        size: 50,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 30),

                _buildStyledInput(
                  controller: _categoryController,
                  hintText: 'Category',
                ),
                _buildStyledInput(
                  controller: _nameController,
                  hintText: 'Name',
                ),
                _buildStyledInput(
                  controller: _priceController,
                  hintText: 'Price',
                  prefixText: 'RM ',
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                ),
                // 5. Added field to change the Image URL
                _buildStyledInput(
                  controller: _imageController,
                  hintText: 'Image URL',
                  onChanged: (val) =>
                      setState(() {}), // Refresh preview on type
                ),
                _buildStyledInput(
                  controller: _descController,
                  hintText: 'Description',
                  maxLines: 5,
                ),
                const SizedBox(height: 30),

                _buildButton(
                  'Save Changes',
                  const Color(0xFFC084FC),
                  _updatePackage,
                ),
                const SizedBox(height: 20),
                _buildButton(
                  'Delete Package',
                  Colors.redAccent,
                  () => _showDeleteConfirmDialog(context),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
          if (_isProcessing)
            const Center(
              child: CircularProgressIndicator(color: Color(0xFFC084FC)),
            ),
        ],
      ),
    );
  }

  // UI Helpers...
  Widget _buildButton(String text, Color color, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        onPressed: _isProcessing ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildStyledInput({
    required TextEditingController controller,
    required String hintText,
    String? prefixText,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    Function(String)? onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        onChanged: onChanged,
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: hintText,
          prefixText: prefixText,
        ),
      ),
    );
  }

  void _showDeleteConfirmDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Package?'),
        content: const Text(
          'This action will permanently remove the menu item.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _deletePackage();
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
