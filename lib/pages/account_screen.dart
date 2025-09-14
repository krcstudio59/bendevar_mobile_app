import 'package:bendevar_mobile_app/services/ilan_service.dart';
import 'package:bendevar_mobile_app/widgets/ilan_card.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../models/ilan_model.dart';
import '../models/user_model.dart';
import 'settings_screen.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  UserModel? _currentUserData;
  bool _isUserLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    if (!mounted) return;
    setState(() => _isUserLoading = true);
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) setState(() => _isUserLoading = false);
      return;
    }
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (userDoc.exists && mounted) {
        setState(() {
          _currentUserData = UserModel.fromJson(userDoc.data()!, userDoc.id);
        });
      }
    } catch (e) {
      print("Kullanıcı verisi yüklenemedi: $e");
    } finally {
      if (mounted) setState(() => _isUserLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadUserData,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (_isUserLoading)
              const Center(child: CircularProgressIndicator())
            else if (_currentUserData != null)
              _buildProfileHeader()
            else
              const Center(child: Text('Kullanıcı bilgileri yüklenemedi.')),

            const SizedBox(height: 24),
            _buildStatsCard(),
            const SizedBox(height: 24),
            // "Paylaştığım Ürünler" başlığı ve listesi
            Text('Paylaştığım Ürünler',
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            if (user != null)
              _buildUserIlanlar(user.uid)
            else
              const Center(
                  child: Text('İlanlarınızı görmek için giriş yapmalısınız.')),
          ],
        ),
      ),
    );
  }

  Widget _buildUserIlanlar(String userId) {
    final ilanService = context.watch<IlanService>();
    return StreamBuilder<List<Ilan>>(
      stream: ilanService.getKullanicininIlanlari(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
              child: Text(
                  'İlanlar yüklenirken bir hata oluştu: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: Text(
                'Henüz hiç ilan paylaşmadınız.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ),
          );
        }

        final ilanlar = snapshot.data!;
        return ListView.builder(
          shrinkWrap: true, // ListView içinde ListView için önemli
          physics:
              const NeverScrollableScrollPhysics(), // Ana ListView scroll'unu kullan
          itemCount: ilanlar.length,
          itemBuilder: (context, index) {
            final ilan = ilanlar[index];
            return IlanCard(ilan: ilan); // Yeniden kullanılabilir kartımız
          },
        );
      },
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
}
