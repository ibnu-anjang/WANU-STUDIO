import 'package:flutter/material.dart';

const _labels = {
  'pending': 'Menunggu pembayaran',
  'paid': 'Dibayar',
  'processing': 'Diproses',
  'shipped': 'Dikirim',
  'completed': 'Selesai',
  'cancelled': 'Dibatalkan',
  'expired': 'Kedaluwarsa',
};

const _colors = {
  'pending': Color(0xFFFBBF24),
  'paid': Color(0xFF34D399),
  'processing': Color(0xFF60A5FA),
  'shipped': Color(0xFF60A5FA),
  'completed': Color(0xFF34D399),
  'cancelled': Color(0xFFFB7185),
  'expired': Color(0xFF9CA3AF),
};

String orderStatusLabel(String status) => _labels[status] ?? status;

Widget orderStatusChip(String status) {
  final color = _colors[status] ?? const Color(0xFF9CA3AF);
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.14),
      borderRadius: BorderRadius.circular(999),
      border: Border.all(color: color.withValues(alpha: 0.35)),
    ),
    child: Text(
      orderStatusLabel(status),
      style: TextStyle(
        color: color,
        fontSize: 11.5,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}
