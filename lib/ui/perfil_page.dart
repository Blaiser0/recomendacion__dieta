import 'package:flutter/material.dart';

class PerfilPage extends StatelessWidget {
  const PerfilPage({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
      children: [
        Center(
          child: CircleAvatar(
            radius: 48,
            backgroundColor: const Color(0xFFE3F2FD),
            child: Text(
              'R',
              style: textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1565C0),
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Renzo',
          textAlign: TextAlign.center,
          style: textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1C1C1E),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Perfil de usuario — recomendación de dieta con IA',
          textAlign: TextAlign.center,
          style: textTheme.bodyMedium?.copyWith(color: const Color(0xFF6B6B6F)),
        ),
        const SizedBox(height: 28),
        Card(
          child: ListTile(
            leading: const Icon(Icons.health_and_safety_outlined),
            title: const Text('Proyecto'),
            subtitle: Text(
              'Metodología de la investigación — modelo TFLite + Firestore.',
              style: textTheme.bodySmall,
            ),
          ),
        ),
      ],
    );
  }
}
