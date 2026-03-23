// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/providers/theme_provider.dart';

class CustomColorButton extends StatefulWidget {
  const CustomColorButton({super.key});

  @override
  State<CustomColorButton> createState() => _CustomColorButtonState();
}

class _CustomColorButtonState extends State<CustomColorButton> {
  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF1E1F24),
            const Color(0xFF2C2D33),
          ],
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header con ícono y título
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color.fromARGB(255, 77, 170, 2), Color.fromARGB(255, 100, 200, 10)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.palette,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Personalizar Apariencia',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Elige el tema que más te guste',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              // Botón para resetear
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: IconButton(
                  icon: const Icon(Icons.refresh, size: 20),
                  color: const Color.fromARGB(255, 77, 170, 2),
                  onPressed: () {
                    themeProvider.resetToDefault();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Colores restablecidos a valores predeterminados'),
                        duration: Duration(seconds: 2),
                        backgroundColor: Color.fromARGB(255, 77, 170, 2),
                      ),
                    );
                  },
                  tooltip: 'Restablecer',
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Sección: Modo Oscuro/Claro
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withOpacity(0.1),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(255, 77, 170, 2).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.dark_mode,
                        color: Color.fromARGB(255, 77, 170, 2),
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Modo de fondo',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Switch elegante para cambiar entre oscuro/claro
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildThemeOption(
                        icon: Icons.light_mode,
                        label: 'Claro',
                        isSelected: !themeProvider.isDarkMode,
                        color: Colors.amber,
                        onTap: () => themeProvider.setLightMode(),
                      ),
                      _buildThemeOption(
                        icon: Icons.dark_mode,
                        label: 'Oscuro',
                        isSelected: themeProvider.isDarkMode,
                        color: Colors.blueGrey,
                        onTap: () => themeProvider.setDarkMode(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Sección: Color del card del dólar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withOpacity(0.1),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(255, 77, 170, 2).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.attach_money,
                        color: Color.fromARGB(255, 77, 170, 2),
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Color del bloque del dólar',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Vista previa del color actual
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: themeProvider.converterCardColor,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: themeProvider.converterCardColor.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.attach_money,
                        color: Colors.white,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Vista previa del color',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        _getColorHexFromColor(themeProvider.converterCardColor),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Selector de colores
                const Text(
                  'Elige un color',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 12),
                
                // Paleta de colores predefinidos
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _buildColorCircle(
                      color: const Color.fromARGB(255, 91, 165, 35),
                      isSelected: themeProvider.converterCardColor == const Color.fromARGB(255, 91, 165, 35),
                      onTap: () => themeProvider.setConverterCardColor(const Color.fromARGB(255, 91, 165, 35)),
                    ),
                    _buildColorCircle(
                      color: Colors.blue[700]!,
                      isSelected: themeProvider.converterCardColor == Colors.blue[700],
                      onTap: () => themeProvider.setConverterCardColor(Colors.blue[700]!),
                    ),
                    _buildColorCircle(
                      color: Colors.red[700]!,
                      isSelected: themeProvider.converterCardColor == Colors.red[700],
                      onTap: () => themeProvider.setConverterCardColor(Colors.red[700]!),
                    ),
                    _buildColorCircle(
                      color: Colors.purple[700]!,
                      isSelected: themeProvider.converterCardColor == Colors.purple[700],
                      onTap: () => themeProvider.setConverterCardColor(Colors.purple[700]!),
                    ),
                    _buildColorCircle(
                      color: Colors.orange[700]!,
                      isSelected: themeProvider.converterCardColor == Colors.orange[700],
                      onTap: () => themeProvider.setConverterCardColor(Colors.orange[700]!),
                    ),
                    _buildColorCircle(
                      color: Colors.teal[700]!,
                      isSelected: themeProvider.converterCardColor == Colors.teal[700],
                      onTap: () => themeProvider.setConverterCardColor(Colors.teal[700]!),
                    ),
                    _buildColorCircle(
                      color: Colors.pink[700]!,
                      isSelected: themeProvider.converterCardColor == Colors.pink[700],
                      onTap: () => themeProvider.setConverterCardColor(Colors.pink[700]!),
                    ),
                    _buildColorCircle(
                      color: Colors.cyan[700]!,
                      isSelected: themeProvider.converterCardColor == Colors.cyan[700],
                      onTap: () => themeProvider.setConverterCardColor(Colors.cyan[700]!),
                    ),
                    _buildColorCircle(
                      color: Colors.indigo[700]!,
                      isSelected: themeProvider.converterCardColor == Colors.indigo[700],
                      onTap: () => themeProvider.setConverterCardColor(Colors.indigo[700]!),
                    ),
                    _buildColorCircle(
                      color: Colors.amber[700]!,
                      isSelected: themeProvider.converterCardColor == Colors.amber[700],
                      onTap: () => themeProvider.setConverterCardColor(Colors.amber[700]!),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Botón para selector personalizado
                GestureDetector(
                  onTap: () async {
                    final Color? pickedColor = await showDialog<Color>(
                      context: context,
                      builder: (BuildContext context) {
                        Color tempColor = themeProvider.converterCardColor;
                        return AlertDialog(
                          title: const Text('Selecciona un color'),
                          content: StatefulBuilder(
                            builder: (context, setState) {
                              return Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: double.infinity,
                                    height: 100,
                                    decoration: BoxDecoration(
                                      color: tempColor,
                                      borderRadius: BorderRadius.circular(8),
                                      boxShadow: [
                                        BoxShadow(
                                          color: tempColor.withOpacity(0.3),
                                          blurRadius: 10,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  SimpleColorPicker(
                                    color: tempColor,
                                    onColorChanged: (color) {
                                      setState(() {
                                        tempColor = color;
                                      });
                                    },
                                  ),
                                ],
                              );
                            },
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Cancelar'),
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color.fromARGB(255, 77, 170, 2),
                              ),
                              onPressed: () => Navigator.pop(context, tempColor),
                              child: const Text('Aceptar'),
                            ),
                          ],
                        );
                      },
                    );
                    
                    if (pickedColor != null) {
                      themeProvider.setConverterCardColor(pickedColor);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color.fromARGB(255, 77, 170, 2).withOpacity(0.2),
                          const Color.fromARGB(255, 77, 170, 2).withOpacity(0.1),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color.fromARGB(255, 77, 170, 2).withOpacity(0.3),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.color_lens,
                          size: 18,
                          color: Color.fromARGB(255, 77, 170, 2),
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Selector personalizado',
                          style: TextStyle(
                            color: Color.fromARGB(255, 77, 170, 2),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Mensaje de ayuda
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.blue.withOpacity(0.2),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 16,
                  color: Colors.blue[300],
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Los cambios se aplican automáticamente. Puedes restablecer los colores predeterminados en cualquier momento.',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[400],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeOption({
    required IconData icon,
    required String label,
    required bool isSelected,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? color.withOpacity(0.3) : Colors.transparent,
            borderRadius: BorderRadius.circular(24),
            border: isSelected
                ? Border.all(color: color, width: 1)
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isSelected ? color : Colors.grey,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildColorCircle({
    required Color color,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.5),
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
                ]
              : null,
          border: isSelected
              ? Border.all(color: Colors.white, width: 3)
              : Border.all(color: Colors.grey[800]!, width: 2),
        ),
        child: isSelected
            ? const Center(
                child: Icon(
                  Icons.check,
                  color: Colors.white,
                  size: 20,
                ),
              )
            : null,
      ),
    );
  }

  String _getColorHexFromColor(Color color) {
    return '#${color.value.toRadixString(16).substring(2).toUpperCase()}';
  }
}

// Selector de color simple
class SimpleColorPicker extends StatelessWidget {
  final Color color;
  final Function(Color) onColorChanged;

  const SimpleColorPicker({
    super.key,
    required this.color,
    required this.onColorChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Selector de matiz (Hue)
        Container(
          height: 40,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                Colors.red,
                Colors.yellow,
                Colors.green,
                Colors.cyan,
                Colors.blue,
                Colors.purple,
                Colors.red,
              ],
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: GestureDetector(
            onHorizontalDragUpdate: (details) {
              final RenderBox box = context.findRenderObject() as RenderBox;
              final position = details.localPosition;
              final width = box.size.width;
              double hue = (position.dx / width).clamp(0.0, 1.0);
              final HSLColor hslColor = HSLColor.fromColor(color);
              final newColor = HSLColor.fromAHSL(1.0, hue * 360, hslColor.saturation, hslColor.lightness).toColor();
              onColorChanged(newColor);
            },
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: Column(
                children: [
                  const Text('Saturación', style: TextStyle(fontSize: 12)),
                  Slider(
                    value: HSLColor.fromColor(color).saturation,
                    onChanged: (value) {
                      final HSLColor hslColor = HSLColor.fromColor(color);
                      final newColor = hslColor.withSaturation(value).toColor();
                      onColorChanged(newColor);
                    },
                  ),
                ],
              ),
            ),
            Expanded(
              child: Column(
                children: [
                  const Text('Luminosidad', style: TextStyle(fontSize: 12)),
                  Slider(
                    value: HSLColor.fromColor(color).lightness,
                    onChanged: (value) {
                      final HSLColor hslColor = HSLColor.fromColor(color);
                      final newColor = hslColor.withLightness(value).toColor();
                      onColorChanged(newColor);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}