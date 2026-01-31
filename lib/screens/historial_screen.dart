import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/app_provider.dart';
import '../models/models.dart';
import 'marca_detail_screen.dart';

class HistorialScreen extends StatelessWidget {
  const HistorialScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial'),
      ),
      body: Consumer<AppProvider>(
        builder: (context, provider, _) {
          if (provider.marcasVencidas.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.history,
                    size: 64,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No hay marcas vencidas',
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
            itemCount: provider.marcasVencidas.length,
            itemBuilder: (context, index) {
              final marca = provider.marcasVencidas[index];
              final categoria = provider.getCategoriaById(marca.categoriaId);
              
              return _HistorialCard(marca: marca, categoria: categoria);
            },
          );
        },
      ),
    );
  }
}

class _HistorialCard extends StatelessWidget {
  final Marca marca;
  final Categoria? categoria;

  const _HistorialCard({required this.marca, this.categoria});

  @override
  Widget build(BuildContext context) {
    final backgroundColor = categoria?.colorObj.withOpacity(0.05);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      color: backgroundColor,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => MarcaDetailScreen(marca: marca),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              if (categoria != null)
                Container(
                  width: 4,
                  height: 60,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    color: categoria!.colorObj.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.check_circle,
                          color: Colors.grey,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            marca.nombre,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              decoration: TextDecoration.lineThrough,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (marca.descripcion != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        marca.descripcion!,
                        style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.5),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.event,
                          size: 16,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Venció: ${DateFormat('dd/MM/yyyy HH:mm').format(marca.fechaHora)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    if (categoria != null) ...[
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: categoria!.colorObj.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          categoria!.nombre,
                          style: TextStyle(
                            fontSize: 12,
                            color: categoria!.colorObj.withOpacity(0.7),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline),
                color: Colors.red[300],
                onPressed: () => _confirmFinish(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmFinish(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Finalizar y eliminar'),
        content: Text('¿Eliminar permanentemente "${marca.nombre}" del historial?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              context.read<AppProvider>().finalizarMarca(marca.id!);
              Navigator.pop(ctx);
            },
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}