import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';

class MitraFormDataPage extends StatefulWidget {
  const MitraFormDataPage({Key? key}) : super(key: key);

  @override
  State<MitraFormDataPage> createState() => _MitraFormDataPageState();
}

class _MitraFormDataPageState extends State<MitraFormDataPage> {
  final _formKey = GlobalKey<FormState>();

  final namaC = TextEditingController();
  final ktpC = TextEditingController();
  final hpC = TextEditingController();
  final alamatC = TextEditingController();
  final pengalamanC = TextEditingController();
  final deskripsiC = TextEditingController();
  final rekeningC = TextEditingController();
  final bankC = TextEditingController();
  final namaRekeningC = TextEditingController();
  final coverageC = TextEditingController();

  List<String> selectedKeahlian = [];
  String? gender;

  File? fotoKtpFile;
  File? fotoDiriFile;
  final ImagePicker picker = ImagePicker();

  bool isLoading = false;

  final List<String> _keahlianList = [
    'Listrik',
    'AC',
    'Pipa / Plumbing',
    'Bangunan / Renovasi',
    'Tukang Kebun',
    'Bersih-Bersih Rumah',
    'Cuci Piring / Dapur',
    'Setrika & Laundry',
  ];

  Future<void> pickImage(bool isKtp) async {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Ambil dari Kamera'),
              onTap: () async {
                Navigator.pop(context);
                final picked = await picker.pickImage(
                  source: ImageSource.camera,
                );
                if (picked != null) {
                  setState(
                    () => isKtp
                        ? fotoKtpFile = File(picked.path)
                        : fotoDiriFile = File(picked.path),
                  );
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo),
              title: const Text('Pilih dari Galeri'),
              onTap: () async {
                Navigator.pop(context);
                final picked = await picker.pickImage(
                  source: ImageSource.gallery,
                );
                if (picked != null) {
                  setState(
                    () => isKtp
                        ? fotoKtpFile = File(picked.path)
                        : fotoDiriFile = File(picked.path),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<String?> uploadToCloudinary(File imageFile) async {
    const cloudName = 'daxhkfgil';
    const uploadPreset = 'home_service';

    final url = Uri.parse(
      'https://api.cloudinary.com/v1_1/$cloudName/image/upload',
    );
    final request = http.MultipartRequest('POST', url)
      ..fields['upload_preset'] = uploadPreset
      ..files.add(await http.MultipartFile.fromPath('file', imageFile.path));

    final response = await request.send();
    final resData = await response.stream.bytesToString();
    if (response.statusCode == 200) {
      final jsonRes = json.decode(resData);
      return jsonRes['secure_url'];
    } else {
      print('Gagal upload: $resData');
      return null;
    }
  }

  Future<void> simpanDataMitra() async {
    if (!_formKey.currentState!.validate()) return;

    if (fotoKtpFile == null || fotoDiriFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Foto KTP dan Foto Diri wajib diisi')),
      );
      return;
    }

    if (selectedKeahlian.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Minimal pilih satu keahlian')),
      );
      return;
    }

    setState(() => isLoading = true);
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) throw Exception("User tidak ditemukan");

      final urlKtp = await uploadToCloudinary(fotoKtpFile!);
      final urlDiri = await uploadToCloudinary(fotoDiriFile!);
      if (urlKtp == null || urlDiri == null)
        throw Exception("Gagal upload gambar");

      final data = {
        'nama': namaC.text.trim(),
        'ktp': ktpC.text.trim(),
        'hp': hpC.text.trim(),
        'alamat': alamatC.text.trim(),
        'keahlian': selectedKeahlian,
        'pengalaman': pengalamanC.text.trim(),
        'deskripsi': deskripsiC.text.trim(),
        'rekening': rekeningC.text.trim(),
        'bank': bankC.text.trim(),
        'nama_rekening': namaRekeningC.text.trim(),
        'coverage_area': coverageC.text.trim(),
        'gender': gender,
        'foto_ktp': urlKtp,
        'foto_diri': urlDiri,
        'status': 'menunggu',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance
          .collection('calon_mitras')
          .doc(uid)
          .set(data);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Data mitra berhasil disimpan')),
      );
      Navigator.pushReplacementNamed(context, '/menunggu');
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal simpan data: $e')));
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  void dispose() {
    namaC.dispose();
    ktpC.dispose();
    hpC.dispose();
    alamatC.dispose();
    pengalamanC.dispose();
    deskripsiC.dispose();
    rekeningC.dispose();
    bankC.dispose();
    namaRekeningC.dispose();
    coverageC.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue.shade800,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          'Form Calon Mitra',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 20,
          ),
        ),
      ),
      backgroundColor: Colors.grey.shade100,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildSectionTitle("Data Diri"),
              _buildFormCard([
                _buildTextField('Nama Lengkap', controller: namaC),
                _buildTextField(
                  'Nomor KTP',
                  controller: ktpC,
                  keyboardType: TextInputType.number,
                ),
                _buildTextField(
                  'Nomor HP',
                  controller: hpC,
                  keyboardType: TextInputType.phone,
                ),
                _buildTextField(
                  'Alamat Lengkap',
                  controller: alamatC,
                  maxLines: 2,
                ),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  value: gender,
                  decoration: _inputDecoration('Jenis Kelamin'),
                  items: ['Laki-laki', 'Perempuan']
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (val) => setState(() => gender = val),
                  validator: (v) => v == null ? 'Pilih jenis kelamin' : null,
                ),
                const SizedBox(height: 14),
                _buildTextField(
                  'Area Layanan / Coverage Area',
                  controller: coverageC,
                ),
              ]),

