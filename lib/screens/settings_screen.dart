import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isLoading = true;
  bool _isEditing = false;
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _schoolController = TextEditingController();
  final _facultyController = TextEditingController();
  final _departmentController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  String? _studentIdUrl;

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
        setState(() {
          _usernameController.text = data['name'] ?? '';
          _phoneController.text = data['phoneNumber'] ?? '';
          _emailController.text = data['email'] ?? '';
          _addressController.text = data['address'] ?? '';

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
          _studentIdUrl = data['studentDocumentUrl'];
          _isLoading = false;
        });
      } else {
        setState(() {
          _usernameController.text = '';
          _phoneController.text = '';
          _schoolController.text = '';
          _facultyController.text = '';
          _departmentController.text = '';
          _emailController.text =
              FirebaseAuth.instance.currentUser?.email ?? '';
          _addressController.text = '';
          _studentIdUrl = null;
          _isLoading = false;
        });
        print('SettingsScreen: User document does not exist in Firestore.');
      }
    } catch (e) {
      print('Kullanıcı bilgileri yüklenirken hata: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickStudentId() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);

      if (image != null) {
        setState(() => _isLoading = true);

        final storageRef = FirebaseStorage.instance
            .ref()
            .child('student_ids')
            .child('${FirebaseAuth.instance.currentUser?.uid}.jpg');

        await storageRef.putFile(File(image.path));
        final downloadUrl = await storageRef.getDownloadURL();

        await FirebaseFirestore.instance
            .collection('users')
            .doc(FirebaseAuth.instance.currentUser?.uid)
            .update({'studentIdUrl': downloadUrl});

        setState(() {
          _studentIdUrl = downloadUrl;
          _isLoading = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Öğrenci kartı başarıyla yüklendi')),
          );
        }
      }
    } catch (e) {
      print('Öğrenci kartı yüklenirken hata: $e');
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Öğrenci kartı yüklenirken bir hata oluştu')),
        );
      }
    }
  }

  Future<void> _saveSettings() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) {
          setState(() => _isLoading = false);
          return;
        }

        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'name': _usernameController.text,
          'phoneNumber': _phoneController.text,
          'studentInfo': {
            'schoolName': _schoolController.text,
            'faculty': _facultyController.text,
            'department': _departmentController.text,
          },
          'email': _emailController.text,
          'address': _addressController.text,
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
              // Öğrenci Kartı
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Öğrenci Kartı',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (_studentIdUrl != null)
                        Image.network(
                          _studentIdUrl!,
                          height: 200,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      const SizedBox(height: 16),
                      if (_isEditing)
                        ElevatedButton.icon(
                          onPressed: _pickStudentId,
                          icon: const Icon(Icons.upload),
                          label: const Text('Öğrenci Kartı Yükle'),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Profil Bilgileri
              const Text(
                'Profil Bilgileri',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _buildInfoField(
                label: 'Kullanıcı Adı',
                controller: _usernameController,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Kullanıcı adı gerekli';
                  }
                  return null;
                },
              ),
              _buildInfoField(
                label: 'Telefon',
                controller: _phoneController,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Telefon numarası gerekli';
                  }
                  return null;
                },
              ),
              _buildInfoField(
                label: 'E-posta',
                controller: _emailController,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'E-posta adresi gerekli';
                  }
                  if (!value.contains('@')) {
                    return 'Geçerli bir e-posta adresi girin';
                  }
                  return null;
                },
              ),
              _buildInfoField(
                label: 'Adres',
                controller: _addressController,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Adres gerekli';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Okul Bilgileri
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
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _phoneController.dispose();
    _schoolController.dispose();
    _facultyController.dispose();
    _departmentController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    super.dispose();
  }
}
