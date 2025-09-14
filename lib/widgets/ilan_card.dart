import 'package:bendevar_mobile_app/models/user_model.dart';
import 'package:bendevar_mobile_app/pages/ilan_detay_ekrani.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/ilan_model.dart';
import '../utils/app_colors.dart';

// Henüz oluşturulmadı, bu yüzden şimdilik placeholder bir dosya adı varsayalım
// import '../pages/ilan_detay_ekrani.dart';

class IlanCard extends StatefulWidget {
  final Ilan ilan;

  const IlanCard({super.key, required this.ilan});

  @override
  State<IlanCard> createState() => _IlanCardState();
}

class _IlanCardState extends State<IlanCard> {
  UserModel? _ilanSahibi;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchIlanSahibi();
  }

  Future<void> _fetchIlanSahibi() async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.ilan.userId)
          .get();
      if (userDoc.exists) {
        if (mounted) {
          setState(() {
            _ilanSahibi = UserModel.fromJson(userDoc.data()!, userDoc.id);
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      print("İlan sahibi bilgisi getirilirken hata: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    // Tarihi formatla
    final formattedDate = DateFormat('dd MMMM yyyy, HH:mm', 'tr_TR')
        .format(widget.ilan.olusturulmaTarihi.toDate());

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(MaterialPageRoute(
          builder: (context) => IlanDetayEkrani(ilan: widget.ilan),
        ));
      },
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 3,
        shadowColor: Colors.black.withOpacity(0.1),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Fotoğraf Alanı
            _buildImage(),
            // Bilgi Alanı
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Kategori ve Lokasyon
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildCategoryChip(widget.ilan.kategori),
                      const Spacer(),
                      Row(
                        children: [
                          Icon(Icons.location_on_outlined,
                              color: Colors.grey.shade600, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            widget.ilan.lokasyon,
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Başlık
                  Text(
                    widget.ilan.baslik,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  const Divider(),
                  const SizedBox(height: 8),
                  // Kullanıcı ve Tarih Bilgisi
                  _buildUserInfo(formattedDate),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage() {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
      child: Container(
        height: 180,
        width: double.infinity,
        color: Colors.grey.shade200,
        child: widget.ilan.fotografUrl != null &&
                widget.ilan.fotografUrl!.isNotEmpty
            ? Image.network(
                widget.ilan.fotografUrl!,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return const Center(child: CircularProgressIndicator());
                },
                errorBuilder: (context, error, stackTrace) =>
                    _buildPlaceholderIcon(),
              )
            : _buildPlaceholderIcon(),
      ),
    );
  }

  Widget _buildPlaceholderIcon() {
    IconData icon;
    switch (widget.ilan.kategori.toLowerCase()) {
      case 'kitap':
        icon = Icons.book_outlined;
        break;
      case 'mobilya':
        icon = Icons.chair_outlined;
        break;
      case 'elektronik':
        icon = Icons.electrical_services_outlined;
        break;
      default:
        icon = Icons.category_outlined;
    }
    return Center(child: Icon(icon, size: 60, color: Colors.grey.shade400));
  }

  Widget _buildCategoryChip(String category) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.bordo.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        category,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
            color: AppColors.bordo, fontWeight: FontWeight.bold, fontSize: 12),
      ),
    );
  }

  Widget _buildUserInfo(String formattedDate) {
    if (_isLoading) {
      return const Row(
        children: [
          CircleAvatar(radius: 12, backgroundColor: Colors.grey),
          SizedBox(width: 8),
          Text('Yükleniyor...'),
        ],
      );
    }
    if (_ilanSahibi == null) {
      return const Text('İlan sahibi bulunamadı',
          style: TextStyle(color: Colors.red));
    }

    // Güvenli harf alma
    String initial = '?';
    if (_ilanSahibi!.firstName != null && _ilanSahibi!.firstName!.isNotEmpty) {
      initial = _ilanSahibi!.firstName![0];
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 12,
              backgroundColor: AppColors.bordo,
              child: Text(
                initial,
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${_ilanSahibi!.firstName ?? 'Bilinmeyen'} ${_ilanSahibi!.lastName ?? 'Kullanıcı'}',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ],
        ),
        Text(
          formattedDate,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        )
      ],
    );
  }
}
