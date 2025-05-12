import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import '../services/auth_service.dart';
import 'auth_screen.dart';
import 'add_item_screen.dart';
import 'add_request_screen.dart';
import 'settings_screen.dart';
import 'account_screen.dart';
import 'search_screen.dart';
import 'favorites_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isLoading = true;
  Map<String, dynamic>? _userData;
  int _selectedIndex = 0;
  List<DocumentSnapshot> _featuredItems = [];
  List<DocumentSnapshot> _latestItems = [];

  void _onItemTapped(int index) {
    if (_selectedIndex == index && index == 0 && _isLoading) {
      return;
    }
    setState(() {
      _selectedIndex = index;
      if (index == 0 && (_featuredItems.isEmpty || _latestItems.isEmpty)) {
        _loadUserData();
        _loadItems();
      }
    });
  }

  @override
  void initState() {
    super.initState();
    if (_selectedIndex == 0) {
      _loadUserData();
      _loadItems();
    }
  }

  Future<void> _loadUserData() async {
    if (_selectedIndex == 0 && mounted) setState(() => _isLoading = true);
    try {
      final user = _auth.currentUser;
      if (user == null) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (userDoc.exists && mounted) {
        setState(() {
          _userData = userDoc.data();
          if (_selectedIndex == 0) _isLoading = false;
        });
      } else if (mounted) {
        if (_selectedIndex == 0) setState(() => _isLoading = false);
      }
    } catch (e) {
      print('Kullanıcı bilgileri yüklenirken hata: $e');
      if (mounted && _selectedIndex == 0) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadItems() async {
    if (_selectedIndex == 0 && mounted) setState(() => _isLoading = true);
    try {
      final featuredQuery = await FirebaseFirestore.instance
          .collection('items')
          .orderBy('favoriteCount', descending: true)
          .limit(5)
          .get();

      final latestQuery = await FirebaseFirestore.instance
          .collection('items')
          .orderBy('createdAt', descending: true)
          .limit(5)
          .get();

      if (mounted) {
        setState(() {
          _featuredItems = featuredQuery.docs;
          _latestItems = latestQuery.docs;
          if (_selectedIndex == 0) _isLoading = false;
        });
      }
    } catch (e) {
      print('Ürünler yüklenirken hata: $e');
      if (mounted && _selectedIndex == 0) setState(() => _isLoading = false);
    }
  }

  Widget _buildHomeContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: () async {
        if (_selectedIndex == 0) {
          await _loadUserData();
          await _loadItems();
        }
      },
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Öne Çıkan Ürünler',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            SizedBox(
              height: 200,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _featuredItems.length,
                itemBuilder: (context, index) {
                  final item =
                      _featuredItems[index].data() as Map<String, dynamic>;
                  return Card(
                    margin: const EdgeInsets.all(8),
                    child: SizedBox(
                      width: 150,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (item['imageUrl'] != null)
                            Image.network(
                              item['imageUrl'],
                              height: 100,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          Padding(
                            padding: const EdgeInsets.all(8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item['title'] ?? '',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  item['description'] ?? '',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Son Eklenen Ürünler',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.all(8),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.75,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: _latestItems.length,
              itemBuilder: (context, index) {
                final item = _latestItems[index].data() as Map<String, dynamic>;
                return Card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (item['imageUrl'] != null)
                        Expanded(
                          child: Image.network(
                            item['imageUrl'],
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item['title'] ?? '',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              item['description'] ?? '',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget currentScreen;
    switch (_selectedIndex) {
      case 0:
        currentScreen = _buildHomeContent();
        break;
      case 1:
        currentScreen = const SearchScreen();
        break;
      case 2:
        currentScreen = const FavoritesScreen();
        break;
      case 3:
        currentScreen = const AccountScreen();
        break;
      case 4:
        currentScreen = const SettingsScreen();
        break;
      default:
        currentScreen = _buildHomeContent();
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_userData?['name'] ?? 'BendeVar'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await context.read<AuthService>().signOut();
              if (!mounted) return;
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => const AuthScreen()),
              );
            },
          ),
          if (_selectedIndex == 0)
            IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () {
                  _loadUserData();
                  _loadItems();
                }),
        ],
      ),
      body: currentScreen,
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Ana Sayfa',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'Ara',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite),
            label: 'Favorilerim',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Hesabım',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Ayarlar',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.deepPurple,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        onTap: _onItemTapped,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: _selectedIndex == 0
          ? Padding(
              padding: const EdgeInsets.only(bottom: 20.0),
              child: SpeedDial(
                icon: Icons.add,
                activeIcon: Icons.close,
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
                visible: true,
                curve: Curves.bounceIn,
                children: [
                  SpeedDialChild(
                    child: const Icon(Icons.check_circle_outline,
                        color: Colors.white),
                    backgroundColor: Colors.green,
                    label: 'Bende Var',
                    labelStyle:
                        const TextStyle(fontSize: 16.0, color: Colors.black),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const AddItemScreen()),
                      );
                    },
                  ),
                  SpeedDialChild(
                    child: const Icon(Icons.help_outline, color: Colors.white),
                    backgroundColor: Colors.orange,
                    label: 'Bana Lazım',
                    labelStyle:
                        const TextStyle(fontSize: 16.0, color: Colors.black),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const AddRequestScreen()),
                      );
                    },
                  ),
                ],
              ),
            )
          : null,
    );
  }
}
