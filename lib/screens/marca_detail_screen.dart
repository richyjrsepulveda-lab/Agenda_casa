import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/app_provider.dart';
import '../models/models.dart';

class MarcaDetailScreen extends StatefulWidget {
  final Marca? marca;
  final DateTime? fechaInicial;

  const MarcaDetailScreen({super.key, this.marca, this.fechaInicial});

  @override
  State<MarcaDetailScreen> createState() => _MarcaDetailScreenState();
}

class _MarcaDetailScreenState extends State<MarcaDetailScreen> {
  late TextEditingController _nombreController;
  late TextEditingController _descripcionController;
  late TextEditingController _intervaloController;
  
  DateTime _fechaSeleccionada = DateTime.now();
  TimeOfDay _horaSeleccionada = TimeOfDay.now();
  Categoria? _categoriaSeleccionada;
  bool _usarIntervaloPersonalizado = false;
  TipoIntervalo _tipoIntervaloPersonalizado = TipoIntervalo.minutos;

  @override
  void initState() {
    super.initState();
    _nombreController = TextEditingController(text: widget.marca?.nombre);
    _descripcionController = TextEditingController(text: widget.marca?.descripcion);
    _intervaloController = TextEditingController(
      text: widget.marca?.intervaloNotificacionPersonalizado?.toString() ?? '30',
    );

    if (widget.marca != null) {
      _fechaSeleccionada = widget.marca!.fechaHora;
      _horaSeleccionada = TimeOfDay.fromDateTime(widget.marca!.fechaHora);
      _usarIntervaloPersonalizado = widget.marca!.intervaloNotificacionPersonalizado != null;
      _tipoIntervaloPersonalizado = widget.marca!.tipoIntervaloPersonalizado ?? TipoIntervalo.minutos;
    } else if (widget.fechaInicial != null) {
      _fechaSeleccionada = widget.fechaInicial!;
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _descripcionController.dispose();
    _intervaloController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.marca == null ? 'Nueva marca' : 'Editar marca'),
        actions: widget.marca != null
            ? [
                // Botón finalizar (solo si NO está finalizada)
                if (!widget.marca!.finalizada)
                  IconButton(
                    icon: const Icon(Icons.check_circle_outline),
                    tooltip: 'Marcar como finalizada',
                    onPressed: _confirmFinish,
                  ),
                // Botón eliminar - SIEMPRE VISIBLE
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  tooltip: 'Eliminar marca',
                  onPressed: _confirmDelete,
                ),
              ]
            : null,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nombreController,
              decoration: const InputDecoration(
                labelText: 'Nombre *',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descripcionController,
              decoration: const InputDecoration(
                labelText: 'Descripción',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            _buildDateTimePickers(),
            const SizedBox(height: 16),
            _buildCategoriaSelector(),
            const SizedBox(height: 16),
            _buildIntervaloPersonalizado(),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                ),
                child: const Text('Guardar'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateTimePickers() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.calendar_today),
          title: const Text('Fecha'),
          subtitle: Text(DateFormat('dd/MM/yyyy').format(_fechaSeleccionada)),
          onTap: _selectDate,
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.access_time),
          title: const Text('Hora'),
          subtitle: Text(_horaSeleccionada.format(context)),
          onTap: _selectTime,
        ),
      ],
    );
  }

  Widget _buildCategoriaSelector() {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        if (widget.marca?.categoriaId != null && _categoriaSeleccionada == null) {
          _categoriaSeleccionada = provider.getCategoriaById(widget.marca!.categoriaId);
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Categoría',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<Categoria?>(
              value: _categoriaSeleccionada,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Sin categoría',
              ),
              items: [
                const DropdownMenuItem<Categoria?>(
                  value: null,
                  child: Text('Sin categoría'),
                ),
                ...provider.categorias.map((cat) {
                  return DropdownMenuItem<Categoria?>(
                    value: cat,
                    child: Row(
                      children: [
                        Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: cat.colorObj,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(cat.nombre),
                      ],
                    ),
                  );
                }),
              ],
              onChanged: (value) {
                setState(() {
                  _categoriaSeleccionada = value;
                });
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildIntervaloPersonalizado() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Intervalo personalizado'),
          subtitle: const Text('Ignorar el intervalo de la categoría'),
          value: _usarIntervaloPersonalizado,
          onChanged: (value) {
            setState(() {
              _usarIntervaloPersonalizado = value;
            });
          },
        ),
        if (_usarIntervaloPersonalizado) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _intervaloController,
                  decoration: const InputDecoration(
                    labelText: 'Intervalo',
                    helperText: '0 = sin notificaciones',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 8),
              DropdownButton<TipoIntervalo>(
                value: _tipoIntervaloPersonalizado,
                items: const [
                  DropdownMenuItem(value: TipoIntervalo.minutos, child: Text('Min')),
                  DropdownMenuItem(value: TipoIntervalo.horas, child: Text('Horas')),
                  DropdownMenuItem(value: TipoIntervalo.dias, child: Text('Días')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _tipoIntervaloPersonalizado = value;
                    });
                  }
                },
              ),
            ],
          ),
        ],
      ],
    );
  }

 Future<void> _selectDate() async {
    final ahora = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _fechaSeleccionada.isBefore(ahora) ? ahora : _fechaSeleccionada,
      firstDate: ahora.subtract(const Duration(days: 1)), // Permitir ayer
      lastDate: DateTime(2030),
    );

    if (picked != null) {
      setState(() {
        _fechaSeleccionada = picked;
      });
    }
  }

  Future<void> _selectTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _horaSeleccionada,
    );

    if (picked != null) {
      setState(() {
        _horaSeleccionada = picked;
      });
    }
  }
