import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import 'auth_screen.dart';
import '../utils/app_colors.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isLoading = true;
  bool _isEditing = false;
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _schoolController = TextEditingController();
  final _facultyController = TextEditingController();
  final _departmentController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  String? _profileImageUrl;

  final _phoneMaskFormatter = MaskTextInputFormatter(
    mask: '(###) ### ## ##',
    filter: {"#": RegExp(r'[0-9]')},
    type: MaskAutoCompletionType.lazy,
  );

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() => _isLoading = false);
        print('SettingsScreen: Current user is null.');
        return;
      }

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (userDoc.exists) {
        final data = userDoc.data()!;
        final initialPhoneNumber = data['phoneNumber'] ?? '';
        _phoneController.text =
            _phoneMaskFormatter.maskText(initialPhoneNumber);

        setState(() {
          _firstNameController.text = data['firstName'] ?? '';
          _lastNameController.text = data['lastName'] ?? '';
          _emailController.text = data['email'] ?? '';
          _addressController.text = data['address'] ?? '';
          _profileImageUrl = data['profileImageUrl'];

          if (data['studentInfo'] != null) {
            final studentInfoData = data['studentInfo'] as Map<String, dynamic>;
            _schoolController.text = studentInfoData['schoolName'] ?? '';
            _facultyController.text = studentInfoData['faculty'] ?? '';
            _departmentController.text = studentInfoData['department'] ?? '';
          } else {
            _schoolController.text = '';
            _facultyController.text = '';
            _departmentController.text = '';
          }
          _isLoading = false;
        });
      } else {
        setState(() {
          _firstNameController.text = '';
          _lastNameController.text = '';
          _phoneController.text = '';
          _schoolController.text = '';
          _facultyController.text = '';
          _departmentController.text = '';
          _emailController.text =
              FirebaseAuth.instance.currentUser?.email ?? '';
          _addressController.text = '';
          _profileImageUrl = null;
          _isLoading = false;
        });
        print('SettingsScreen: User document does not exist in Firestore.');
      }
    } catch (e) {
      print('Kullanıcı bilgileri yüklenirken hata: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickProfileImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);

      if (image != null) {
        setState(() => _isLoading = true);
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) {
          setState(() => _isLoading = false);
          return;
        }

        final storageRef = FirebaseStorage.instance
            .ref()
            .child('profile_pictures')
            .child('${user.uid}.jpg');

        await storageRef.putFile(File(image.path));
        final downloadUrl = await storageRef.getDownloadURL();

        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({'profileImageUrl': downloadUrl});

        setState(() {
          _profileImageUrl = downloadUrl;
          _isLoading = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Profil fotoğrafı başarıyla güncellendi')),
          );
        }
      }
    } catch (e) {
      print('Profil fotoğrafı yüklenirken hata: $e');
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Profil fotoğrafı yüklenirken bir hata oluştu')),
        );
      }
    }
  }

  Future<void> _saveSettings() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      final unmaskedPhoneNumber = _phoneMaskFormatter.getUnmaskedText();

      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) {
          setState(() => _isLoading = false);
          return;
        }

        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'firstName': _firstNameController.text.trim(),
          'lastName': _lastNameController.text.trim(),
          'phoneNumber': unmaskedPhoneNumber,
          'studentInfo': {
            'schoolName': _schoolController.text,
            'faculty': _facultyController.text,
            'department': _departmentController.text,
          },
          'email': _emailController.text.trim(),
          'address': _addressController.text.trim(),
        }, SetOptions(merge: true));

        setState(() {
          _isEditing = false;
          _isLoading = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Ayarlar başarıyla kaydedildi')),
          );
        }
      } catch (e) {
        print('Ayarlar kaydedilirken hata: $e');
        setState(() => _isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Ayarlar kaydedilirken bir hata oluştu')),
          );
        }
      }
    }
  }

  Widget _buildInfoField({
    required String label,
    required TextEditingController controller,
    required String? Function(String?) validator,
    bool enabled = true,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        validator: validator,
        enabled: _isEditing && enabled,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ayarlar'),
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => setState(() => _isEditing = true),
            )
          else
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _saveSettings,
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile Picture Section
              if (_isEditing)
                Center(
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundImage: _profileImageUrl != null
                            ? NetworkImage(_profileImageUrl!)
                            : null,
                        backgroundColor: Colors.grey[200],
                        child: _profileImageUrl == null
                            ? Icon(Icons.person,
                                size: 50, color: Colors.grey[400])
                            : null,
                      ),
                      TextButton.icon(
                        icon: const Icon(Icons.camera_alt),
                        label: const Text('Profil Fotoğrafını Değiştir'),
                        onPressed: _pickProfileImage,
                      ),
                    ],
                  ),
                ),
              if (_isEditing) const SizedBox(height: 24),

              // User Info Section
              const Text(
                'Kişisel Bilgiler',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              _buildInfoField(
                label: 'Ad',
                controller: _firstNameController,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Ad boş bırakılamaz';
                  }
                  return null;
                },
              ),
              _buildInfoField(
                label: 'Soyad',
                controller: _lastNameController,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Soyad boş bırakılamaz';
                  }
                  return null;
                },
              ),
              _buildInfoField(
                label: 'Telefon Numarası',
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                inputFormatters: [_phoneMaskFormatter],
                validator: (value) {
                  final unmaskedText = _phoneMaskFormatter.getUnmaskedText();
                  if (unmaskedText.isNotEmpty && unmaskedText.length != 10) {
                    return 'Telefon numarası 10 haneli olmalı';
                  }
                  if (unmaskedText.isNotEmpty &&
                      !unmaskedText.startsWith('5')) {
                    return 'Telefon numarası 5 ile başlamalı';
                  }
                  return null;
                },
              ),
              _buildInfoField(
                label: 'E-posta',
                controller: _emailController,
                enabled: false,
                validator: (value) => null,
              ),
              _buildInfoField(
                label: 'Adres',
                controller: _addressController,
                keyboardType: TextInputType.multiline,
                validator: (value) => null,
              ),
              const SizedBox(height: 24),

              // Student Info Section
              const Text(
                'Okul Bilgileri',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _buildInfoField(
                label: 'Okul',
                controller: _schoolController,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Okul adı gerekli';
                  }
                  return null;
                },
              ),
              _buildInfoField(
                label: 'Fakülte',
                controller: _facultyController,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Fakülte adı gerekli';
                  }
                  return null;
                },
              ),
              _buildInfoField(
                label: 'Bölüm',
                controller: _departmentController,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Bölüm adı gerekli';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 40),

              // Logout Button
              Center(
                child: TextButton(
                  onPressed: () async {
                    // Show confirmation dialog
                    final bool? confirmLogout = await showDialog<bool>(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: const Text('Çıkış Yap'),
                          content: const Text(
                              'Çıkış yapmak istediğinizden emin misiniz?'),
                          actions: <Widget>[
                            TextButton(
                              child: const Text('İptal'),
                              onPressed: () {
                                Navigator.of(context)
                                    .pop(false); // Return false
                              },
                            ),
                            TextButton(
                              child: const Text(
                                'Çıkış Yap',
                                style: TextStyle(color: Colors.red),
                              ),
                              onPressed: () {
                                Navigator.of(context).pop(true); // Return true
                              },
                            ),
                          ],
                        );
                      },
                    );

                    // If confirmed, proceed with logout
                    if (confirmLogout == true) {
                      try {
                        await context.read<AuthService>().signOut();
                        // Navigate to AuthScreen and remove all previous routes
                        if (mounted) {
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(
                                builder: (context) => const AuthScreen()),
                            (Route<dynamic> route) =>
                                false, // Remove all routes
                          );
                        }
                      } catch (e) {
                        print("Çıkış yaparken hata: $e");
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                  'Çıkış yapılırken bir hata oluştu: ${e.toString()}'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    }
                  },
                  child: const Text(
                    'Çıkış Yap',
                    style: TextStyle(
                      color: AppColors.bordo,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _schoolController.dispose();
    _facultyController.dispose();
    _departmentController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    super.dispose();
  }
}
