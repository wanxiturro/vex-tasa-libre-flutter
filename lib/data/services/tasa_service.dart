// ignore_for_file: depend_on_referenced_packages

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart'; // Añade esta dependencia

class TasaService {
  static final TasaService _instance = TasaService._internal();
  factory TasaService() => _instance;
  TasaService._internal();

  // Datos de caché local
  Map<String, dynamic>? _cacheData;
  DateTime? _lastFetch;
  final Duration _cacheDuration = const Duration(minutes: 5);

  final Map<String, double> _backupRates = {
    'USD': 64.50,
    'EUR': 70.20,
    'USDT': 64.80,
    'BTC': 4200000,
    'ETH': 210000,
  };

  Map<String, double> _customRates = {};

  Future<void> initCustomRates() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? customRatesString = prefs.getString('custom_rates');
      if (customRatesString != null) {
        _customRates = Map<String, double>.from(json.decode(customRatesString));
        // print('📝 Tasas personalizadas cargadas: $_customRates');
      }
    } catch (e) {
        //  print('Error cargando tasas personalizadas: $e');
    }
  }

  Future<void> saveCustomRate(String nombre, double tasa) async {
    try {
      _customRates[nombre] = tasa;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('custom_rates', json.encode(_customRates));
      // print('✅ Tasa personalizada guardada: $nombre = $tasa');
    } catch (e) {
      // print('Error guardando tasa personalizada: $e');
    }
  }

  Future<void> deleteCustomRate(String nombre) async {
    try {
      _customRates.remove(nombre);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('custom_rates', json.encode(_customRates));
      // print('✅ Tasa personalizada eliminada: $nombre');
    } catch (e) {
      // print('Error eliminando tasa personalizada: $e');
    }
  }

  Future<Map<String, dynamic>> getTasas({bool includeCustom = true}) async {
    if (_cacheData != null && _lastFetch != null) {
      final age = DateTime.now().difference(_lastFetch!);
      if (age < _cacheDuration) {
        // print('📦 Usando datos en caché');
        if (includeCustom && _customRates.isNotEmpty) {
          final Map<String, dynamic> dataWithCustom = Map.from(_cacheData!);
          final rates = Map<String, double>.from(dataWithCustom['rates']);
          rates.addAll(_customRates);
          dataWithCustom['rates'] = rates;
          dataWithCustom['hasCustomRates'] = true;
          return dataWithCustom;
        }
        return _cacheData!;
      }
    }

    Map<String, dynamic>? result;

    try {
      // print('🌐 Intentando con dolarapi.com...');
      final response = await http
          .get(Uri.parse('https://ve.dolarapi.com/v1/dolares'))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        result = _procesarDolarApi(data);
      }
    } catch (e) {
      // print('❌ Error con dolarapi.com: $e');
    }

    if (result == null) {
      try {
        // print('🌐 Intentando con pydolarve.org...');
        final response = await http
            .get(Uri.parse('https://pydolarve.org/api/v1/dollar'))
            .timeout(const Duration(seconds: 60));

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          result = _procesarPyDolarVe(data);
        }
      } catch (e) {
        // print('❌ Error con pydolarve.org: $e');
      }
    }

    result ??= _obtenerDatosRespaldo();

    _actualizarCache(result);

    if (includeCustom && _customRates.isNotEmpty) {
      final Map<String, dynamic> dataWithCustom = Map.from(result);
      final rates = Map<String, double>.from(result['rates']);
      rates.addAll(_customRates);
      dataWithCustom['rates'] = rates;
      dataWithCustom['hasCustomRates'] = true;
      return dataWithCustom;
    }

    return result;
  }

  Map<String, double> getCustomRates() {
    return Map.from(_customRates);
  }

  Map<String, dynamic> _procesarDolarApi(List<dynamic> data) {
    final Map<String, double> tasas = {};
    
    for (var item in data) {
      final String fuente = item['fuente']?.toString().toLowerCase() ?? '';
      final double? promedio = item['promedio']?.toDouble();
      
      if (promedio != null) {
        if (fuente == 'oficial') {
          tasas['USD'] = promedio;
        } else if (fuente == 'paralelo') {
          tasas['USDT'] = promedio;
        }
      }
    }

    if (!tasas.containsKey('USD') && data.isNotEmpty) {
      final primerItem = data.first;
      if (primerItem['promedio'] != null) {
        tasas['USD'] = primerItem['promedio'].toDouble();
      }
    }

    tasas['EUR'] = (tasas['USD'] ?? 64.50) * 1.1;
    
    DateTime fechaActualizacion = DateTime.now();
    if (data.isNotEmpty && data.first['fechaActualizacion'] != null) {
      try {
        fechaActualizacion = DateTime.parse(data.first['fechaActualizacion']);
      } catch (e) {
        // print('Error parseando fecha: $e');
      }
    }

    return {
      'rates': tasas,
      'lastUpdate': fechaActualizacion,
      'source': 'dolarapi.com',
      'fecha': _formatearFecha(fechaActualizacion),
    };
  }

  Map<String, dynamic> _procesarPyDolarVe(dynamic data) {
    final Map<String, double> tasas = {};
    
    if (data is Map) {
      if (data['usd'] != null) tasas['USD'] = data['usd']['price'].toDouble();
      if (data['eur'] != null) tasas['EUR'] = data['eur']['price'].toDouble();
      if (data['usdt'] != null) tasas['USDT'] = data['usdt']['price'].toDouble();
    }

    if (tasas.isEmpty) {
      tasas['USD'] = 64.50;
      tasas['EUR'] = 70.20;
      tasas['USDT'] = 64.80;
    }

    return {
      'rates': tasas,
      'lastUpdate': DateTime.now(),
      'source': 'pydolarve.org',
      'fecha': _formatearFecha(DateTime.now()),
    };
  }

  Map<String, dynamic> _obtenerDatosRespaldo() {
    return {
      'rates': Map.from(_backupRates),
      'lastUpdate': DateTime.now(),
      'source': 'backup-local',
      'fecha': _formatearFecha(DateTime.now()),
    };
  }

  void _actualizarCache(Map<String, dynamic> data) {
    _cacheData = data;
    _lastFetch = DateTime.now();
  }

  String _formatearFecha(DateTime fecha) {
    
    final fechaCaracas = fecha.toUtc().subtract(const Duration(hours: 4));

    final meses = [
      'ene', 'feb', 'mar', 'abr', 'may', 'jun',
      'jul', 'ago', 'sep', 'oct', 'nov', 'dic'
    ];

    String dia = fechaCaracas.day.toString().padLeft(2, '0');
    String mes = meses[fechaCaracas.month - 1];

    int hora12 = fechaCaracas.hour % 12;
    hora12 = hora12 == 0 ? 12 : hora12;
    String minuto = fechaCaracas.minute.toString().padLeft(2, '0');
    String ampm = fechaCaracas.hour >= 12 ? 'p. m.' : 'a. m.';

    return '$dia-$mes., $hora12:$minuto $ampm';
  }
}