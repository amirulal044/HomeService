import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:latlong2/latlong.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

class FormOrderPage extends StatefulWidget {
  const FormOrderPage({super.key});

  @override
  State<FormOrderPage> createState() => _FormOrderPageState();
}

class _FormOrderPageState extends State<FormOrderPage> {
  final _formKey = GlobalKey<FormState>();
  final deskripsiC = TextEditingController();
  final kontakAlternatifC = TextEditingController();
  final tambahanAlamatC = TextEditingController();
  final manualAlamatC = TextEditingController();
  final picker = ImagePicker();

  String? selectedJenisLokasi;
  File? fotoKondisiFile;
  bool isLoading = false;
  final mapController = MapController();
  LatLng? selectedLatLng;
  String? alamatDariMap;
  bool loadingMap = false;
  String? kategoriLayanan;

    // Tambahan Variabel untuk Harga
  Map<String, dynamic>? layananData;
  int quantity = 1; // Default 1 (bisa 1 jam, 1 unit, atau 1 kunjungan)
  double totalPrice = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Tangkap arguments sebagai Map lengkap
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    
    if (args != null) {
      layananData = args;
      kategoriLayanan = args['nama'];
      // Hitung harga awal
      _hitungTotal();
    }
  }

  void _hitungTotal() {
    if (layananData == null) return;
    setState(() {
      double basePrice = (layananData!['price'] as int).toDouble();
      // Jika tipe survey atau visit, quantity biasanya tetap 1 (sekali datang)
      // Tapi jika hourly atau unit, dikali quantity
      totalPrice = basePrice * quantity;
    });
  }

  void _updateQuantity(int delta) {
    setState(() {
      quantity += delta;
      if (quantity < 1) quantity = 1; // Minimal 1
      _hitungTotal();
    });
  } 

  Future<void> _updateAlamat(LatLng latLng) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        latLng.latitude,
        latLng.longitude,
      );
      final place = placemarks.first;
      setState(() {
        alamatDariMap =
            "${place.street}, ${place.locality}, ${place.administrativeArea}";
      });
    } catch (e) {
      setState(() => alamatDariMap = "Gagal mendapatkan alamat");
    }
  }

  Future<void> _ambilLokasiTerkini() async {
    setState(() => loadingMap = true);
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied ||
            permission == LocationPermission.deniedForever) {
          throw Exception("Izin lokasi ditolak");
        }
      }
      final posisi = await Geolocator.getCurrentPosition();
      final current = LatLng(posisi.latitude, posisi.longitude);
      setState(() => selectedLatLng = current);
      mapController.move(current, 16);
      await _updateAlamat(current);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Gagal ambil lokasi: $e")),
      );
    } finally {
      setState(() => loadingMap = false);
    }
  }

  Future<void> _cariDariManualInput() async {
    final alamat = manualAlamatC.text.trim();
    if (alamat.isEmpty) return;
    setState(() => loadingMap = true);
    try {
      List<Location> hasil = await locationFromAddress(alamat);
      if (hasil.isNotEmpty) {
        final lokasi = hasil.first;
        final latLng = LatLng(lokasi.latitude, lokasi.longitude);
        setState(() => selectedLatLng = latLng);
        mapController.move(latLng, 17.0);
        await _updateAlamat(latLng);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Gagal cari alamat: $e")),
      );
    } finally {
      setState(() => loadingMap = false);
    }
  }

  Future<String?> uploadToCloudinary(File file, String folderName, String userId) async {
    const cloudName = 'daxhkfgil';
    const uploadPreset = 'home_service';
    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
    final fileName = '${userId}_$timestamp';
    final publicId = '$folderName/$fileName';

    final url = Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload');
    final request = http.MultipartRequest('POST', url)
      ..fields['upload_preset'] = uploadPreset
      ..fields['public_id'] = publicId
      ..files.add(await http.MultipartFile.fromPath('file', file.path));

    final response = await request.send();
    final resData = await response.stream.bytesToString();
    if (response.statusCode == 200) {
      return json.decode(resData)['secure_url'];
    } else {
      debugPrint('Upload gagal: $resData');
      return null;
    }
  }

  Future<void> pickFotoKondisi() async {
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) setState(() => fotoKondisiFile = File(picked.path));
  }

  Future<void> kirimOrder() async {
    if (!_formKey.currentState!.validate()) return;
    if (selectedLatLng == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lokasi wajib diisi')),
      );
      return;
    }

    setState(() => isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("User belum login");

      final now = DateTime.now();
      String? urlFotoLokasi;
      if (fotoKondisiFile != null) {
        urlFotoLokasi = await uploadToCloudinary(
          fotoKondisiFile!,
          'order/foto_kondisi',
          user.uid,
        );
      }

      final finalAlamat = tambahanAlamatC.text.isNotEmpty
          ? '$alamatDariMap - ${tambahanAlamatC.text.trim()}'
          : alamatDariMap;

final data = {
        'user_id': user.uid,
        'email': user.email,
        'deskripsi': deskripsiC.text.trim(),
        'alamat': finalAlamat,
        'latitude': selectedLatLng!.latitude,
        'longitude': selectedLatLng!.longitude,
        'tanggal_order': now.toIso8601String(),
        'waktu_order': TimeOfDay.now().format(context),
        'jenis_lokasi': selectedJenisLokasi,
        'kontak_lain': kontakAlternatifC.text.trim(),
        'foto_kondisi': {
          'url': urlFotoLokasi,
          'keterangan': 'Foto kondisi ruangan',
        },
        'kategori': kategoriLayanan, // String nama layanan
        
        // --- DATA BARU ---
        'tipe_harga': layananData?['type'] ?? 'unknown',
        'harga_dasar': layananData?['price'] ?? 0,
        'qty_order': quantity, // Jumlah jam atau unit
        'total_estimasi': totalPrice, // Harga total awal
        // -----------------
        
        'status': 'menunggu',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance.collection('orders').add(data);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Order berhasil dikirim')),
      );
      if (context.mounted) Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal kirim order: $e')),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  void dispose() {
    deskripsiC.dispose();
    kontakAlternatifC.dispose();
    tambahanAlamatC.dispose();
    manualAlamatC.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue.shade50,
      appBar: AppBar(
        title: Text("Form Order (${kategoriLayanan ?? ''})"),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Informasi Order
              _buildOrderInfoSection(),
              const SizedBox(height: 22),
                // MASUKKAN SECTION PRICING DISINI
              _buildPricingSection(), 
              const SizedBox(height: 22),
              // Lokasi & Kontak
              _buildLokasiKontakSection(),
              const SizedBox(height: 28),
              // Tombol Kirim
              _buildSubmitButton(),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOrderInfoSection() {
    return Card(
      color: Colors.white,
      elevation: 6,
      shadowColor: Colors.blue.shade100,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.assignment_rounded, color: Colors.blue.shade700),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "Detail Order (${kategoriLayanan ?? ''})",
                    style: TextStyle(
                      color: Colors.blue.shade700,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    softWrap: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            TextFormField(
              controller: deskripsiC,
              decoration: InputDecoration(
                labelText: 'Deskripsi Pekerjaan',
                prefixIcon: Icon(Icons.description, color: Colors.blue.shade300),
                labelStyle: TextStyle(color: Colors.blue.shade700),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.blue.shade700),
                ),
              ),
              validator: (v) => v == null || v.isEmpty ? 'Wajib diisi' : null,
              maxLines: 2,
            ),
            const SizedBox(height: 18),
            Center(
              child: SizedBox(
                width: 220,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade700,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    elevation: 2,
                  ),
                  onPressed: pickFotoKondisi,
                  icon: const Icon(Icons.camera_alt),
                  label: Text(
                    fotoKondisiFile != null ? 'Ganti Foto Kondisi' : 'Upload Foto Kondisi',
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
            if (fotoKondisiFile != null)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.blue.shade100),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.shade50,
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(fotoKondisiFile!, height: 150),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLokasiKontakSection() {
    return Card(
      color: Colors.white,
      elevation: 6,
      shadowColor: Colors.blue.shade100,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.home_work_rounded, color: Colors.blue.shade700),
                const SizedBox(width: 8),
                Text(
                  "Info Lokasi & Kontak",
                  style: TextStyle(
                    color: Colors.blue.shade700,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildAlamatManualSearchField(),
            const SizedBox(height: 16),
            _buildMapView(),
            if (alamatDariMap != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    Icon(Icons.place, color: Colors.blue.shade700, size: 18),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        "Alamat: $alamatDariMap",
                        style: TextStyle(
                          fontStyle: FontStyle.italic,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 10),
            Center(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.my_location),
                label: const Text("Gunakan Lokasi Saat Ini"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade700,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                ),
                onPressed: loadingMap ? null : _ambilLokasiTerkini,
              ),
            ),
            const SizedBox(height: 20),
            DropdownButtonFormField<String>(
              value: selectedJenisLokasi,
              items: ['Rumah', 'Kantor', 'Toko', 'Apartemen']
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (val) => setState(() => selectedJenisLokasi = val),
              decoration: InputDecoration(
                labelText: 'Jenis Lokasi',
                prefixIcon: Icon(Icons.apartment, color: Colors.blue.shade300),
                labelStyle: TextStyle(color: Colors.blue.shade700),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.blue.shade700),
                ),
              ),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: kontakAlternatifC,
              decoration: InputDecoration(
                labelText: 'Kontak Alternatif',
                prefixIcon: Icon(Icons.phone, color: Colors.blue.shade300),
                labelStyle: TextStyle(color: Colors.blue.shade700),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.blue.shade700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlamatManualSearchField() {
    return Row(
      children: [
        Expanded(
          child: TextFormField(
            controller: manualAlamatC,
            decoration: InputDecoration(
              labelText: "Ketik Alamat Manual",
              prefixIcon: Icon(Icons.location_on, color: Colors.blue.shade300),
              labelStyle: TextStyle(color: Colors.blue.shade700),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.blue.shade700),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Material(
          color: Colors.blue.shade700,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: _cariDariManualInput,
            child: const Padding(
              padding: EdgeInsets.all(10),
              child: Icon(Icons.search, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMapView() {
    return Container(
      height: 180,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.blue.shade100),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: FlutterMap(
          mapController: mapController,
          options: MapOptions(
            initialCenter: selectedLatLng ?? LatLng(-6.2, 106.8),
            initialZoom: 15,
            onTap: (_, latLng) async {
              setState(() => selectedLatLng = latLng);
              await _updateAlamat(latLng);
            },
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.de/{z}/{x}/{y}.png',
            ),
            if (selectedLatLng != null)
              MarkerLayer(
                markers: [
                  Marker(
                    point: selectedLatLng!,
                    width: 60,
                    height: 60,
                    child: const Icon(Icons.location_pin, color: Colors.red, size: 40),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue.shade700,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          padding: const EdgeInsets.symmetric(vertical: 18),
        ),
        onPressed: isLoading ? null : kirimOrder,
        icon: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : const Icon(Icons.send),
        label: Text(
          isLoading ? "Mengirim..." : "Kirim Order",
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
        ),
      ),
    );
  }

  Widget _buildPricingSection() {
    if (layananData == null) return const SizedBox();

    String type = layananData!['type'];
    String unitName = layananData!['unit_name'];
    int basePrice = layananData!['price'];

    // Penjelasan teks berdasarkan tipe
    String keterangan = "";
    if (type == 'visit') {
      keterangan = "Biaya ini adalah ongkos kunjungan & pengecekan awal. Biaya perbaikan & sparepart dikonfirmasi di tempat.";
    } else if (type == 'survey') {
      keterangan = "Biaya untuk survey lokasi dan pengukuran detail sebelum estimasi proyek (RAB).";
    } else if (type == 'hourly') {
      keterangan = "Estimasi biaya tenaga kerja per jam.";
    } else {
      keterangan = "Harga per unit pengerjaan.";
    }

    return Card(
      color: Colors.white,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.monetization_on_outlined, color: Colors.green.shade700),
                const SizedBox(width: 8),
                Text(
                  "Estimasi Biaya",
                  style: TextStyle(
                    color: Colors.blue.shade700,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // LOGIKA TAMPILAN QUANTITY
            // Jika tipe Visit/Survey, biasanya user tidak pilih jumlah (fix 1x datang)
            // Jika Hourly/Unit, user bisa tambah kurang
            if (type == 'hourly' || type == 'unit') ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Jumlah ($unitName)", style: const TextStyle(fontSize: 16)),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: () => _updateQuantity(-1),
                          icon: const Icon(Icons.remove, color: Colors.red),
                        ),
                        Text(
                          '$quantity',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        IconButton(
                          onPressed: () => _updateQuantity(1),
                          icon: const Icon(Icons.add, color: Colors.green),
                        ),
                      ],
                    ),
                  )
                ],
              ),
              const Divider(height: 24),
            ],

            // TAMPILAN TOTAL HARGA
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Total Estimasi:", style: TextStyle(fontWeight: FontWeight.bold)),
                Text(
                  "Rp ${totalPrice.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}",
                  style: TextStyle(
                    color: Colors.green.shade700,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                keterangan,
                style: TextStyle(fontSize: 12, color: Colors.blue.shade900),
                textAlign: TextAlign.justify,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
