import 'package:flutter/material.dart';

import '../services/registro_consulta_firestore.dart';

class HistorialConsultasPage extends StatelessWidget {
  const HistorialConsultasPage({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = RegistroConsultaFirestore();

    return StreamBuilder<List<Map<String, Object?>>>(
      stream: repo.historial(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final items = snapshot.data ?? [];
        if (items.isEmpty) {
          return const Center(
            child: Text(
              'Aún no hay consultas guardadas.\n'
              'Use la pestaña Consulta y pulse «Recomendar dieta».',
              textAlign: TextAlign.center,
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: items.length,
          separatorBuilder: (context, index) => const Divider(height: 1),
          itemBuilder: (context, i) {
            final r = items[i];
            final conf = r['confianzaPrediccion'];
            final confTxt = conf is num
                ? 'Confianza: ${(conf.toDouble() * 100).toStringAsFixed(1)} %\n'
                : '';
            return ListTile(
              title: Text('${r['nivelObesidad'] ?? ''}'),
              subtitle: Text(
                '$confTxt${r['dietaRecomendada'] ?? ''}\n${r['creadoEn'] ?? ''}',
              ),
              isThreeLine: true,
            );
          },
        );
      },
    );
  }
}
