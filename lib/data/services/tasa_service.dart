// ignore_for_file: depend_on_referenced_packages

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class TasaService {
  static final TasaService _instance = TasaService._internal();
  factory TasaService() => _instance;
  TasaService._internal();

  Map<String, dynamic>? _cacheData;
  DateTime? _lastFetch;
  final Duration _cacheDuration = const Duration(minutes: 5);

  final Map<String, double> _backupRates = {
    'USD': 446.80,
    'EUR': 511.22,
    'USDT': 630.00,
  };

  Map<String, double> _customRates = {};

  Future<void> initCustomRates() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? customRatesString = prefs.getString('custom_rates');
      if (customRatesString != null) {
        final decoded = json.decode(customRatesString) as Map<String, dynamic>;
        _customRates = decoded.map(
          (key, value) => MapEntry(key, (value as num).toDouble()),
        );
      }
    } catch (_) {}
  }

  Future<void> saveCustomRate(String nombre, double tasa) async {
    try {
      _customRates[nombre] = tasa;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('custom_rates', json.encode(_customRates));
    } catch (_) {}
  }

  Future<void> deleteCustomRate(String nombre) async {
    try {
      _customRates.remove(nombre);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('custom_rates', json.encode(_customRates));
    } catch (_) {}
  }

  Future<Map<String, dynamic>> getTasas({bool includeCustom = true}) async {
    if (_cacheData != null && _lastFetch != null) {
      final age = DateTime.now().difference(_lastFetch!);
      if (age < _cacheDuration) {
        if (includeCustom && _customRates.isNotEmpty) {
          final dataWithCustom = Map<String, dynamic>.from(_cacheData!);
          final rates = Map<String, double>.from(
            (dataWithCustom['rates'] as Map).map(
              (k, v) => MapEntry(k.toString(), (v as num).toDouble()),
            ),
          );
          rates.addAll(_customRates);
          dataWithCustom['rates'] = rates;
          dataWithCustom['hasCustomRates'] = true;
          return dataWithCustom;
        }
        return _cacheData!;
      }
    }

    final Map<String, double> tasas = {};
    DateTime fechaActualizacion = DateTime.now();
    String source = 'backup-local';

    // — Dólares —
    try {
      final response = await http
          .get(Uri.parse('https://ve.dolarapi.com/v1/dolares'))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as List<dynamic>;
        for (final item in data) {
          final map = item as Map<String, dynamic>;
          final fuente = (map['fuente'] as String?)?.toLowerCase() ?? '';
          final promedio = (map['promedio'] as num?)?.toDouble();
          if (promedio != null) {
            if (fuente == 'oficial') tasas['USD'] = promedio;
            if (fuente == 'paralelo') tasas['Paralelo'] = promedio;
          }
        }
        if (data.isNotEmpty) {
          final first = data.first as Map<String, dynamic>;
          if (first['fechaActualizacion'] != null) {
            fechaActualizacion = DateTime.parse(
              first['fechaActualizacion'] as String,
            );
          }
        }
        source = 'dolarapi.com';
      }
    } catch (e) {
      debugPrint('❌ dolarapi dolares: $e');
    }

    // — Euros —
    try {
      final response = await http
          .get(Uri.parse('https://ve.dolarapi.com/v1/euros'))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as List<dynamic>;
        for (final item in data) {
          final map = item as Map<String, dynamic>;
          final fuente = (map['fuente'] as String?)?.toLowerCase() ?? '';
          final promedio = (map['promedio'] as num?)?.toDouble();
          if (promedio != null && fuente == 'oficial') {
            tasas['EUR'] = promedio;
          }
        }
      }
    } catch (e) {
      debugPrint('❌ dolarapi euros: $e');
    }

    // — USDT desde pydolarve —
    try {
      final response = await http
          .get(Uri.parse('https://pydolarve.org/api/v1/dollar'))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;

        final usdt = data['usdt'] as Map<String, dynamic>?;
        final usd = data['usd'] as Map<String, dynamic>?;
        final eur = data['eur'] as Map<String, dynamic>?;

        if (usdt != null) {
          tasas['USDT'] = (usdt['price'] as num).toDouble();
        }
        if (!tasas.containsKey('USD') && usd != null) {
          tasas['USD'] = (usd['price'] as num).toDouble();
          source = 'pydolarve.org';
        }
        if (!tasas.containsKey('EUR') && eur != null) {
          tasas['EUR'] = (eur['price'] as num).toDouble();
        }
      }
    } catch (e) {
      debugPrint('❌ pydolarve: $e');
    }

    // — Respaldo —
    if (tasas.isEmpty) {
      return _obtenerDatosRespaldo();
    }

    final result = <String, dynamic>{
      'rates': tasas,
      'lastUpdate': fechaActualizacion,
      'source': source,
      'fecha': _formatearFecha(fechaActualizacion),
    };

    _actualizarCache(result);

    if (includeCustom && _customRates.isNotEmpty) {
      final dataWithCustom = Map<String, dynamic>.from(result);
      final rates = Map<String, double>.from(tasas);
      rates.addAll(_customRates);
      dataWithCustom['rates'] = rates;
      dataWithCustom['hasCustomRates'] = true;
      return dataWithCustom;
    }

    return result;
  }

  Map<String, double> getCustomRates() {
    return Map<String, double>.from(_customRates);
  }

  Map<String, dynamic> _obtenerDatosRespaldo() {
    return <String, dynamic>{
      'rates': Map<String, double>.from(_backupRates),
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
      'jul', 'ago', 'sep', 'oct', 'nov', 'dic',
    ];
    final dia = fechaCaracas.day.toString().padLeft(2, '0');
    final mes = meses[fechaCaracas.month - 1];
    int hora12 = fechaCaracas.hour % 12;
    hora12 = hora12 == 0 ? 12 : hora12;
    final minuto = fechaCaracas.minute.toString().padLeft(2, '0');
    final ampm = fechaCaracas.hour >= 12 ? 'p. m.' : 'a. m.';
    return '$dia-$mes., $hora12:$minuto $ampm';
  }
}