              const SizedBox(height: 16),
              _buildSectionTitle("Keahlian"),
              _buildFormCard([
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _keahlianList.map((skill) {
                    final isSelected = selectedKeahlian.contains(skill);
                    return FilterChip(
                      selected: isSelected,
                      label: Text(
                        skill,
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w500,
                          color: isSelected
                              ? Colors.white
                              : Colors.blue.shade800,
                        ),
                      ),
                      selectedColor: Colors.blue.shade700,
                      backgroundColor: Colors.grey.shade100,
                      checkmarkColor: Colors.white,
                      onSelected: (val) {
                        setState(() {
                          isSelected
                              ? selectedKeahlian.remove(skill)
                              : selectedKeahlian.add(skill);
                        });
                      },
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    );
                  }).toList(),
                ),
              ]),

              const SizedBox(height: 16),
              _buildSectionTitle("Pengalaman & Deskripsi"),
              _buildFormCard([
                _buildTextField(
                  'Pengalaman Kerja',
                  controller: pengalamanC,
                  maxLines: 2,
                ),
                _buildTextField(
                  'Deskripsi Diri Singkat',
                  controller: deskripsiC,
                  maxLines: 3,
                ),
              ]),

              const SizedBox(height: 16),
              _buildSectionTitle("Rekening Bank"),
              _buildFormCard([
                _buildTextField(
                  'Nomor Rekening',
                  controller: rekeningC,
                  keyboardType: TextInputType.number,
                ),
                _buildTextField('Nama Bank', controller: bankC),
                _buildTextField(
                  'Nama Pemilik Rekening',
                  controller: namaRekeningC,
                ),
              ]),

              const SizedBox(height: 16),
              _buildSectionTitle("Upload Dokumen"),
              _buildFormCard([
                Text(
                  'Foto KTP',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                _buildImagePicker(fotoKtpFile, () => pickImage(true)),
                const SizedBox(height: 16),
                Text(
                  'Foto Diri',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                _buildImagePicker(fotoDiriFile, () => pickImage(false)),
              ]),

              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: isLoading ? null : simpanDataMitra,
                  icon: isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.check),
                  label: Text(
                    isLoading ? 'Memproses...' : 'Kirim Data',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade800,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    String label, {
    required TextEditingController controller,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        decoration: _inputDecoration(label),
        validator: (v) => v == null || v.isEmpty ? 'Wajib diisi' : null,
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.poppins(),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    );
  }

  Widget _buildFormCard(List<Widget> children) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: children),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.blue.shade800,
        ),
      ),
    );
  }

  Widget _buildImagePicker(File? imageFile, VoidCallback onPick) {
    return Column(
      children: [
        if (imageFile != null)
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(12),
              child: Image.file(
                imageFile,
                height: 150,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
          )
        else
          Container(
            height: 150,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.shade100),
            ),
            child: Center(
              child: Icon(
                Icons.image_outlined,
                size: 40,
                color: Colors.blueGrey,
              ),
            ),
          ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: onPick,
          icon: const Icon(Icons.upload),
          label: const Text('Pilih Gambar'),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.blue.shade800,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      ],
    );
  }
}
