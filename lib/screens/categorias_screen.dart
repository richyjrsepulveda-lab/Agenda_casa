import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/models.dart';

class CategoriasScreen extends StatelessWidget {
  const CategoriasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Categorías'),
      ),
      body: Consumer<AppProvider>(
        builder: (context, provider, _) {
          if (provider.categorias.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.folder_off,
                    size: 64,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No hay categorías',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: provider.categorias.length,
            itemBuilder: (context, index) {
              final categoria = provider.categorias[index];
              return _CategoriaCard(categoria: categoria);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCategoriaDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showCategoriaDialog(BuildContext context, [Categoria? categoria]) {
    showDialog(
      context: context,
      builder: (_) => _CategoriaDialog(categoria: categoria),
    );
  }
}

class _CategoriaCard extends StatelessWidget {
  final Categoria categoria;

  const _CategoriaCard({required this.categoria});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: categoria.colorObj,
        ),
        title: Text(categoria.nombre),
        subtitle: Text(categoria.intervaloTexto),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (_) => _CategoriaDialog(categoria: categoria),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => _confirmDelete(context),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar categoría'),
        content: Text('¿Eliminar "${categoria.nombre}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              context.read<AppProvider>().deleteCategoria(categoria.id!);
              Navigator.pop(ctx);
            },
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}

class _CategoriaDialog extends StatefulWidget {
  final Categoria? categoria;

  const _CategoriaDialog({this.categoria});

  @override
  State<_CategoriaDialog> createState() => _CategoriaDialogState();
}

class _CategoriaDialogState extends State<_CategoriaDialog> {
  late TextEditingController _nombreController;
  late TextEditingController _intervaloController;
  Color _selectedColor = Colors.blue;
  TipoIntervalo _tipoIntervalo = TipoIntervalo.minutos;

  final List<Color> _availableColors = [
    Colors.red,
    Colors.pink,
    Colors.purple,
    Colors.deepPurple,
    Colors.indigo,
    Colors.blue,
    Colors.cyan,
    Colors.teal,
    Colors.green,
    Colors.lightGreen,
    Colors.lime,
    Colors.yellow,
    Colors.amber,
    Colors.orange,
    Colors.deepOrange,
    Colors.brown,
  ];

  @override
  void initState() {
    super.initState();
    _nombreController = TextEditingController(text: widget.categoria?.nombre);
    _intervaloController = TextEditingController(
      text: widget.categoria?.intervaloNotificacion.toString() ?? '30',
    );
    if (widget.categoria != null) {
      _selectedColor = widget.categoria!.colorObj;
      _tipoIntervalo = widget.categoria!.tipoIntervalo;
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _intervaloController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.categoria == null ? 'Nueva categoría' : 'Editar categoría',
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nombreController,
              decoration: const InputDecoration(
                labelText: 'Nombre',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
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
                  value: _tipoIntervalo,
                  items: const [
                    DropdownMenuItem(value: TipoIntervalo.minutos, child: Text('Min')),
                    DropdownMenuItem(value: TipoIntervalo.horas, child: Text('Horas')),
                    DropdownMenuItem(value: TipoIntervalo.dias, child: Text('Días')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _tipoIntervalo = value;
                      });
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text('Color:'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _availableColors.map((color) {
                final isSelected = color.toARGB32() == _selectedColor.toARGB32();
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedColor = color;
                    });
                  },
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? Colors.white : Colors.transparent,
                        width: 3,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: color.withValues(alpha: 0.5),
                                blurRadius: 8,
                                spreadRadius: 2,
                              )
                            ]
                          : null,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        TextButton(
          onPressed: _save,
          child: const Text('Guardar'),
        ),
      ],
    );
  }

  void _save() {
    if (_nombreController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El nombre es requerido')),
      );
      return;
    }

    final intervalo = int.tryParse(_intervaloController.text) ?? 0;

    final categoria = Categoria(
      id: widget.categoria?.id,
      nombre: _nombreController.text.trim(),
      intervaloNotificacion: intervalo,
      tipoIntervalo: _tipoIntervalo,
      color: '0x${_selectedColor.toARGB32().toRadixString(16).padLeft(8, '0')}',
    );

    final provider = context.read<AppProvider>();
    if (widget.categoria == null) {
      provider.addCategoria(categoria);
    } else {
      provider.updateCategoria(categoria);
    }

    Navigator.pop(context);
  }
}