import 'package:flutter/material.dart';

class TasaModel {
  final String nombre;
  final String cambio;
  final Color colorCambio;
  final String precioUSD;
  final String tasa;
  final IconData icono;
  final double valor;

  TasaModel({
    required this.nombre,
    required this.cambio,
    required this.colorCambio,
    required this.precioUSD,
    required this.tasa,
    required this.icono,
    required this.valor,
  });

  factory TasaModel.fromData(String codigo, double valor, double valorAnterior) {
    final diferencia = valor - valorAnterior;
    final porcentaje = valorAnterior > 0 ? (diferencia / valorAnterior) * 100 : 0;
    
    String cambio;
    Color colorCambio;
    
    if (diferencia > 0.01) {
      cambio = '↗ +${porcentaje.toStringAsFixed(1)}%';
      colorCambio = Colors.green;
    } else if (diferencia < -0.01) {
      cambio = '↘ ${porcentaje.toStringAsFixed(1)}%';
      colorCambio = Colors.red;
    } else {
      cambio = '— 0.0%';
      colorCambio = Colors.grey;
    }

    IconData icono;
    String nombreCompleto;
    
    switch (codigo.toUpperCase()) {
      case 'USD':
        nombreCompleto = 'Dólar BCV';
        icono = Icons.attach_money;
        break;
      case 'EUR':
        nombreCompleto = 'Euro BCV';
        icono = Icons.euro;
        break;
      case 'USDT':
        nombreCompleto = 'USDT';
        icono = Icons.donut_large;
        break;
      case 'BTC':
        nombreCompleto = 'Bitcoin';
        icono = Icons.currency_bitcoin;
        break;
      case 'ETH':
        nombreCompleto = 'Ethereum';
        icono = Icons.currency_bitcoin;
        break;
      default:
        nombreCompleto = codigo;
        icono = Icons.currency_exchange;
    }

    // Calcular precio en USD (inverso de la tasa)
    final precioEnUsd = 1 / valor;

    return TasaModel(
      nombre: nombreCompleto,
      cambio: cambio,
      colorCambio: colorCambio,
      precioUSD: 'Bs ${valor.toStringAsFixed(2)}',
      tasa: '\$ ${precioEnUsd.toStringAsFixed(7)}',
      icono: icono,
      valor: valor,
    );
  }
}