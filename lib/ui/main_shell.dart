import 'package:flutter/material.dart';

import '../theme/dietwise_theme.dart';
import 'consulta_formulario_page.dart';
import 'dashboard_page.dart';
import 'dietas_info_page.dart';
import 'historial_consultas_page.dart';
import 'perfil_page.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  var _index = 0;

  static const _titles = [
    'Inicio',
    'Consulta',
    'Historial',
    'Dietas',
    'Perfil',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(_titles[_index]),
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0.5,
      ),
      body: IndexedStack(
        index: _index,
        children: [
          DashboardPage(onIrASeccion: (i) => setState(() => _index = i)),
          const ConsultaFormularioPage(),
          HistorialConsultasPage(
            onHacerConsulta: () => setState(() => _index = 1),
          ),
          const DietasInfoPage(),
          const PerfilPage(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: BottomNavigationBar(
            currentIndex: _index,
            onTap: (i) => setState(() => _index = i),
            type: BottomNavigationBarType.fixed,
            selectedItemColor: DietWiseColors.textPrimary,
            unselectedItemColor: DietWiseColors.textMuted,
            selectedFontSize: 11,
            unselectedFontSize: 11,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined),
                activeIcon: Icon(Icons.home),
                label: 'Inicio',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.edit_note_outlined),
                activeIcon: Icon(Icons.edit_note),
                label: 'Consulta',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.history_outlined),
                activeIcon: Icon(Icons.history),
                label: 'Historial',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.apple_outlined),
                activeIcon: Icon(Icons.apple),
                label: 'Dietas',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person_outline),
                activeIcon: Icon(Icons.person),
                label: 'Perfil',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
