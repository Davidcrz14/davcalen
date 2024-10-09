import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'agenda_page.dart';
import 'chat_ia_page.dart';
import 'db/database_helper.dart';
import 'project_organizer_page.dart';
import 'notas_rapidas_page.dart';

void main() async {
  // Asegúrate de que los widgets de Flutter estén inicializados
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializa sqflite_ffi
  if (Platform.isWindows || Platform.isLinux) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  // Inicializa la base de datos
  try {
    await DatabaseHelper().database;
    print('Base de datos inicializada correctamente');
  } catch (e) {
    print('Error al inicializar la base de datos: $e');
  }

  // Ejecuta la aplicación
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mi Agenda',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const DashboardPage(), // Cambiado de AgendaPage a DashboardPage
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('es', 'ES'),
      ],
    );
  }
}

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  _DashboardPageState createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage>
    with TickerProviderStateMixin {
  late AnimationController _menuController;
  late List<AnimationController> _cardControllers;
  int _hoveredIndex = -1;

  @override
  void initState() {
    super.initState();
    _menuController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _cardControllers = List.generate(
      12,
      (index) => AnimationController(
        duration: const Duration(milliseconds: 2000),
        vsync: this,
      )..repeat(),
    );
  }

  @override
  void dispose() {
    _menuController.dispose();
    for (var controller in _cardControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          _buildMenu(),
          Expanded(
            child: _buildDashboard(),
          ),
        ],
      ),
    );
  }

  Widget _buildMenu() {
    return Container(
      width: 200,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Menu',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          _buildMenuItem('DavCalen', Icons.calendar_today, true),
          _buildMenuItem('Opciones', Icons.settings),
          _buildMenuItem('Configuración', Icons.tune),
          _buildMenuItem('Perfil', Icons.person),
        ],
      ),
    );
  }

  Widget _buildMenuItem(String title, IconData icon,
      [bool isSelected = false]) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: isSelected ? Colors.black.withOpacity(0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          AnimatedIcon(
            icon: AnimatedIcons.menu_arrow,
            progress: _menuController,
            color: isSelected ? Colors.black : Colors.grey,
          ),
          const SizedBox(width: 10),
          Text(
            title,
            style: TextStyle(
              color: isSelected ? Colors.black : Colors.grey,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboard() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Dashboard Multitarea',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.5,
              ),
              itemCount: cardData
                  .length, // Cambiamos esto para usar la longitud de cardData
              itemBuilder: (context, index) {
                return MouseRegion(
                  onEnter: (_) => setState(() => _hoveredIndex = index),
                  onExit: (_) => setState(() => _hoveredIndex = -1),
                  child: _buildCard(index),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToAgenda() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AgendaPage()),
    );
  }

  // Movemos cardData fuera de _buildCard para que sea accesible en toda la clase
  final List<Map<String, dynamic>> cardData = [
    {
      'title': 'Agenda',
      'icon': Icons.calendar_today,
      'color': const Color(0xFF2D2D2D),
      'page': const AgendaPage(),
    },
    {
      'title': 'ChatIA',
      'icon': Icons.chat_bubble_outline,
      'color': const Color(0xFFE0E0E0),
      'page': const ChatIAPage(),
    },
    {
      'title': 'Organizador de proyectos',
      'icon': Icons.assignment,
      'color': const Color(0xFFE0E0E0),
      'page': ProjectOrganizerPage(
        databaseHelper: DatabaseHelper(),
        onProjectUpdated: () {
          // Aquí puedes añadir lógica para actualizar la UI si es necesario
        },
      ),
    },
    {
      'title': 'Notas rápidas',
      'icon': Icons.note_add,
      'color': const Color(0xFFE0E0E0),
      'page': const NotasRapidasPage(),
    },
    {
      'title': 'Recordatorios',
      'icon': Icons.alarm,
      'color': const Color(0xFFFFC0CB)
    },
    {
      'title': 'Tareas pendientes',
      'icon': Icons.check_box,
      'color': const Color(0xFF2D2D2D)
    },
    {
      'title': 'Hábitos diarios',
      'icon': Icons.repeat,
      'color': const Color(0xFFE0E0E0)
    },
    {
      'title': 'Estadísticas',
      'icon': Icons.bar_chart,
      'color': const Color(0xFF2D2D2D)
    },
    {
      'title': 'Meditación',
      'icon': Icons.self_improvement,
      'color': const Color(0xFFD7E4C0)
    },
    {
      'title': 'Configuración',
      'icon': Icons.settings,
      'color': const Color(0xFFE0E0E0)
    },
  ];

  Widget _buildCard(int index) {
    final isHovered = _hoveredIndex == index;

    return GestureDetector(
      onTap: () {
        if (cardData[index]['page'] != null) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => cardData[index]['page']),
          );
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardData[index]['color'],
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isHovered ? 0.2 : 0.1),
              blurRadius: isHovered ? 8 : 4,
              offset: isHovered ? const Offset(0, 4) : const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildAnimatedIcon(
                index, cardData[index]['icon'], cardData[index]['color']),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                color: cardData[index]['color'] == const Color(0xFF2D2D2D)
                    ? Colors.white
                    : Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: isHovered ? 18 : 16,
              ),
              child: Text(cardData[index]['title']),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedIcon(int index, IconData icon, Color color) {
    final isHovered = _hoveredIndex == index;
    final controller = _cardControllers[index];

    switch (index) {
      case 0: // Agenda
        return AnimatedBuilder(
          animation: controller,
          builder: (context, child) {
            return Transform.rotate(
              angle: math.sin(controller.value * 2 * math.pi) * 0.05,
              child: Icon(icon,
                  color: color == const Color(0xFF2D2D2D)
                      ? Colors.white
                      : Colors.black54,
                  size: 30),
            );
          },
        );
      case 1:
        return AnimatedBuilder(
          animation: controller,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(0, math.sin(controller.value * 2 * math.pi) * 5),
              child: Icon(icon,
                  color: color == const Color(0xFF2D2D2D)
                      ? Colors.white
                      : Colors.black54,
                  size: 30),
            );
          },
        );

      case 6: // Recordatorios
        return AnimatedBuilder(
          animation: controller,
          builder: (context, child) {
            return Transform.rotate(
              angle: math.sin(controller.value * 2 * math.pi) * 0.2,
              child: Icon(icon,
                  color: color == const Color(0xFF2D2D2D)
                      ? Colors.white
                      : Colors.black54,
                  size: 30),
            );
          },
        );
      default:
        return AnimatedScale(
          scale: isHovered ? 1.1 : 1.0,
          duration: const Duration(milliseconds: 200),
          child: Icon(icon,
              color: color == const Color(0xFF2D2D2D)
                  ? Colors.white
                  : Colors.black54,
              size: 30),
        );
    }
  }
}

class ChartPainter extends CustomPainter {
  final double animationValue;

  ChartPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black54
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final path = Path();
    path.moveTo(0, size.height);
    for (var i = 0; i < size.width; i++) {
      path.lineTo(
        i.toDouble(),
        size.height -
            size.height *
                math.sin((i / size.width + animationValue) * 2 * math.pi) *
                0.5,
      );
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
