import 'package:bendevar_mobile_app/models/ilan_model.dart';
import 'package:bendevar_mobile_app/models/user_model.dart';
import 'package:bendevar_mobile_app/services/firestore_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class IlanDetayEkrani extends StatefulWidget {
  final Ilan ilan;

  const IlanDetayEkrani({super.key, required this.ilan});

  @override
  State<IlanDetayEkrani> createState() => _IlanDetayEkraniState();
}

class _IlanDetayEkraniState extends State<IlanDetayEkrani> {
  UserModel? ilanSahibi;

  @override
  void initState() {
    super.initState();
    _fetchIlanSahibi();
  }

  Future<void> _fetchIlanSahibi() async {
    final firestoreService =
        Provider.of<FirestoreService>(context, listen: false);
    final user = await firestoreService.getUser(widget.ilan.userId);
    if (mounted) {
      setState(() {
        ilanSahibi = user;
      });
    }
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Arama yapılamadı. Lütfen tekrar deneyin.'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final formattedDate = DateFormat('dd MMMM yyyy, HH:mm', 'tr_TR')
        .format(widget.ilan.olusturulmaTarihi.toDate());

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 250.0,
            floating: false,
            pinned: true,
            backgroundColor: Theme.of(context).colorScheme.primary,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                widget.ilan.baslik,
                style: const TextStyle(shadows: [
                  Shadow(
                    blurRadius: 10.0,
                    color: Colors.black,
                    offset: Offset(2.0, 2.0),
                  ),
                ]),
              ),
              background: widget.ilan.fotografUrl != null &&
                      widget.ilan.fotografUrl!.isNotEmpty
                  ? Image.network(
                      widget.ilan.fotografUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const Center(child: Icon(Icons.error));
                      },
                    )
                  : Container(color: Colors.grey),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ilanSahibi != null
                      ? _buildOwnerInfo(context, formattedDate)
                      : const Center(child: CircularProgressIndicator()),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 16),
                  Text(
                    'Açıklama',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.ilan.aciklama,
                    style: TextStyle(
                        fontSize: 16, color: Colors.grey.shade800, height: 1.5),
                  ),
                  const SizedBox(height: 24),
                  _buildInfoRow(Icons.category_outlined, 'Kategori',
                      widget.ilan.kategori),
                  const SizedBox(height: 12),
                  _buildInfoRow(Icons.location_on_outlined, 'Lokasyon',
                      widget.ilan.lokasyon),
                  const SizedBox(height: 32),
                  if (ilanSahibi == null)
                    const Center(child: CircularProgressIndicator())
                  else
                    ElevatedButton.icon(
                      onPressed: () {
                        if (ilanSahibi!.phoneNumber != null &&
                            ilanSahibi!.phoneNumber!.isNotEmpty) {
                          _makePhoneCall(ilanSahibi!.phoneNumber!);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                  'Bu kullanıcının telefon numarası kayıtlı değil.'),
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.phone),
                      label: Text(
                          '${ilanSahibi!.firstName ?? ''} ${ilanSahibi!.lastName ?? ''} ile iletişime geç'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.grey.shade600),
        const SizedBox(width: 16),
        Text(
          '$label:',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 16),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildOwnerInfo(BuildContext context, String formattedDate) {
    String initial = '?';
    if (ilanSahibi?.firstName != null && ilanSahibi!.firstName!.isNotEmpty) {
      initial = ilanSahibi!.firstName![0];
    }
    return Row(
      children: [
        CircleAvatar(
          radius: 24,
          child: Text(initial, style: const TextStyle(fontSize: 20)),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${ilanSahibi!.firstName ?? ''} ${ilanSahibi!.lastName ?? ''}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'İlan Tarihi: $formattedDate',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
          ],
        ),
      ],
    );
  }
}
