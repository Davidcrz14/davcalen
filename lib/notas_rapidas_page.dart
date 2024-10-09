import 'dart:math';

import 'package:davcalen/db/database_helper.dart';
import 'package:flutter/material.dart';

class NotasRapidasPage extends StatefulWidget {
  const NotasRapidasPage({Key? key}) : super(key: key);

  @override
  _NotasRapidasPageState createState() => _NotasRapidasPageState();
}

class _NotasRapidasPageState extends State<NotasRapidasPage> {
  List<Nota> notas = [];
  final Random random = Random();
  final DatabaseHelper _databaseHelper = DatabaseHelper();

  @override
  void initState() {
    super.initState();
    cargarNotas();
  }

  void cargarNotas() async {
    List<Map<String, dynamic>> notasDB = await _databaseHelper.getQuickNotes();
    setState(() {
      notas = notasDB.map((nota) => Nota.fromJson(nota)).toList();
    });
  }

  void guardarNota(Nota nota) async {
    if (nota.id == null) {
      int id = await _databaseHelper.insertQuickNote(nota.toJson());
      setState(() {
        nota.id = id.toString();
      });
    } else {
      await _databaseHelper.updateQuickNote(nota.toJson());
    }
  }

  void eliminarNota(String id) async {
    await _databaseHelper.deleteQuickNote(int.parse(id));
    setState(() {
      notas.removeWhere((nota) => nota.id == id);
    });
  }

  void agregarNota() {
    final nuevaNota = Nota(
      contenido: '',
      posicion: Offset(
        random.nextDouble() * (MediaQuery.of(context).size.width - 150),
        random.nextDouble() * (MediaQuery.of(context).size.height - 150),
      ),
      color: Color.fromRGBO(
        random.nextInt(256),
        random.nextInt(256),
        random.nextInt(256),
        1,
      ),
    );
    setState(() {
      notas.add(nuevaNota);
    });
  }

  void actualizarPosicionNota(Nota nota, Offset nuevaPosicion) {
    setState(() {
      nota.posicion = nuevaPosicion;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notas Rápidas', style: TextStyle(color: Colors.black87)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: Container(
        color: Colors.grey[100],
        child: Stack(
          children: notas.map((nota) => NotaDraggable(
            key: ValueKey(nota.id ?? UniqueKey()),
            nota: nota,
            onDelete: () => eliminarNota(nota.id!),
            onDragEnd: (details) => actualizarPosicionNota(nota, details.offset),
            onSave: () => guardarNota(nota),
          )).toList(),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: agregarNota,
        backgroundColor: Colors.blueGrey[300],
        child: const Icon(Icons.add),
      ),
    );
  }
}

class Nota {
  String? id;
  String contenido;
  Offset posicion;
  Color color;
  bool isEditing;

  Nota({
    this.id,
    required this.contenido,
    required this.posicion,
    required this.color,
    this.isEditing = true,
  });

  factory Nota.fromJson(Map<String, dynamic> json) {
    return Nota(
      id: json['id'].toString(),
      contenido: json['content'],
      posicion: Offset(json['positionX'], json['positionY']),
      color: Color(json['color']),
      isEditing: false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': int.parse(id!),
      'content': contenido,
      'positionX': posicion.dx,
      'positionY': posicion.dy,
      'color': color.value,
      'createdAt': DateTime.now().millisecondsSinceEpoch,
    };
  }
}

class NotaDraggable extends StatefulWidget {
  final Nota nota;
  final VoidCallback onDelete;
  final Function(DraggableDetails) onDragEnd;
  final VoidCallback onSave;

  const NotaDraggable({
    Key? key,
    required this.nota,
    required this.onDelete,
    required this.onDragEnd,
    required this.onSave,
  }) : super(key: key);

  @override
  _NotaDraggableState createState() => _NotaDraggableState();
}

class _NotaDraggableState extends State<NotaDraggable> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.nota.contenido);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: widget.nota.posicion.dx,
      top: widget.nota.posicion.dy,
      child: Draggable(
        feedback: NotaWidget(
          nota: widget.nota,
          onDelete: widget.onDelete,
          onSave: widget.onSave,
          controller: _controller,
          isEditing: false,
        ),
        childWhenDragging: Container(),
        onDragEnd: widget.onDragEnd,
        child: NotaWidget(
          nota: widget.nota,
          onDelete: widget.onDelete,
          onSave: () {
            setState(() {
              widget.nota.contenido = _controller.text;
              widget.nota.isEditing = false;
            });
            widget.onSave();
          },
          controller: _controller,
          isEditing: widget.nota.isEditing,
        ),
      ),
    );
  }
}

class NotaWidget extends StatelessWidget {
  final Nota nota;
  final VoidCallback onDelete;
  final VoidCallback onSave;
  final TextEditingController controller;
  final bool isEditing;

  const NotaWidget({
    Key? key,
    required this.nota,
    required this.onDelete,
    required this.onSave,
    required this.controller,
    required this.isEditing,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150,
      height: 150,
      decoration: BoxDecoration(
        color: nota.color,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 3,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: isEditing
                ? TextField(
                    maxLines: null,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: 'Escribe tu nota aquí...',
                    ),
                    style: const TextStyle(color: Colors.black87, fontSize: 14),
                    controller: controller,
                  )
                : Text(
                    nota.contenido,
                    style: const TextStyle(color: Colors.black87, fontSize: 14),
                  ),
          ),
          Positioned(
            top: 0,
            right: 0,
            child: Row(
              children: [
                if (isEditing)
                  IconButton(
                    icon: const Icon(Icons.save, color: Colors.black54, size: 18),
                    onPressed: onSave,
                  ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.black54, size: 18),
                  onPressed: onDelete,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
