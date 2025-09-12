import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
// Removed PDF dependencies (dietitian panel removed)
// import 'package:pdf/pdf.dart';
// import 'package:pdf/widgets.dart' as pw;  
// import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import '../models/health_data_model.dart';
import '../models/user_model.dart';
import 'dart:ui' as ui;

class ExportService {
  static const String appName = 'DiyetKent';
  
  /// CSV formatında sağlık verilerini export eder
  static Future<void> exportHealthDataToCSV({
    required List<HealthDataModel> healthData,
    required UserModel user,
  }) async {
    try {
      // CSV başlıkları
      final headers = [
        'Tarih',
        'Boy (cm)',
        'Kilo (kg)', 
        'BMI',
        'BMI Kategori',
        'Adım Sayısı',
        'Yağ Oranı (%)',
        'Kas Kütlesi (kg)',
        'Su Oranı (%)',
        'Notlar'
      ];

      // CSV verilerini oluştur
      final csvData = <List<dynamic>>[headers];
      
      for (final health in healthData) {
        final row = [
          DateFormat('dd/MM/yyyy').format(health.recordDate),
          health.height?.toStringAsFixed(1) ?? '',
          health.weight?.toStringAsFixed(1) ?? '',
          health.bmi?.toStringAsFixed(1) ?? '',
          _getBMICategory(health.bmi),
          health.stepCount?.toString() ?? '',
          health.bodyFat?.toStringAsFixed(1) ?? '',
          health.muscleMass?.toStringAsFixed(1) ?? '',
          health.waterPercentage?.toStringAsFixed(1) ?? '',
          health.notes ?? ''
        ];
        csvData.add(row);
      }

      // CSV string'ini oluştur
      final csvString = const ListToCsvConverter().convert(csvData);
      
      // Dosya yolu oluştur
      final directory = await getApplicationDocumentsDirectory();
      final fileName = 'saglik_verileri_${user.name ?? 'kullanici'}_${DateFormat('yyyy_MM_dd').format(DateTime.now())}.csv';
      final file = File('${directory.path}/$fileName');
      
      // Dosyayı yaz
      await file.writeAsString(csvString, encoding: utf8);
      
      // Dosyayı paylaş
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Sağlık verileriniz CSV formatında',
        subject: 'DiyetKent Sağlık Verileri',
      );
      
    } catch (e) {
      throw Exception('CSV export hatası: $e');
    }
  }

  /// PDF formatında sağlık raporunu export eder (DISABLED - PDF functionality removed)
  static Future<void> exportHealthDataToPDF({
    required List<HealthDataModel> healthData,
    required UserModel user,
    GlobalKey? chartKey,
  }) async {
    // PDF functionality removed due to dietitian panel removal
    throw UnimplementedError('PDF export functionality has been removed');
  }

  /// Widget'ı screenshot olarak yakalar
  static Future<Uint8List?> _captureWidget(GlobalKey key) async {
    try {
      final RenderRepaintBoundary boundary = 
          key.currentContext?.findRenderObject() as RenderRepaintBoundary;
      final ui.Image image = await boundary.toImage(pixelRatio: 2.0);
      final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (e) {
      print('Screenshot alma hatası: $e');
      return null;
    }
  }

  /// PDF için özet bölümü oluşturur (DISABLED - PDF functionality removed)
  static dynamic _buildSummarySection(
    List<HealthDataModel> healthData, 
    dynamic font, 
    dynamic fontBold
  ) {
    // PDF functionality removed
    return null;
  }

  /// PDF için özet item oluşturur (DISABLED - PDF functionality removed)
  static dynamic _buildSummaryItem(
    String title, 
    String value, 
    String subtitle, 
    dynamic font, 
    dynamic fontBold
  ) {
    // PDF functionality removed
    return null;
  }

  /// PDF için veri tablosu oluşturur (DISABLED - PDF functionality removed)
  static dynamic _buildDataTable(
    List<HealthDataModel> healthData, 
    dynamic font, 
    dynamic fontBold
  ) {
    // PDF functionality removed
    return null;
  }

  /// PDF tablo hücresi oluşturur (DISABLED - PDF functionality removed)
  static dynamic _buildTableCell(String text, dynamic font, bool isHeader) {
    // PDF functionality removed
    return null;
  }

  /// BMI kategorisini döndürür
  static String _getBMICategory(double? bmi) {
    if (bmi == null) return 'Bilinmiyor';
    if (bmi < 18.5) return 'Zayıf';
    if (bmi < 25) return 'Normal';
    if (bmi < 30) return 'Fazla Kilo';
    return 'Obez';
  }

  /// PDF'i yazdırma/önizleme olarak gösterir (DISABLED - PDF functionality removed)
  static Future<void> previewPDF({
    required List<HealthDataModel> healthData,
    required UserModel user,
    GlobalKey? chartKey,
  }) async {
    // PDF functionality removed due to dietitian panel removal
    throw UnimplementedError('PDF preview functionality has been removed');
  }
}