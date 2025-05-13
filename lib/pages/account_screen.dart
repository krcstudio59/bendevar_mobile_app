import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../models/user_model.dart';
import '../models/item_model.dart';
import '../models/request_model.dart';
import '../services/auth_service.dart';
import 'settings_screen.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  bool _isLoading = true;
  UserModel? _currentUserData;
  List<ItemModel> _userItems = [];
  List<RequestModel> _userRequests = [];

  final ScrollController _scrollController = ScrollController();
  final GlobalKey _userItemsKey = GlobalKey();
  final GlobalKey _userRequestsKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _loadAllUserData();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadAllUserData() async {
    print("AccountScreen: _loadAllUserData CALLED");
    if (!mounted) {
      print("AccountScreen: _loadAllUserData EXITED - NOT MOUNTED");
      return;
    }
    setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        if (mounted) setState(() => _isLoading = false);
        print("AccountScreen: _loadAllUserData EXITED - USER IS NULL");
        return;
      }

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (userDoc.exists && mounted) {
        _currentUserData = UserModel.fromJson(userDoc.data()!, userDoc.id);
      } else {
        _currentUserData = null;
      }

      final itemsQuery = await FirebaseFirestore.instance
          .collection('items')
          .where('userId', isEqualTo: user.uid)
          .orderBy('createdAt', descending: true)
          .get();
      _userItems = itemsQuery.docs
          .map((doc) => ItemModel.fromJson(doc.data(), doc.id))
          .toList();

      final requestsQuery = await FirebaseFirestore.instance
          .collection('requests')
          .where('userId', isEqualTo: user.uid)
          .orderBy('createdAt', descending: true)
          .get();
      _userRequests = requestsQuery.docs
          .map((doc) => RequestModel.fromJson(doc.data(), doc.id))
          .toList();

      if (mounted) {
        setState(() => _isLoading = false);
      }
      print("AccountScreen: _loadAllUserData SUCCESSFULLY COMPLETED");
    } catch (e) {
      print('AccountScreen: Kullanıcı verileri yüklenirken hata: $e');
      if (mounted) setState(() => _isLoading = false);
      print("AccountScreen: _loadAllUserData COMPLETED WITH ERROR");
    }
  }

  void _scrollToSection(GlobalKey key) {
    final context = key.currentContext;
    if (context != null) {
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
        alignment: 0.0,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final authService = Provider.of<AuthService>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: Text(
            ("${_currentUserData?.firstName ?? ''} ${_currentUserData?.lastName ?? ''}"
                    .trim()
                    .isNotEmpty
                ? "${_currentUserData?.firstName ?? ''} ${_currentUserData?.lastName ?? ''}"
                    .trim()
                : 'Hesabım')),
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        foregroundColor: Theme.of(context).textTheme.titleLarge?.color,
      ),
      body: RefreshIndicator(
        onRefresh: _loadAllUserData,
        child: ListView(
          controller: _scrollController,
          padding: const EdgeInsets.all(16),
          children: [
            _buildProfileHeader(),
            const SizedBox(height: 24),
            _buildStatsCard(),
            const SizedBox(height: 24),
            _buildSimplifiedMenuSection(),
            const SizedBox(height: 24),
            Container(key: _userItemsKey, child: _buildUserItemsSection()),
            const SizedBox(height: 24),
            Container(
                key: _userRequestsKey, child: _buildUserRequestsSection()),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Row(
      children: [
        CircleAvatar(
          radius: 40,
          backgroundImage: _currentUserData?.profileImageUrl != null
              ? NetworkImage(_currentUserData!.profileImageUrl!)
              : null,
          backgroundColor: Colors.grey[200],
          child: _currentUserData?.profileImageUrl == null
              ? Icon(Icons.person, size: 40, color: Colors.grey[400])
              : null,
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                ("${_currentUserData?.firstName ?? ''} ${_currentUserData?.lastName ?? ''}"
                        .trim()
                        .isNotEmpty
                    ? "${_currentUserData?.firstName ?? ''} ${_currentUserData?.lastName ?? ''}"
                        .trim()
                    : 'Kullanıcı Adı'),
                style:
                    const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                _currentUserData?.email ?? 'E-posta adresi yok',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        IconButton(
          icon: Icon(Icons.edit_outlined, color: Colors.grey[600]),
          onPressed: () {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const SettingsScreen()));
          },
        )
      ],
    );
  }

  Widget _buildStatsCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItem(Icons.star_border, 'Puan',
                _currentUserData?.score.toString() ?? '0'),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String label, String value) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 28, color: Colors.deepPurple),
        const SizedBox(height: 8),
        Text(value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildSimplifiedMenuSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildMenuListItem(Icons.rate_review_outlined, 'Yorumlarım', () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Yorumlarım tıklandı (TODO)')),
          );
        }),
      ],
    );
  }

  Widget _buildMenuListItem(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Colors.deepPurple),
      title: Text(title),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildUserItemsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Paylaştığım Ürünler',
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        if (_userItems.isEmpty)
          const Center(
              child: Padding(
            padding: EdgeInsets.symmetric(vertical: 20.0),
            child: Text('Henüz "Bende Var" ilanı paylaşmadınız.',
                style: TextStyle(color: Colors.grey)),
          ))
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _userItems.length,
            itemBuilder: (context, index) {
              final item = _userItems[index];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 6),
                elevation: 1,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
                child: ListTile(
                  leading: item.imageUrls != null && item.imageUrls!.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(4.0),
                          child: Image.network(
                            item.imageUrls!.first,
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(Icons.broken_image, size: 50),
                          ),
                        )
                      : const SizedBox(
                          width: 50,
                          height: 50,
                          child: Icon(Icons.inventory_2_outlined,
                              size: 30, color: Colors.grey)),
                  title: Text(item.title,
                      style: const TextStyle(fontWeight: FontWeight.w500)),
                  subtitle: Text(item.description,
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildUserRequestsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Taleplerim',
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        if (_userRequests.isEmpty)
          const Center(
              child: Padding(
            padding: EdgeInsets.symmetric(vertical: 20.0),
            child: Text('Henüz "Bana Lazım" talebi oluşturmadınız.',
                style: TextStyle(color: Colors.grey)),
          ))
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _userRequests.length,
            itemBuilder: (context, index) {
              final request = _userRequests[index];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 6),
                elevation: 1,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
                child: ListTile(
                  leading: const SizedBox(
                      width: 50,
                      height: 50,
                      child: Icon(Icons.receipt_long_outlined,
                          size: 30, color: Colors.grey)),
                  title: Text(request.title,
                      style: const TextStyle(fontWeight: FontWeight.w500)),
                  subtitle: Text(request.description,
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
              );
            },
          ),
      ],
    );
  }
}
