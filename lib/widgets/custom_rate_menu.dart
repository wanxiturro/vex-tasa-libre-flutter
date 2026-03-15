// lib/widgets/custom_rates_menu.dart
import 'package:flutter/material.dart';
import 'package:vex_tasa_libre/data/services/tasa_service.dart';

class CustomRatesMenu extends StatefulWidget {
  final TasaService tasaService;
  final Function onRatesUpdated;

  const CustomRatesMenu({
    super.key,
    required this.tasaService,
    required this.onRatesUpdated,
  });

  @override
  State<CustomRatesMenu> createState() => _CustomRatesMenuState();
}

class _CustomRatesMenuState extends State<CustomRatesMenu> {
  Map<String, double> _customRates = {};

  @override
  void initState() {
    super.initState();
    _loadCustomRates();
  }

  void _loadCustomRates() {
    setState(() {
      _customRates = widget.tasaService.getCustomRates();
    });
  }

  @override
  void didUpdateWidget(CustomRatesMenu oldWidget) {
    super.didUpdateWidget(oldWidget);
    _loadCustomRates();
  }

  Future<void> _deleteRate(String nombre) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1F24),
        title: const Text(
          'Eliminar tasa',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          '¿Eliminar "$nombre"?',
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancelar',
              style: TextStyle(color: Colors.grey[400]),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await widget.tasaService.deleteCustomRate(nombre);
      _loadCustomRates();
      widget.onRatesUpdated();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_customRates.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              Icons.star_border,
              size: 48,
              color: Colors.grey[600],
            ),
            const SizedBox(height: 12),
            Text(
              'No tienes tasas personalizadas',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Agrega tu primera tasa tocando el botón +',
              textAlign: TextAlign.center, // 👈 esto faltaba
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _customRates.length,
      itemBuilder: (context, index) {
        final entry = _customRates.entries.elementAt(index);
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1F24),
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF2C2D33),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.star,
                color: Color.fromARGB(255, 255, 215, 0),
                size: 16,
              ),
            ),
            title: Text(
              entry.key,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
            subtitle: Text(
              'Bs ${entry.value.toStringAsFixed(2)}',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: () => _deleteRate(entry.key),
            ),
          ),
        );
      },
    );
  }
}