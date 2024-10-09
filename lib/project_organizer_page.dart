import 'package:davcalen/db/database_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class ProjectOrganizerPage extends StatefulWidget {
  final DatabaseHelper databaseHelper;
  final Function onProjectUpdated;

  const ProjectOrganizerPage({
    Key? key,
    required this.databaseHelper,
    required this.onProjectUpdated,
  }) : super(key: key);

  @override
  _ProjectOrganizerPageState createState() => _ProjectOrganizerPageState();
}

class _ProjectOrganizerPageState extends State<ProjectOrganizerPage>
    with TickerProviderStateMixin {
  List<Map<String, dynamic>> _projects = [];
  late AnimationController _fabAnimationController;
  late Animation<double> _fabScaleAnimation;

  @override
  void initState() {
    super.initState();
    _loadProjects();
    _setupAnimations();
  }

  void _setupAnimations() {
    _fabAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fabScaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _fabAnimationController,
        curve: Curves.easeOut,
      ),
    );
    _fabAnimationController.forward();
  }

  Future<void> _loadProjects() async {
    final projects = await widget.databaseHelper.getProjects();
    setState(() {
      _projects = projects;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Organizador de Proyectos',
            style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.teal.shade700,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.teal.shade700, Colors.teal.shade100],
          ),
        ),
        child: _buildProjectList(),
      ),
      floatingActionButton: ScaleTransition(
        scale: _fabScaleAnimation,
        child: FloatingActionButton.extended(
          onPressed: () => _showAddProjectDialog(context),
          icon: const Icon(Icons.add),
          label: const Text('Nuevo Proyecto'),
          backgroundColor: Colors.teal.shade800,
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildProjectList() {
    return ListView.builder(
      itemCount: _projects.length,
      itemBuilder: (context, index) {
        final project = _projects[index];
        return Slidable(
          endActionPane: ActionPane(
            motion: const ScrollMotion(),
            children: [
              SlidableAction(
                onPressed: (context) =>
                    _showEditProjectDialog(context, project),
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                icon: Icons.edit,
                label: 'Editar',
              ),
              SlidableAction(
                onPressed: (context) => _confirmDeleteProject(context, project),
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                icon: Icons.delete,
                label: 'Eliminar',
              ),
            ],
          ),
          child: _buildProjectCard(project),
        );
      },
    );
  }

  Widget _buildProjectCard(Map<String, dynamic> project) {
    final dueDate = DateTime.parse(project['dueDate']);
    final isOverdue = dueDate.isBefore(DateTime.now());

    return Card(
      elevation: 8,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: InkWell(
        onTap: () => _showProjectDetails(project),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(  // Añadido para manejar el overflow
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  project['title'],
                  style: GoogleFonts.poppins(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(project['description'], style: GoogleFonts.roboto()),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildStatusDropdown(project),
                    Text(
                      'Vence: ${DateFormat('dd/MM/yyyy').format(dueDate)}',
                      style: GoogleFonts.roboto(
                        color: isOverdue ? Colors.red : Colors.black54,
                        fontWeight:
                            isOverdue ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusDropdown(Map<String, dynamic> project) {
    return DropdownButton<String>(
      value: project['status'],
      onChanged: (String? newValue) {
        if (newValue != null) {
          _updateProjectStatus(project['id'], newValue);
        }
      },
      items: <String>['Pendiente', 'En Progreso', 'Completado']
          .map<DropdownMenuItem<String>>((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(value),
        );
      }).toList(),
    );
  }

  Future<void> _updateProjectStatus(int projectId, String newStatus) async {
    await widget.databaseHelper.updateProject({'id': projectId, 'status': newStatus});
    _loadProjects();  // Recargar los proyectos después de la actualización
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'en progreso':
        return Colors.blue;
      case 'completado':
        return Colors.green;
      case 'pendiente':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  void _showAddProjectDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        String title = '';
        String description = '';
        String status = 'Pendiente';
        DateTime dueDate = DateTime.now().add(const Duration(days: 7));

        return AlertDialog(
          title: const Text('Añadir Proyecto'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  decoration: const InputDecoration(labelText: 'Título'),
                  onChanged: (value) => title = value,
                ),
                TextField(
                  decoration: const InputDecoration(labelText: 'Descripción'),
                  onChanged: (value) => description = value,
                ),
                DropdownButtonFormField<String>(
                  value: status,
                  items: ['Pendiente', 'En Progreso', 'Completado']
                      .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
                  onChanged: (value) => status = value!,
                  decoration: const InputDecoration(labelText: 'Estado'),
                ),
                InkWell(
                  onTap: () async {
                    final pickedDate = await showDatePicker(
                      context: context,
                      initialDate: dueDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (pickedDate != null) {
                      dueDate = pickedDate;
                    }
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(
                        labelText: 'Fecha de vencimiento'),
                    child: Text(DateFormat('dd/MM/yyyy').format(dueDate)),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('Guardar'),
              onPressed: () async {
                final newProject = {
                  'title': title,
                  'description': description,
                  'status': status,
                  'dueDate': dueDate.toIso8601String(),
                  'createdAt': DateTime.now().millisecondsSinceEpoch,
                };
                await widget.databaseHelper.insertProject(newProject);
                _loadProjects();
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _showProjectDetails(Map<String, dynamic> project) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ProjectDetailsPage(
          project: project,
          databaseHelper: widget.databaseHelper,
          onProjectUpdated: _loadProjects,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _fabAnimationController.dispose();
    super.dispose();
  }

  void _showEditProjectDialog(
      BuildContext context, Map<String, dynamic> project) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Editar Proyecto',
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: TextEditingController(text: project['title']),
                decoration: const InputDecoration(
                  labelText: 'Título del proyecto',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: TextEditingController(text: project['description']),
                decoration: const InputDecoration(
                  labelText: 'Descripción del proyecto',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              child: Text('Cancelar', style: GoogleFonts.roboto()),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              child: Text('Guardar', style: GoogleFonts.roboto()),
              onPressed: () async {
                final updatedProject = {
                  'id': project['id'],
                  'title': project['title'],
                  'description': project['description'],
                };
                await widget.databaseHelper.updateProject(updatedProject);
                widget.onProjectUpdated();
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _confirmDeleteProject(
      BuildContext context, Map<String, dynamic> project) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Eliminar Proyecto',
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
          content: Text('¿Estás seguro de que deseas eliminar este proyecto?',
              style: GoogleFonts.roboto()),
          actions: [
            TextButton(
              child: Text('Cancelar', style: GoogleFonts.roboto()),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: Text('Eliminar',
                  style: GoogleFonts.roboto(color: Colors.red)),
              onPressed: () async {
                await widget.databaseHelper.deleteProject(project['id']);
                widget.onProjectUpdated();
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}

class ProjectDetailsPage extends StatefulWidget {
  final Map<String, dynamic> project;
  final DatabaseHelper databaseHelper;
  final Function onProjectUpdated;

  const ProjectDetailsPage({
    Key? key,
    required this.project,
    required this.databaseHelper,
    required this.onProjectUpdated,
  }) : super(key: key);

  @override
  _ProjectDetailsPageState createState() => _ProjectDetailsPageState();
}

class _ProjectDetailsPageState extends State<ProjectDetailsPage> {
  List<Map<String, dynamic>> _tasks = [];
  final bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    final tasks =
        await widget.databaseHelper.getTasksForProject(widget.project['id']);
    setState(() {
      _tasks = tasks;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.project['title'],
            style: GoogleFonts.poppins(color: Colors.white)),
        backgroundColor: Colors.teal.shade700,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => _showEditProjectDialog(context),
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () => _confirmDeleteProject(context),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.teal.shade100, Colors.white],
          ),
        ),
        child: Column(
          children: [
            _buildProjectInfo(),
            const Divider(),
            Expanded(child: _buildTaskList()),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddTaskDialog(context),
        icon: const Icon(Icons.add_task),
        label: const Text('Nueva Tarea'),
        backgroundColor: Colors.teal.shade800,
      ),
    );
  }

  Widget _buildProjectInfo() {
    final dueDate = DateTime.parse(widget.project['dueDate']);
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.project['description'],
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Chip(
                label: Text(widget.project['status']),
                backgroundColor: _getStatusColor(widget.project['status']),
              ),
              Text(
                'Vence: ${DateFormat('dd/MM/yyyy').format(dueDate)}',
                style: const TextStyle(fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTaskList() {
    return ListView.builder(
      itemCount: _tasks.length,
      itemBuilder: (context, index) {
        final task = _tasks[index];
        return Slidable(
          endActionPane: ActionPane(
            motion: const ScrollMotion(),
            children: [
              SlidableAction(
                onPressed: (context) => _showEditTaskDialog(context, task),
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                icon: Icons.edit,
                label: 'Editar',
              ),
              SlidableAction(
                onPressed: (context) => _confirmDeleteTask(context, task),
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                icon: Icons.delete,
                label: 'Eliminar',
              ),
            ],
          ),
          child: ListTile(
            title: Text(task['title'],
                style: GoogleFonts.roboto(fontWeight: FontWeight.bold)),
            subtitle: Text(task['description'], style: GoogleFonts.roboto()),
            trailing: _buildTaskStatusDropdown(task),
          ),
        );
      },
    );
  }

  Widget _buildTaskStatusDropdown(Map<String, dynamic> task) {
    return DropdownButton<String>(
      value: task['status'],
      onChanged: (String? newValue) {
        if (newValue != null) {
          _updateTaskStatus(task['id'], newValue);
        }
      },
      items: <String>['Pendiente', 'En Progreso', 'Completado']
          .map<DropdownMenuItem<String>>((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(value),
        );
      }).toList(),
    );
  }

  Future<void> _updateTaskStatus(int taskId, String newStatus) async {
    await widget.databaseHelper.updateTask({'id': taskId, 'status': newStatus});
    _loadTasks();  // Recargar las tareas después de la actualización
  }

  void _showAddTaskDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        String title = '';
        String description = '';
        String status = 'Pendiente';
        DateTime dueDate = DateTime.now().add(const Duration(days: 1));

        return AlertDialog(
          title: const Text('Añadir Tarea'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  decoration: const InputDecoration(labelText: 'Título'),
                  onChanged: (value) => title = value,
                ),
                TextField(
                  decoration: const InputDecoration(labelText: 'Descripción'),
                  onChanged: (value) => description = value,
                ),
                DropdownButtonFormField<String>(
                  value: status,
                  items: ['Pendiente', 'En Progreso', 'Completado']
                      .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
                  onChanged: (value) => status = value!,
                  decoration: const InputDecoration(labelText: 'Estado'),
                ),
                InkWell(
                  onTap: () async {
                    final pickedDate = await showDatePicker(
                      context: context,
                      initialDate: dueDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (pickedDate != null) {
                      dueDate = pickedDate;
                    }
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(
                        labelText: 'Fecha de vencimiento'),
                    child: Text(DateFormat('dd/MM/yyyy').format(dueDate)),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('Guardar'),
              onPressed: () async {
                final newTask = {
                  'projectId': widget.project['id'],
                  'title': title,
                  'description': description,
                  'status': status,
                  'dueDate': dueDate.toIso8601String(),
                };
                await widget.databaseHelper.insertTask(newTask);
                _loadTasks();
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _showEditTaskDialog(BuildContext context, Map<String, dynamic> task) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        String title = task['title'];
        String description = task['description'];
        String status = task['status'];
        DateTime dueDate = DateTime.parse(task['dueDate']);

        return AlertDialog(
          title: const Text('Editar Tarea'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  decoration: const InputDecoration(labelText: 'Título'),
                  onChanged: (value) => title = value,
                  controller: TextEditingController(text: title),
                ),
                TextField(
                  decoration: const InputDecoration(labelText: 'Descripción'),
                  onChanged: (value) => description = value,
                  controller: TextEditingController(text: description),
                ),
                DropdownButtonFormField<String>(
                  value: status,
                  items: ['Pendiente', 'En Progreso', 'Completado']
                      .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
                  onChanged: (value) => status = value!,
                  decoration: const InputDecoration(labelText: 'Estado'),
                ),
                InkWell(
                  onTap: () async {
                    final pickedDate = await showDatePicker(
                      context: context,
                      initialDate: dueDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (pickedDate != null) {
                      dueDate = pickedDate;
                    }
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(
                        labelText: 'Fecha de vencimiento'),
                    child: Text(DateFormat('dd/MM/yyyy').format(dueDate)),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('Guardar'),
              onPressed: () async {
                final updatedTask = {
                  'id': task['id'],
                  'title': title,
                  'description': description,
                  'status': status,
                  'dueDate': dueDate.toIso8601String(),
                };
                await widget.databaseHelper.updateTask(updatedTask);
                _loadTasks();
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _showEditProjectDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        String title = widget.project['title'];
        String description = widget.project['description'];
        String status = widget.project['status'];
        DateTime dueDate = DateTime.parse(widget.project['dueDate']);

        return AlertDialog(
          title: const Text('Editar Proyecto'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  decoration: const InputDecoration(labelText: 'Título'),
                  onChanged: (value) => title = value,
                  controller: TextEditingController(text: title),
                ),
                TextField(
                  decoration: const InputDecoration(labelText: 'Descripción'),
                  onChanged: (value) => description = value,
                  controller: TextEditingController(text: description),
                ),
                DropdownButtonFormField<String>(
                  value: status,
                  items: ['Pendiente', 'En Progreso', 'Completado']
                      .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
                  onChanged: (value) => status = value!,
                  decoration: const InputDecoration(labelText: 'Estado'),
                ),
                InkWell(
                  onTap: () async {
                    final pickedDate = await showDatePicker(
                      context: context,
                      initialDate: dueDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (pickedDate != null) {
                      dueDate = pickedDate;
                    }
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(
                        labelText: 'Fecha de vencimiento'),
                    child: Text(DateFormat('dd/MM/yyyy').format(dueDate)),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('Guardar'),
              onPressed: () async {
                final updatedProject = {
                  'id': widget.project['id'],
                  'title': title,
                  'description': description,
                  'status': status,
                  'dueDate': dueDate.toIso8601String(),
                };
                await widget.databaseHelper.updateProject(updatedProject);
                widget.onProjectUpdated();
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _confirmDeleteProject(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Eliminar Proyecto'),
          content:
              const Text('¿Estás seguro de que deseas eliminar este proyecto?'),
          actions: [
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('Eliminar'),
              onPressed: () async {
                await widget.databaseHelper.deleteProject(widget.project['id']);
                widget.onProjectUpdated();
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'en progreso':
        return Colors.blue;
      case 'completado':
        return Colors.green;
      case 'pendiente':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  void _confirmDeleteTask(BuildContext context, Map<String, dynamic> task) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Eliminar Tarea'),
          content:
              const Text('¿Estás seguro de que deseas eliminar esta tarea?'),
          actions: [
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('Eliminar'),
              onPressed: () async {
                await widget.databaseHelper.deleteTask(task['id']);
                widget.onProjectUpdated();
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