void _save() {
    if (_nombreController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El nombre es requerido')),
      );
      return;
    }

    final fechaHora = DateTime(
      _fechaSeleccionada.year,
      _fechaSeleccionada.month,
      _fechaSeleccionada.day,
      _horaSeleccionada.hour,
      _horaSeleccionada.minute,
    );

    // VALIDAR: Solo bloquear si es MÁS DE 1 MINUTO en el pasado
    final ahora = DateTime.now();
    if (fechaHora.isBefore(ahora.subtract(const Duration(minutes: 1)))) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('La fecha debe ser futura o muy reciente'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    int? intervaloPersonalizado;
    TipoIntervalo? tipoPersonalizado;
    if (_usarIntervaloPersonalizado) {
      intervaloPersonalizado = int.tryParse(_intervaloController.text) ?? 0;
      tipoPersonalizado = _tipoIntervaloPersonalizado;
    }

    final marca = Marca(
      id: widget.marca?.id,
      nombre: _nombreController.text.trim(),
      descripcion: _descripcionController.text.trim().isEmpty 
          ? null 
          : _descripcionController.text.trim(),
      fechaHora: fechaHora,
      categoriaId: _categoriaSeleccionada?.id,
      intervaloNotificacionPersonalizado: intervaloPersonalizado,
      tipoIntervaloPersonalizado: tipoPersonalizado,
      finalizada: widget.marca?.finalizada ?? false,
      fechaCreacion: widget.marca?.fechaCreacion,
    );

    final provider = context.read<AppProvider>();
    if (widget.marca == null) {
      provider.addMarca(marca);
    } else {
      provider.updateMarca(marca);
    }

    Navigator.pop(context);
  }
  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar marca'),
        content: Text('¿Estás seguro de eliminar "${widget.marca!.nombre}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              context.read<AppProvider>().deleteMarca(widget.marca!.id!);
              Navigator.pop(ctx); // Cierra el diálogo
              Navigator.pop(context); // Cierra la pantalla de detalle
            },
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  void _confirmFinish() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Finalizar marca'),
        content: Text('¿Marcar "${widget.marca!.nombre}" como finalizada?\n\nSeguirá visible pero sin notificaciones.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              final marcaFinalizada = widget.marca!.copyWith(finalizada: true);
              context.read<AppProvider>().updateMarca(marcaFinalizada);
              Navigator.pop(ctx);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('✓ Marca finalizada')),
              );
            },
            child: const Text('Finalizar'),
          ),
        ],
      ),
    );
  }
}