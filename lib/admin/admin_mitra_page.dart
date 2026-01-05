import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:async/async.dart'; // ← WAJIB untuk StreamZip

class AdminMitraPage extends StatefulWidget {
  const AdminMitraPage({super.key});

  @override
  State<AdminMitraPage> createState() => _AdminMitraPageState();
}

class _AdminMitraPageState extends State<AdminMitraPage> {
  String statusFilter = 'Semua';
  String searchKeyword = '';

  Stream<List<QueryDocumentSnapshot>> getRealtimeFilteredDocs() async* {
    final firestore = FirebaseFirestore.instance;

    Stream<QuerySnapshot> calonStream =
        firestore.collection('calon_mitras').snapshots();
    Stream<QuerySnapshot> mitraStream =
        firestore.collection('mitras').snapshots();

    await for (final snapshot in StreamZip([calonStream, mitraStream])) {
      List<QueryDocumentSnapshot> calonDocs = snapshot[0].docs;
      List<QueryDocumentSnapshot> mitraDocs = snapshot[1].docs;

      List<QueryDocumentSnapshot> combined = [];

      if (statusFilter == 'Semua') {
        combined = [...calonDocs, ...mitraDocs];
      } else if (statusFilter == 'Disetujui') {
        combined = mitraDocs
            .where((doc) =>
                (doc.data() as Map<String, dynamic>)['status'] == 'disetujui')
            .toList();
      } else {
        combined = calonDocs
            .where((doc) =>
                (doc.data() as Map<String, dynamic>)['status'] ==
                statusFilter.toLowerCase())
            .toList();
      }

      yield combined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Filter dan Pencarian
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 10),
          child: Row(
            children: [
              DropdownButton<String>(
                value: statusFilter,
                borderRadius: BorderRadius.circular(12),
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                  color: Colors.black,
                ),
                items: const [
                  DropdownMenuItem(value: 'Semua', child: Text('Semua')),
                  DropdownMenuItem(value: 'Menunggu', child: Text('Menunggu')),
                  DropdownMenuItem(value: 'Disetujui', child: Text('Disetujui')),
                  DropdownMenuItem(value: 'Ditolak', child: Text('Ditolak')),
                ],
                onChanged: (val) => setState(() => statusFilter = val!),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Cari nama mitra...',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onChanged: (value) =>
                      setState(() => searchKeyword = value.toLowerCase()),
                ),
              ),
            ],
          ),
        ),

        // Daftar Mitra Realtime
        Expanded(
          child: StreamBuilder<List<QueryDocumentSnapshot>>(
            stream: getRealtimeFilteredDocs(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final docs = snapshot.data ?? [];
              final filteredDocs = docs.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final nama = (data['nama'] ?? '').toString().toLowerCase();
                return nama.contains(searchKeyword);
              }).toList();

              if (filteredDocs.isEmpty) {
                return const Center(child: Text('Tidak ada mitra ditemukan.'));
              }

              return RefreshIndicator(
                onRefresh: () async => setState(() {}),
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: filteredDocs.length,
                  itemBuilder: (context, index) {
                    final doc = filteredDocs[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final uid = doc.id;

                    final nama = data['nama'] ?? 'Tanpa Nama';
                    final email = data['email'] ?? '-';
                    final status = data['status'] ?? '-';
                    final alamat = data['alamat'] ?? '-';

                    final rawKeahlian = data['keahlian'];
                    List<String> keahlianList = [];
                    if (rawKeahlian is List) {
                      keahlianList = rawKeahlian.cast<String>();
                    } else if (rawKeahlian is String) {
                      keahlianList = [rawKeahlian];
                    }

                    return Card(
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header Nama + Email + Tombol
                            Row(
                              children: [
                                const Icon(Icons.account_circle,
                                    size: 40, color: Colors.blue),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        nama,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      Text(
                                        email,
                                        style: const TextStyle(
                                            fontSize: 13, color: Colors.black54),
                                      ),
                                    ],
                                  ),
                                ),
                                ElevatedButton(
                                  onPressed: () {
                                    Navigator.pushNamed(
                                      context,
                                      '/detail-mitra',
                                      arguments: {
                                        'uid': uid,
                                        'data': data,
                                      },
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue.shade600,
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8)),
                                  ),
                                  child: const Text('Detail',
                                      style: TextStyle(color: Colors.white)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),

                            // Alamat
                            Row(
                              children: [
                                const Icon(Icons.location_on,
                                    size: 18, color: Colors.grey),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    alamat,
                                    style: const TextStyle(
                                        color: Colors.black87, fontSize: 13),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 8),

                            // Status
                            Row(
                              children: [
                                const Icon(Icons.verified,
                                    size: 18, color: Colors.grey),
                                const SizedBox(width: 4),
                                Text(
                                  'Status: $status',
                                  style: TextStyle(
                                    color: status == 'disetujui'
                                        ? Colors.green
                                        : Colors.orange,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 8),

                            // Keahlian
                            Row(
                              children: const [
                                Icon(Icons.work_outline,
                                    size: 18, color: Colors.grey),
                                SizedBox(width: 4),
                                Text(
                                  'Keahlian:',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w600, fontSize: 13),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: keahlianList.map((item) {
                                return Chip(
                                  label: Text(item),
                                  backgroundColor: Colors.blue.shade50,
                                  labelStyle: const TextStyle(fontSize: 12),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

