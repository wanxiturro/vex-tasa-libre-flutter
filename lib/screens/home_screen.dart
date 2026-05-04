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
import 'package:shared_preferences/shared_preferences.dart';
import '../data/providers/theme_provider.dart';
import '../widgets/custom_color_buttom.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
  
  String _selectedCurrency = 'USD';
  final TextEditingController _amountController = TextEditingController(text: '1');
  double _conversionResult = 0;
  double _foreignAmount = 0;
  final TextEditingController _bsController = TextEditingController(text: '0.00');
  
  final Map<String, double> _tasasAnteriores = {};

  bool _showCustomRatesMenu = false;
  bool _hasVotedToday = false;

  @override
  void initState() {
    super.initState();
    _loadVoteStatus();
    _cargarTasas();
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
        _updateConversions();
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

  void _updateConversions() {
    if (_tasasData == null) return;
    
    final ratesRaw = _tasasData!['rates'];
    final rates = Map<String, double>.from(ratesRaw as Map);
    final amount = double.tryParse(_amountController.text) ?? 1;

    final tasa = rates[_selectedCurrency] 
        ?? _tasaService.getCustomRates()[_selectedCurrency] 
        ?? 0;
  
    setState(() {
      _conversionResult = amount * tasa;
      _foreignAmount = amount;
      _bsController.text = _conversionResult.toStringAsFixed(2);
    });
  }

  void _updateFromBs() {
    if (_tasasData == null) return;
    
    final ratesRaw = _tasasData!['rates'];
    final rates = Map<String, double>.from(ratesRaw as Map);
    final bsAmount = double.tryParse(_bsController.text) ?? 0;

    final tasa = rates[_selectedCurrency] 
        ?? _tasaService.getCustomRates()[_selectedCurrency] 
        ?? 0;
  
    setState(() {
      _conversionResult = bsAmount;
      _foreignAmount = tasa > 0 ? bsAmount / tasa : 0;
      _amountController.text = _foreignAmount.toStringAsFixed(2);
    });
  }

  String _getTodayKey() {
    return DateTime.now().toIso8601String().split('T')[0];
  }

  Future<void> _loadVoteStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final savedDate = prefs.getString('last_vote_date');
    final todayKey = _getTodayKey();

    if (mounted) {
      setState(() {
        _hasVotedToday = savedDate == todayKey;
      });
    }
  }

  Future<void> _vote(bool isUp) async {
    if (_hasVotedToday) return;

    final todayKey = _getTodayKey();
    final docRef = FirebaseFirestore.instance.collection('votes').doc(todayKey);

    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);
      if (!snapshot.exists) {
        transaction.set(docRef, {'up': isUp ? 1 : 0, 'down': isUp ? 0 : 1});
      } else {
        final data = snapshot.data()!;
        final up = data['up'] ?? 0;
        final down = data['down'] ?? 0;
        transaction.update(docRef, {
          'up': up + (isUp ? 1 : 0),
          'down': down + (isUp ? 0 : 1),
        });
      }
    });

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_vote_date', todayKey);

    if (mounted) {
      setState(() {
        _hasVotedToday = true;
      });
    }
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
        backgroundColor: themeProvider.converterCardColor,
        shape: const CircleBorder(),
        child: const Icon(
          Icons.palette,
          color: Colors.white,
          size: 28,
        ), 
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
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildTab('Dólar BCV', 
                    isSelected: _selectedCurrency == 'USD',
                    onTap: () {
                      setState(() {
                        _selectedCurrency = 'USD';
                        _updateConversions();
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
                        _updateConversions();
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
                        _updateConversions();
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
                              _updateConversions();
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

            _buildConverterCard(rates, themeProvider),
            
            const SizedBox(height: 24),
            
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
  
            const SizedBox(height: 24),
            
            _buildPollWidget(themeProvider),
  
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
                              color: themeProvider.secondaryTextColor,
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
                          debugPrint('Error al abrir URL, intentalo más tarde.');
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
                      _updateConversions();
                    },
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 7),
          
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

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                Expanded(
                  child: TextField(
                    controller: _bsController,
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
                      _updateFromBs();
                    },
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

  Widget _buildPollWidget(ThemeProvider themeProvider) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('votes').doc(_getTodayKey()).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Container(); // O mostrar error
        }

        final data = snapshot.data?.data() as Map<String, dynamic>? ?? {};
        final up = data['up'] ?? 0;
        final down = data['down'] ?? 0;
        final total = up + down;
        final upPercent = total > 0 ? (up / total * 100).round() : 0;
        final downPercent = total > 0 ? (down / total * 100).round() : 0;

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: themeProvider.rateCardColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text('📈', style: TextStyle(fontSize: 24)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '¿El dólar subirá mañana?',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: themeProvider.textColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              if (!_hasVotedToday) ...[
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _vote(true),
                        icon: const Icon(Icons.trending_up, color: Colors.white),
                        label: const Text('Sí', style: TextStyle(color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade600,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _vote(false),
                        icon: const Icon(Icons.trending_down, color: Colors.white),
                        label: const Text('No', style: TextStyle(color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade600,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                      ),
                    ),
                  ],
                ),
              ] else ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.blue.shade200.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle, color: Colors.blue, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        '¡Gracias por votar! Vuelve mañana.',
                        style: TextStyle(
                          color: themeProvider.secondaryTextColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 20),
              Text(
                'Resultados en tiempo real ($total votos)',
                style: TextStyle(
                  fontSize: 14,
                  color: themeProvider.secondaryTextColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 16),
              _buildVoteResult(
                label: 'Subirá',
                percent: upPercent,
                count: up,
                color: Colors.green,
                themeProvider: themeProvider,
              ),
              const SizedBox(height: 12),
              _buildVoteResult(
                label: 'No subirá',
                percent: downPercent,
                count: down,
                color: Colors.red,
                themeProvider: themeProvider,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildVoteResult({
    required String label,
    required int percent,
    required int count,
    required Color color,
    required ThemeProvider themeProvider,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: themeProvider.textColor,
              ),
            ),
            Text(
              '$percent% ($count)',
              style: TextStyle(
                fontSize: 14,
                color: themeProvider.secondaryTextColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          height: 8,
          decoration: BoxDecoration(
            color: themeProvider.lineCardColor,
            borderRadius: BorderRadius.circular(4),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percent / 100,
              backgroundColor: Colors.transparent,
              valueColor: AlwaysStoppedAnimation<Color>(color.withOpacity(0.8)),
            ),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    _bsController.dispose();
    super.dispose();
  }
}