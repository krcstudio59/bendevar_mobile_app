import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _userData;
  List<DocumentSnapshot> _userItems = [];
  List<DocumentSnapshot> _userRequests = [];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final userDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(FirebaseAuth.instance.currentUser?.uid)
              .get();

      final itemsQuery =
          await FirebaseFirestore.instance
              .collection('items')
              .where(
                'userId',
                isEqualTo: FirebaseAuth.instance.currentUser?.uid,
              )
              .get();

      final requestsQuery =
          await FirebaseFirestore.instance
              .collection('requests')
              .where(
                'userId',
                isEqualTo: FirebaseAuth.instance.currentUser?.uid,
              )
              .get();

      setState(() {
        _userData = userDoc.data();
        _userItems = itemsQuery.docs;
        _userRequests = requestsQuery.docs;
        _isLoading = false;
      });
    } catch (e) {
      print('Kullanıcı bilgileri yüklenirken hata: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Hesabım')),
      body: RefreshIndicator(
        onRefresh: _loadUserData,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profil Bilgileri
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _userData?['username'] ?? 'Kullanıcı',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Puan: ${_userData?['score'] ?? 0}',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Paylaşılan Ürünler
              const Text(
                'Paylaştığım Ürünler',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              if (_userItems.isEmpty)
                const Center(child: Text('Henüz ürün paylaşmadınız'))
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _userItems.length,
                  itemBuilder: (context, index) {
                    final item =
                        _userItems[index].data() as Map<String, dynamic>;
                    return Card(
                      child: ListTile(
                        leading:
                            item['imageUrl'] != null
                                ? Image.network(
                                  item['imageUrl'],
                                  width: 50,
                                  height: 50,
                                  fit: BoxFit.cover,
                                )
                                : const Icon(Icons.image),
                        title: Text(item['title'] ?? ''),
                        subtitle: Text(item['description'] ?? ''),
                        trailing: Text(
                          item['isAvailable'] ? 'Müsait' : 'Alındı',
                          style: TextStyle(
                            color:
                                item['isAvailable'] ? Colors.green : Colors.red,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              const SizedBox(height: 24),

              // Talepler
              const Text(
                'Taleplerim',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              if (_userRequests.isEmpty)
                const Center(child: Text('Henüz talep oluşturmadınız'))
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _userRequests.length,
                  itemBuilder: (context, index) {
                    final request =
                        _userRequests[index].data() as Map<String, dynamic>;
                    return Card(
                      child: ListTile(
                        title: Text(request['title'] ?? ''),
                        subtitle: Text(request['description'] ?? ''),
                        trailing: Text(
                          request['isActive'] ? 'Aktif' : 'Tamamlandı',
                          style: TextStyle(
                            color:
                                request['isActive']
                                    ? Colors.green
                                    : Colors.grey,
                          ),
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}
