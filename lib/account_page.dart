import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Page Imports
import 'home_page.dart';
import 'packages_page.dart';
import 'my_reservation_page.dart';
import 'user_list_page.dart';
import 'admin_packages_page.dart';
import 'admin_home_page.dart';
import 'admin_reservations_page.dart';
import 'welcome_page.dart';

class AccountPage extends StatefulWidget {
  final bool isAdmin;
  final bool isGuest;
  const AccountPage({super.key, this.isAdmin = false, this.isGuest = true});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    // When login, default to Home tab
    _selectedIndex = 0;
  }

  // 1. Logout Logic
  Future<void> _handleLogout() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const WelcomePage()),
        (route) => false,
      );
    }
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  // Define Navigation Items
  List<BottomNavigationBarItem> get _userItems => [
    const BottomNavigationBarItem(
      icon: Icon(Icons.home_outlined),
      label: 'Home',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.book_outlined),
      label: 'Packages',
    ),
    if (!widget.isGuest) // Hide for guests
      const BottomNavigationBarItem(
        icon: Icon(Icons.calendar_month_outlined),
        label: 'My Reservations',
      ),
    const BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Account'),
  ];

  List<BottomNavigationBarItem> get _adminItems => const [
    BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Home'),
    BottomNavigationBarItem(icon: Icon(Icons.book_outlined), label: 'Packages'),
    BottomNavigationBarItem(icon: Icon(Icons.people_outline), label: 'Users'),
    BottomNavigationBarItem(
      icon: Icon(Icons.assignment_outlined),
      label: 'Reservations',
    ),
    BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Account'),
  ];

  List<Widget> get _screens => widget.isAdmin ? _adminScreens : _userScreens;

  List<Widget> get _adminScreens => [
    AdminHomePage(onTabChange: _onItemTapped),
    const AdminPackagesPage(),
    const UserListPage(),
    const AdminReservationsPage(),
    _buildProfileContent(),
  ];

  List<Widget> get _userScreens => [
    const HomePage(),
    const PackagesPage(),
    MyReservationsPage(onExplorePackages: () => _onItemTapped(1)),
    _buildProfileContent(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFFC084FC),
        unselectedItemColor: Colors.grey,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: widget.isAdmin ? _adminItems : _userItems,
      ),
    );
  }

  Widget _buildProfileContent() {
    final user = FirebaseAuth.instance.currentUser;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
        child: Column(
          children: [
            // Dynamic User Profile Card
            StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(user?.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                var userData = snapshot.data?.data() as Map<String, dynamic>?;
                String name = userData?['fullName'] ?? 'Guest User';
                String email = userData?['email'] ?? 'Not Logged In';

                return _buildShadowCard(
                  child: ListTile(
                    leading: const CircleAvatar(
                      radius: 30,
                      backgroundColor: Color(0xFFC084FC),
                      child: Icon(Icons.person, color: Colors.white, size: 30),
                    ),
                    title: Text(
                      name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    subtitle: Text(
                      email,
                      style: const TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                    trailing: const Icon(Icons.notifications_none, size: 30),
                  ),
                );
              },
            ),

            const SizedBox(height: 20),
            _buildShadowCard(
              child: ListTile(
                leading: const Icon(Icons.person_outline),
                title: const Text('Account setting'),
                trailing: const Icon(Icons.edit_outlined),
                onTap: () {},
              ),
            ),
            const SizedBox(height: 20),
            _buildShadowCard(
              child: Column(
                children: [
                  _buildMenuTile(Icons.translate, 'Language'),
                  const Divider(height: 1),
                  _buildMenuTile(Icons.chat_bubble_outline, 'Feedback'),
                  const Divider(height: 1),
                  _buildMenuTile(Icons.star_border, 'Rate us'),
                  const Divider(height: 1),
                  _buildMenuTile(Icons.arrow_upward, 'New Version'),
                ],
              ),
            ),
            const SizedBox(height: 40),

            SizedBox(
              width: 160,
              height: 50,
              child: ElevatedButton(
                onPressed: _handleLogout,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEF4444),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Logout',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShadowCard({required Widget child}) {
    return Container(
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
      child: child,
    );
  }

  Widget _buildMenuTile(IconData icon, String title) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF374151)),
      title: Text(title, style: const TextStyle(color: Color(0xFF374151))),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: () {},
    );
  }
}
