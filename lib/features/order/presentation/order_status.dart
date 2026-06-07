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
  'pending': Colors.orange,
  'paid': Colors.green,
  'processing': Colors.blue,
  'shipped': Colors.blue,
  'completed': Colors.green,
  'cancelled': Colors.red,
  'expired': Colors.grey,
};

String orderStatusLabel(String status) => _labels[status] ?? status;

Widget orderStatusChip(String status) {
  final color = _colors[status] ?? Colors.grey;
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.15),
      borderRadius: BorderRadius.circular(6),
    ),
    child: Text(
      orderStatusLabel(status),
      style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600),
    ),
  );
}
