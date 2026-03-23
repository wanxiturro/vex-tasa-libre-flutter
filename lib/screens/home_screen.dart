// lib/screens/home_screen.dart
// ignore_for_file: deprecated_member_use

import 'dart:async';

import 'package:flutter/material.dart';
import '../data/services/tasa_service.dart';
import '../data/models/tasa_models.dart';
import '../widgets/custom_rate_dialog.dart';
import '../widgets/custom_rate_menu.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import '../data/providers/theme_provider.dart';
import '../widgets/custom_color_buttom.dart';

class HomeScreen extends StatefulWidget {
  final Future<Map<String, dynamic>>? preloadFuture;

  const HomeScreen({super.key, this.preloadFuture});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TasaService _tasaService = TasaService();
  Map<String, dynamic>? _tasasData;
  bool _isLoading = true;
  String? _errorMessage;
  
  // Variables para el conversor
  String _selectedCurrency = 'USD';
  final TextEditingController _amountController = TextEditingController(text: '1');
  double _conversionResult = 0;
  
  // Tasas anteriores para calcular cambios
  final Map<String, double> _tasasAnteriores = {};

  bool _showCustomRatesMenu = false;

  @override
  void initState() {
    super.initState();
    _cargarTasas();
    // Actualizar cada 5 minutos
    Timer.periodic(const Duration(minutes: 5), (timer) {
      if (mounted) {
        _cargarTasas();
      }
    });
  }

  Future<void> _cargarTasas() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final data = await (widget.preloadFuture ?? _tasaService.getTasas());
      
