import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'db/database_helper.dart';
import 'package:intl/intl.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:google_fonts/google_fonts.dart';

class AgendaPage extends StatefulWidget {
  const AgendaPage({super.key});

  @override
  _AgendaPageState createState() => _AgendaPageState();
}

class _AgendaPageState extends State<AgendaPage> with SingleTickerProviderStateMixin {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  late AnimationController _animationController;
  late Animation<double> _animation;
  late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
    _initializeNotifications();
  }

  void _initializeNotifications() {
    flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    const initializationSettingsWindows = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initializationSettings = InitializationSettings(
      iOS: initializationSettingsWindows,
    );
    flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Agenda', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.teal.shade700,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.teal.shade700, Colors.teal.shade100],
          ),
        ),
        child: FadeTransition(
          opacity: _animation,
          child: Column(
            children: [
              _buildCalendar(),
              Expanded(child: _buildReminderList()),
            ],
          ),
        ),
      ),
      floatingActionButton: ScaleTransition(
        scale: _animation,
        child: FloatingActionButton.extended(
          onPressed: () => _showAddReminderDialog(_selectedDay ?? _focusedDay),
          backgroundColor: Colors.teal.shade800,
          icon: const Icon(Icons.add),
          label: const Text('Nuevo Recordatorio'),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildCalendar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(8),
      child: TableCalendar(
        firstDay: DateTime.utc(2010, 10, 16),
        lastDay: DateTime.utc(2030, 3, 14),
        focusedDay: _focusedDay,
        calendarFormat: _calendarFormat,
        selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
        onDaySelected: (selectedDay, focusedDay) {
          setState(() {
            _selectedDay = selectedDay;
            _focusedDay = focusedDay;
          });
        },
        onFormatChanged: (format) {
          if (_calendarFormat != format) {
            setState(() {
              _calendarFormat = format;
            });
          }
        },
        onPageChanged: (focusedDay) {
          _focusedDay = focusedDay;
        },
        locale: 'es_ES',
        calendarStyle: CalendarStyle(
          todayDecoration: BoxDecoration(
            color: Colors.teal.shade300,
            shape: BoxShape.circle,
          ),
          selectedDecoration: BoxDecoration(
            color: Colors.teal.shade700,
            shape: BoxShape.circle,
          ),
          weekendTextStyle: TextStyle(color: Colors.teal.shade800),
          outsideTextStyle: const TextStyle(color: Colors.grey),
        ),
        headerStyle: HeaderStyle(
          formatButtonVisible: false,
          titleCentered: true,
          titleTextStyle: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal.shade700),
        ),
      ),
    );
  }

  Widget _buildReminderList() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _databaseHelper.getReminders(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else {
          final reminders = snapshot.data ?? [];
          return ListView.builder(
            itemCount: reminders.length,
            itemBuilder: (context, index) {
              final reminder = reminders[index];
              return SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(1, 0),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: _animationController,
                  curve: Interval(
                    index / reminders.length,
                    (index + 1) / reminders.length,
                    curve: Curves.easeInOut,
                  ),
                )),
                child: Card(
                  elevation: 4,
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    title: Text(reminder['title'],
                        style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.teal.shade700)),
                    subtitle: Text('${reminder['description']} - ${reminder['time']}',
                        style: GoogleFonts.roboto(color: Colors.grey.shade600)),
                    leading: Icon(Icons.event, color: Colors.teal.shade500),
                    onTap: () => _showReminderDetailsDialog(reminder),
                  ),
                ),
              );
            },
          );
        }
      },
    );
  }

  void _showReminderDetailsDialog(Map<String, dynamic> reminder) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(reminder['title']),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Descripción: ${reminder['description']}'),
              Text('Fecha: ${DateFormat('dd/MM/yyyy').format(DateTime.parse(reminder['date']))}'),
              Text('Hora: ${reminder['time']}'),
            ],
          ),
          actions: [
            TextButton(
              child: const Text('Cerrar'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('Eliminar'),
              onPressed: () async {
                await _databaseHelper.deleteReminder(reminder['id']);
                Navigator.of(context).pop();
                setState(() {});
              },
            ),
          ],
        );
      },
    );
  }

  void _showAddReminderDialog(DateTime selectedDay) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        String title = '';
        String description = '';
        TimeOfDay time = TimeOfDay.now();

        return AlertDialog(
          title: Text('Añadir recordatorio', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.teal.shade700)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  decoration: InputDecoration(
                    labelText: 'Título',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.teal.shade700)),
                  ),
                  onChanged: (value) => title = value,
                ),
                const SizedBox(height: 16),
                TextField(
                  decoration: InputDecoration(
                    labelText: 'Descripción',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.teal.shade700)),
                  ),
                  maxLines: 3,
                  onChanged: (value) => description = value,
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  icon: const Icon(Icons.access_time),
                  label: const Text('Seleccionar hora'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal.shade700, // Cambiado de 'primary' a 'backgroundColor'
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () async {
                    final selectedTime = await showTimePicker(
                      context: context,
                      initialTime: time,
                    );
                    if (selectedTime != null) {
                      time = selectedTime;
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: Text('Cancelar', style: GoogleFonts.roboto(color: Colors.grey.shade600)),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              child: Text('Guardar', style: GoogleFonts.roboto(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal.shade700, // Cambiado de 'primary' a 'backgroundColor'
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                if (title.isNotEmpty) {
                  final reminderDateTime = DateTime(
                    selectedDay.year,
                    selectedDay.month,
                    selectedDay.day,
                    time.hour,
                    time.minute,
                  );
                  _databaseHelper.insertReminder({
                    'title': title,
                    'description': description,
                    'date': selectedDay.toIso8601String(),
                    'time': '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
                  });
                  _scheduleNotification(title, description, reminderDateTime);
                  Navigator.of(context).pop();
                  setState(() {});
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Por favor, ingrese un título')),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _scheduleNotification(String title, String description, DateTime scheduledDate) async {
    const iOSPlatformChannelSpecifics = DarwinNotificationDetails();
    const platformChannelSpecifics = NotificationDetails(iOS: iOSPlatformChannelSpecifics);

    await flutterLocalNotificationsPlugin.schedule(
      0,
      title,
      description,
      scheduledDate,
      platformChannelSpecifics,
    );
  }
}
