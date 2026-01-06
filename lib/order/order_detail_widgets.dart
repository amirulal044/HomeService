import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

// --- HELPER FUNGSI ---
Future<void> bukaGoogleMaps(
  double lat,
  double lng,
  BuildContext context,
) async {
  final url = 'https://www.google.com/maps/search/?api=1&query=$lat,$lng';
  if (await canLaunchUrl(Uri.parse(url))) {
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  } else {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Gagal buka peta")));
  }
}

// --- WIDGETS ---
class OrderInfoCard extends StatelessWidget {
  final Map<String, dynamic> data;
  const OrderInfoCard({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildTile(
              "Kategori",
              data['kategori'] ?? '',
              LucideIcons.briefcase,
            ),
            _buildTile(
              "Deskripsi",
              data['deskripsi'] ?? '',
              LucideIcons.alignLeft,
            ),
            _buildTile(
              "Tanggal",
              data['tanggal_order']?.substring(0, 10) ?? '',
              LucideIcons.calendar,
            ),
            const Divider(),
            Row(
              children: [
                const Icon(LucideIcons.mapPin, color: Colors.blue),
                const SizedBox(width: 8),
                Expanded(child: Text(data['alamat'] ?? '-')),
                if (data['latitude'] != null)
                  IconButton(
                    icon: const Icon(Icons.directions, color: Colors.blue),
                    onPressed: () => bukaGoogleMaps(
                      data['latitude'],
                      data['longitude'],
                      context,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTile(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              "$label: $value",
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}

class OrderStatusBadge extends StatelessWidget {
  final String status;
  const OrderStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    Color color = status == 'selesai'
        ? Colors.green
        : (status == 'sedang_dikerjakan' ? Colors.orange : Colors.blue);
    return Chip(
      backgroundColor: color.withOpacity(0.1),
      label: Text(
        status.replaceAll('_', ' ').toUpperCase(),
        style: TextStyle(color: color, fontWeight: FontWeight.bold),
      ),
      avatar: Icon(Icons.info, color: color, size: 16),
    );
  }
}

class ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;

  const ActionButton({
    super.key,
    required this.label,
    required this.icon,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        icon: Icon(icon, color: Colors.white),
        label: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: onPressed,
      ),
    );
  }
}
