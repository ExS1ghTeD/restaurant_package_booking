import 'package:flutter/material.dart';
import 'register_page.dart';
import 'login_page.dart';
import 'account_page.dart'; //

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 1. Illustration
              Center(
                child: Container(
                  height: 250,
                  width: 250,
                  decoration: BoxDecoration(
                    color: Colors.purple.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: ClipOval(
                    child: Image.network(
                      'https://img.freepik.com/premium-vector/elegant-golden-luxury-restaurant-logo-design_759312-10074.jpg?semt=ais_hybrid&w=740&q=80', // You can change this URL
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const Icon(
                        Icons.restaurant,
                        size: 80,
                        color: Colors.purple,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 30),

              // 2. Welcome Text
              const Text(
                'Welcome',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),
              const SizedBox(height: 10),

              // 3. Subtitle Text
              const Text(
                'Experience high-end dining.\nLogin or explore as a guest.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF6B7280),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 40),

              // 4. Create Account Button
              _buildButton(
                context,
                'Create Account',
                const Color(0xFFC084FC),
                Colors.white,
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const RegisterPage()),
                ),
              ),
              const SizedBox(height: 16),

              // 5. Login Button
              _buildButton(
                context,
                'Login',
                const Color(0xFFF3E8FF),
                const Color(0xFFC084FC),
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                ),
              ),
              const SizedBox(height: 20),

              // 6. GUEST BUTTON
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AccountPage(
                        isAdmin: false,
                        isGuest: true, // Guided as per assessment
                      ),
                    ),
                  );
                },
                child: const Text(
                  'Continue as Guest',
                  style: TextStyle(
                    color: Colors.grey,
                    fontWeight: FontWeight.bold,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),

              const SizedBox(height: 24),
              // Footer terms remain the same
            ],
          ),
        ),
      ),
    );
  }

  // Helper method for consistent button styling
  Widget _buildButton(
    BuildContext context,
    String text,
    Color bgColor,
    Color textColor,
    VoidCallback onPressed,
  ) {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: bgColor,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 18,
            color: textColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