      setState(() {

        if(_tasasData != null){
          final rateViejas = _tasasData!['rates'] as Map<String, double>? ?? {};
            rateViejas.forEach((key, value) {
              _tasasAnteriores[key] = value;
            },
          );
        }

        _tasasData = data;
        _isLoading = false;
        _actualizarConversion();
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error al cargar tasas: $e';
        _isLoading = false;
      });
    }
  }

  void _showAddCustomRateDialog() {
    showDialog(
      context: context,
      builder: (context) => CustomRateDialog(
        onSave: (nombre, tasa) async {
          await _tasaService.saveCustomRate(nombre, tasa);
          await _cargarTasas();
          setState(() {});
        },
      ),
    );
  }

  void _actualizarConversion() {
    if (_tasasData == null) return;
    
    final ratesRaw = _tasasData!['rates'];
    final rates = Map<String, double>.from(ratesRaw as Map);
    final amount = double.tryParse(_amountController.text) ?? 1;

    final tasa = rates[_selectedCurrency] 
        ?? _tasaService.getCustomRates()[_selectedCurrency] 
        ?? 0;
  
    setState(() {
      _conversionResult = amount * tasa;
    });
  }

  void _showCustomizationMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Color(0xFF1E1F24),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: const CustomColorButton(),
      ),
    );
  }

  String _getSimboloMoneda(String moneda) {
    switch (moneda) {
      case 'USD':
        return '\$';
      case 'EUR':
        return '€';
      case 'USDT':
        return '₮';
      default:
        return '🏷';
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      backgroundColor: themeProvider.backgroundColor,
      appBar: _buildAppBar(themeProvider),
      body: _buildBody(themeProvider),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showCustomizationMenu(context);
        },
        backgroundColor: const Color.fromARGB(255, 77, 170, 2),
        shape: const CircleBorder(),
        child: const Icon(
          Icons.palette,
          color: Colors.white,
          size: 28,
        ), // Esto asegura que sea redondo
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  PreferredSizeWidget _buildAppBar(ThemeProvider themeProvider) {
    return AppBar(
      backgroundColor: themeProvider.appBarColor,
      elevation: 0,
      title: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Image.asset(
            'assets/imagenes/logo-512x512.png',
            width: 50,
            height: 50,
            fit: BoxFit.contain,
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Vex',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color.fromARGB(255, 77, 170, 2),
                ),
              ),
              Text(
                'TASA LIBRE DE VENEZUELA',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBody(ThemeProvider themeProvider) {
    if (_isLoading && _tasasData == null) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color.fromARGB(255, 77, 170, 2),
        ),
      );
    }
  
    if (_errorMessage != null && _tasasData == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: Colors.red[300], size: 48),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: const TextStyle(color: Colors.white),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _cargarTasas,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 77, 170, 2),
              ),
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }
  
    final ratesRaw = _tasasData?['rates'];
    final rates = ratesRaw != null
    ? Map<String, double>.from(ratesRaw as Map)
    : <String, double>{};
    final fechaActualizacion = _tasasData?['fecha'] ?? '';
    final hasCustomRates = _tasasData?['hasCustomRates'] ?? false;
  

    const ordenDeseado = ['USD', 'EUR', 'USDT'];
    final entradasOrdenadas = [

      ...ordenDeseado
          .where((key) => rates.containsKey(key))
          .map((key) => MapEntry(key, rates[key]!)),

      ...rates.entries.where((e) => !ordenDeseado.contains(e.key)),
    ];
    return RefreshIndicator(
      onRefresh: _cargarTasas,
      color: const Color.fromARGB(255, 77, 170, 2),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Currency tabs
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildTab('Dólar BCV', 
                    isSelected: _selectedCurrency == 'USD',
                    onTap: () {
                      setState(() {
                        _selectedCurrency = 'USD';
                        _actualizarConversion();
                      });
                    },
                    themeProvider: themeProvider,
                  ),
                  const SizedBox(width: 8),
                  _buildTab('Euro BCV',
                    isSelected: _selectedCurrency == 'EUR',
                    onTap: () {
                      setState(() {
                        _selectedCurrency = 'EUR';
                        _actualizarConversion();
                      });
                    },
                    themeProvider: themeProvider
                  ),
                  const SizedBox(width: 8),
                  _buildTab('USDT',
                    isSelected: _selectedCurrency == 'USDT',
                    onTap: () {
                      setState(() {
                        _selectedCurrency = 'USDT';
                        _actualizarConversion();
                      });
                    },
                    themeProvider: themeProvider
                  ),
                  ..._tasaService.getCustomRates().entries.map((entry) {
                    return Row(
                      children: [
                        const SizedBox(width: 8,),
                          _buildTab(
                            entry.key, 
                            isSelected: _selectedCurrency == entry.key, 
                            onTap: () => setState(() {
                              _selectedCurrency = entry.key;
                              _actualizarConversion();
                            }),
                            themeProvider: themeProvider
                          )
                        ],
                      );
                    },
                  ),
                  const SizedBox(width: 8),
                  _buildTab('+ Personalizada',
                    isSelected: _showCustomRatesMenu,
                    onTap: () {
                      setState(() {
                        _showCustomRatesMenu = !_showCustomRatesMenu;
                      });
                    },
                    themeProvider: themeProvider
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            if (_showCustomRatesMenu) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: themeProvider.rateCardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color.fromARGB(255, 77, 170, 2).withOpacity(0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Tasas Personalizadas',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: themeProvider.textColor
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: Icon(Icons.add, color: themeProvider.converterCardColor),
                          onPressed: () => _showAddCustomRateDialog(),
                        ),
                      ],
                    ),
                    const Divider(color: Color(0xFF2C2D33)),
                    CustomRatesMenu(
                      tasaService: _tasaService,
                      onRatesUpdated: _cargarTasas,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
            
            // Converter card
            _buildConverterCard(rates, themeProvider),
            
            const SizedBox(height: 24),
            
            // All rates section
            Row(
              children: [
                Text(
                  'Todas las tasas',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: themeProvider.textColor,
                  ),
                ),
                const Spacer(),
                if (hasCustomRates)
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(255, 255, 215, 0).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.star,
                          color: Color.fromARGB(255, 255, 215, 0),
                          size: 12,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Incluye personalizadas',
                          style: TextStyle(
                            fontSize: 10,
                            color: themeProvider.secondaryTextColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: themeProvider.backgroundColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _tasasData?['source'] == 'dolarapi.com' 
                              ? Colors.green 
                              : _tasasData?['source'] == 'pydolarve.org'
                                  ? Colors.orange
                                  : Colors.grey,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _tasasData?['source'] ?? 'local',
                        style: TextStyle(
                          fontSize: 10,
                          color: themeProvider.secondaryTextColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 8),
            
            Text(
              fechaActualizacion,
              style: TextStyle(
                fontSize: 14,
                color: themeProvider.secondaryTextColor,
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Rates list
            
            ...entradasOrdenadas.map((entry) {
              final tasaAnterior = _tasasAnteriores[entry.key] ?? entry.value;
              final model = TasaModel.fromData(
                entry.key, 
                entry.value,
                tasaAnterior,
              );
              
              
              return Column(
                children: [
                  _buildRateCard(model, themeProvider),
                  const SizedBox(height: 12),
                ],
              );
            }),
  
            const SizedBox(height: 32),

            Align(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 22, 22, 20),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.08),
                    width: 1,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: TextStyle(
                          color: themeProvider.secondaryTextColor,
                          fontSize: 13,
                          height: 1.4,
                          fontWeight: FontWeight.w200,
                          letterSpacing: 0.2,
                        ),
                        children: [
                          const TextSpan(
                            text: "Proyecto de ",
                          ),
                          TextSpan(
                            text: "código abierto",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: themeProvider.secondaryTextColor, // Un poco más brillante
                            ),
                          ),
                          const TextSpan(
                            text: " sin fines de lucro. Creado para traer software funcional, atractivo y poco intrusivo a Venezuela.",
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    GestureDetector(
                      onTap: () async {
                        final Uri url = Uri.parse('https://github.com/wanxiturro/vex-tasa-libre-flutter');
                        try {
                          final bool launched = await launchUrl(
                            url,
                            mode: LaunchMode.externalApplication,
                          );
                          if (!launched) {
                            await launchUrl(
                              url,
                              mode: LaunchMode.platformDefault,
                            );
                          }
                        } catch (e) {
                          debugPrint('Error al abrir URL: $e');
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.03),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.1),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.code,
                              color: Colors.white.withOpacity(0.5),
                              size: 14,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              "Ver en GitHub",
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 12,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),           
          ],
        ),
      ),
    );
  }

  Widget _buildConverterCard(Map<String, double> rates, ThemeProvider themeProvider) {
    final tasaActual = rates[_selectedCurrency] ?? _tasaService.getCustomRates()[_selectedCurrency] ?? 0;
    final simbolo = _getSimboloMoneda(_selectedCurrency);
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: themeProvider.converterCardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'TENGO',
            style: TextStyle(
              fontSize: 12,
              color: Color.fromARGB(91, 22, 21, 25),
              fontWeight: FontWeight.w500,
            ),
          ),
          
          const SizedBox(height: 7),
          
          // Input
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: themeProvider.lineCardColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Text(
                  '$simbolo ',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color.fromARGB(150, 22, 21, 25),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(
                      fontSize: 20,
                      color: Color.fromARGB(255, 22, 21, 25),
                      fontWeight: FontWeight.bold,
                    ),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    onChanged: (value) {
                      _actualizarConversion();
                    },
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 7),
          
          // Rate
          Container(
            padding: const EdgeInsets.all(1),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '1 $_selectedCurrency = Bs ',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color.fromARGB(91, 22, 21, 25),
                    fontStyle: FontStyle.italic,
                  ),
                ),
                Text(
                  tasaActual.toStringAsFixed(2),
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color.fromARGB(91, 22, 21, 25),
                    fontWeight: FontWeight.bold,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 7),

          Text(
            'RECIBO (BS) — $_selectedCurrency',
            style: const TextStyle(
              fontSize: 12,
              color: Color.fromARGB(91, 22, 21, 25),
              fontWeight: FontWeight.bold,
            ),
          ),
                
          const SizedBox(height: 5),
          
          // Result
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            decoration: BoxDecoration(
              color: themeProvider.lineCardColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Text(
                  'Bs ',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color.fromARGB(150, 22, 21, 25),
                  ),
                ),
                Text(
                  _conversionResult.toStringAsFixed(2),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color.fromARGB(255, 22, 21, 25),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTab(String text, {required bool isSelected, required VoidCallback onTap, required ThemeProvider themeProvider}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected 
            ? themeProvider.converterCardColor
            : themeProvider.rateCardColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isSelected 
                ? const Color.fromARGB(255, 22, 21, 25) 
                : Colors.grey,
            fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildRateCard(TasaModel model, ThemeProvider themeProvider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: themeProvider.rateCardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          // Icon
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF2C2D33),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              model.icono,
              color: Colors.white,
              size: 20,
            ),
          ),
          
          const SizedBox(width: 12),
          
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      model.nombre,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: themeProvider.textColor,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      model.cambio,
                      style: TextStyle(
                        fontSize: 14,
                        color: model.colorCambio,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Price
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                model.precioUSD,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: themeProvider.textColor,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                model.tasa,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }


  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }
}