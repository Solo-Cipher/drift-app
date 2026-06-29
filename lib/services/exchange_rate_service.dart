import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Service for currency conversion using free exchange rate API
class ExchangeRateService {
  static const String _baseUrl = 'https://open.er-api.com/v6/latest';
  
  /// Cache: base currency -> (timestamp, rates map)
  static final Map<String, _RateCache> _cache = {};
  
  /// Cache validity: 24 hours
  static const Duration _cacheValidity = Duration(hours: 24);

  /// Convert an amount from one currency to another
  /// Returns the original amount if conversion fails (graceful fallback)
  static Future<double> convert({
    required double amount,
    required String fromCurrency,
    required String toCurrency,
  }) async {
    if (fromCurrency == toCurrency) return amount;
    
    try {
      final rates = await _getRates(toCurrency);
      // API returns rates relative to base currency (toCurrency)
      // So we need the rate for fromCurrency in terms of toCurrency
      final rate = rates[fromCurrency];
      if (rate == null) return amount;
      
      // If 1 toCurrency = rate fromCurrency, then:
      // amount in toCurrency = amount / rate
      return double.parse((amount / rate).toStringAsFixed(2));
    } catch (e) {
      debugPrint('Currency conversion error: $e');
      return amount; // Graceful fallback
    }
  }

  /// Get exchange rates for a base currency
  static Future<Map<String, double>> _getRates(String baseCurrency) async {
    final cached = _cache[baseCurrency];
    if (cached != null && 
        DateTime.now().difference(cached.timestamp) < _cacheValidity) {
      return cached.rates;
    }

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/$baseCurrency'),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final ratesRaw = data['rates'] as Map<String, dynamic>;
        final rates = ratesRaw.map(
          (k, v) => MapEntry(k, (v as num).toDouble()),
        );
        
        _cache[baseCurrency] = _RateCache(
          rates: rates,
          timestamp: DateTime.now(),
        );
        
        return rates;
      }
    } catch (e) {
      debugPrint('Failed to fetch exchange rates: $e');
    }

    // Return cached rates even if expired, or empty
    return cached?.rates ?? {};
  }

  /// Get list of supported currencies
  static Future<List<String>> getSupportedCurrencies() async {
    try {
      final rates = await _getRates('USD');
      final currencies = rates.keys.toList()..sort();
      return currencies;
    } catch (e) {
      // Fallback: common currencies
      return ['USD', 'EUR', 'GBP', 'OMR', 'VND', 'LKR', 'IDR', 'THB', 'JPY', 'TRY', 'MAD', 'MUR'];
    }
  }
}

class _RateCache {
  final Map<String, double> rates;
  final DateTime timestamp;
  
  _RateCache({required this.rates, required this.timestamp});
}
