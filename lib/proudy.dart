import 'package:flutter/material.dart';

class ProudyPage extends StatelessWidget {
  const ProudyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Proud Moment'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const TextField(
              readOnly: true,
              minLines: 5,
              maxLines: 5,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                filled: true,
              ),
            ),
            const SizedBox(height: 24),
            _buildOption(
              icon: Icons.favorite_border,
              title: 'Favorisieren',
              subtitle: 'Als Favorit markieren',
            ),
            _buildOption(
              icon: Icons.category_outlined,
              title: 'Kategorie',
              subtitle: 'Kategorie eingeben',
            ),
            _buildOption(
              icon: Icons.add_photo_alternate_outlined,
              title: 'Bild hinzufügen',
              subtitle: 'Ein Bild für diesen Moment auswählen',
            ),
            _buildOption(
              icon: Icons.calendar_today_outlined,
              title: 'Datum',
              subtitle: 'Datum auswählen',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOption({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        // Platzhalter: Die Aktionen werden später ergänzt.
        onTap: () {},
      ),
    );
  }
}

