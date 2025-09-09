import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
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

  /// PDF formatında sağlık raporunu export eder
  static Future<void> exportHealthDataToPDF({
    required List<HealthDataModel> healthData,
    required UserModel user,
    GlobalKey? chartKey,
  }) async {
    try {
      final pdf = pw.Document();
      
      // Font yükleme
      final font = await PdfGoogleFonts.notoSansRegular();
      final fontBold = await PdfGoogleFonts.notoSansBold();
      
      
      // Chart screenshot'ı al
      Uint8List? chartImage;
      if (chartKey != null) {
        chartImage = await _captureWidget(chartKey);
      }
      
      // PDF sayfası oluştur
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (pw.Context context) {
            return [
              // Başlık
              pw.Header(
                level: 0,
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'SAĞLIK RAPORU',
                          style: pw.TextStyle(
                            font: fontBold,
                            fontSize: 24,
                            color: PdfColors.teal,
                          ),
                        ),
                        pw.Text(
                          appName,
                          style: pw.TextStyle(font: font, fontSize: 14),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              pw.SizedBox(height: 20),
              
              // Kullanıcı bilgileri
              pw.Container(
                padding: const pw.EdgeInsets.all(16),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300),
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Kişi Bilgileri',
                      style: pw.TextStyle(font: fontBold, fontSize: 16),
                    ),
                    pw.SizedBox(height: 8),
                    pw.Row(
                      children: [
                        pw.Expanded(
                          child: pw.Text('Ad Soyad: ${user.name ?? 'Belirtilmemiş'}',
                              style: pw.TextStyle(font: font)),
                        ),
                        pw.Expanded(
                          child: pw.Text('Telefon: ${user.phoneNumber ?? 'Belirtilmemiş'}',
                              style: pw.TextStyle(font: font)),
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 4),
                    pw.Row(
                      children: [
                        pw.Expanded(
                          child: pw.Text('Mevcut Boy: ${user.currentHeight?.toStringAsFixed(1) ?? 'N/A'} cm',
                              style: pw.TextStyle(font: font)),
                        ),
                        pw.Expanded(
                          child: pw.Text('Mevcut Kilo: ${user.currentWeight?.toStringAsFixed(1) ?? 'N/A'} kg',
                              style: pw.TextStyle(font: font)),
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text('Hedef Kilo: Belirtilmemiş',
                        style: pw.TextStyle(font: font)),
                  ],
                ),
              ),
              
              pw.SizedBox(height: 20),
              
              // Özet istatistikler
              _buildSummarySection(healthData, font, fontBold),
              
              pw.SizedBox(height: 20),
              
              // Grafik (varsa)
              if (chartImage != null) ...[
                pw.Text(
                  'Sağlık Trend Grafiği',
                  style: pw.TextStyle(font: fontBold, fontSize: 16),
                ),
                pw.SizedBox(height: 10),
                pw.Center(
                  child: pw.Image(
                    pw.MemoryImage(chartImage),
                    width: 400,
                    height: 200,
                  ),
                ),
                pw.SizedBox(height: 20),
              ],
              
              // Detaylı tablo
              _buildDataTable(healthData, font, fontBold),
              
              // Footer
              pw.Spacer(),
              pw.Divider(),
              pw.SizedBox(height: 10),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Oluşturulma Tarihi: ${DateFormat('dd MMMM yyyy HH:mm', 'tr_TR').format(DateTime.now())}',
                    style: pw.TextStyle(font: font, fontSize: 10, color: PdfColors.grey600),
                  ),
                  pw.Text(
                    '$appName - Kişisel Sağlık Takibi',
                    style: pw.TextStyle(font: font, fontSize: 10, color: PdfColors.grey600),
                  ),
                ],
              ),
            ];
          },
        ),
      );
      
      // PDF dosyasını kaydet ve paylaş
      final directory = await getApplicationDocumentsDirectory();
      final fileName = 'saglik_raporu_${user.name ?? 'kullanici'}_${DateFormat('yyyy_MM_dd').format(DateTime.now())}.pdf';
      final file = File('${directory.path}/$fileName');
      
      final pdfBytes = await pdf.save();
      await file.writeAsBytes(pdfBytes);
      
      // Dosyayı paylaş
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Sağlık raporunuz PDF formatında',
        subject: 'DiyetKent Sağlık Raporu',
      );
      
    } catch (e) {
      throw Exception('PDF export hatası: $e');
    }
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

  /// PDF için özet bölümü oluşturur
  static pw.Widget _buildSummarySection(
    List<HealthDataModel> healthData, 
    pw.Font font, 
    pw.Font fontBold
  ) {
    if (healthData.isEmpty) {
      return pw.Text('Veri bulunamadı', style: pw.TextStyle(font: font));
    }

    final latestData = healthData.first;
    final oldestData = healthData.last;
    
    // Değişim hesaplamaları
    final weightChange = (latestData.weight != null && oldestData.weight != null)
        ? latestData.weight! - oldestData.weight!
        : null;
    
    final bmiChange = (latestData.bmi != null && oldestData.bmi != null)
        ? latestData.bmi! - oldestData.bmi!
        : null;

    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColors.teal50,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Özet İstatistikler',
            style: pw.TextStyle(font: fontBold, fontSize: 16),
          ),
          pw.SizedBox(height: 12),
          pw.Row(
            children: [
              pw.Expanded(
                child: _buildSummaryItem(
                  'Mevcut BMI',
                  latestData.bmi?.toStringAsFixed(1) ?? 'N/A',
                  _getBMICategory(latestData.bmi),
                  font, fontBold,
                ),
              ),
              pw.Expanded(
                child: _buildSummaryItem(
                  'Mevcut Kilo',
                  '${latestData.weight?.toStringAsFixed(1) ?? 'N/A'} kg',
                  weightChange != null 
                    ? '${weightChange >= 0 ? '+' : ''}${weightChange.toStringAsFixed(1)} kg'
                    : 'N/A',
                  font, fontBold,
                ),
              ),
              pw.Expanded(
                child: _buildSummaryItem(
                  'BMI Değişimi',
                  bmiChange != null 
                    ? '${bmiChange >= 0 ? '+' : ''}${bmiChange.toStringAsFixed(1)}'
                    : 'N/A',
                  '${healthData.length} gün',
                  font, fontBold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// PDF için özet item oluşturur
  static pw.Widget _buildSummaryItem(
    String title, 
    String value, 
    String subtitle, 
    pw.Font font, 
    pw.Font fontBold
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(title, style: pw.TextStyle(font: font, fontSize: 12, color: PdfColors.grey600)),
        pw.SizedBox(height: 4),
        pw.Text(value, style: pw.TextStyle(font: fontBold, fontSize: 16)),
        pw.SizedBox(height: 2),
        pw.Text(subtitle, style: pw.TextStyle(font: font, fontSize: 10, color: PdfColors.grey500)),
      ],
    );
  }

  /// PDF için veri tablosu oluşturur
  static pw.Widget _buildDataTable(
    List<HealthDataModel> healthData, 
    pw.Font font, 
    pw.Font fontBold
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Detaylı Veri Tablosu',
          style: pw.TextStyle(font: fontBold, fontSize: 16),
        ),
        pw.SizedBox(height: 10),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey300),
          columnWidths: {
            0: const pw.FractionColumnWidth(0.15),
            1: const pw.FractionColumnWidth(0.12),
            2: const pw.FractionColumnWidth(0.12),
            3: const pw.FractionColumnWidth(0.12),
            4: const pw.FractionColumnWidth(0.15),
            5: const pw.FractionColumnWidth(0.12),
            6: const pw.FractionColumnWidth(0.22),
          },
          children: [
            // Başlık satırı
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey100),
              children: [
                _buildTableCell('Tarih', fontBold, true),
                _buildTableCell('Boy', fontBold, true),
                _buildTableCell('Kilo', fontBold, true),
                _buildTableCell('BMI', fontBold, true),
                _buildTableCell('Kategori', fontBold, true),
                _buildTableCell('Adım', fontBold, true),
                _buildTableCell('Notlar', fontBold, true),
              ],
            ),
            // Veri satırları
            ...healthData.take(20).map((health) => pw.TableRow(
              children: [
                _buildTableCell(DateFormat('dd/MM/yy').format(health.recordDate), font, false),
                _buildTableCell(health.height?.toStringAsFixed(0) ?? '-', font, false),
                _buildTableCell(health.weight?.toStringAsFixed(1) ?? '-', font, false),
                _buildTableCell(health.bmi?.toStringAsFixed(1) ?? '-', font, false),
                _buildTableCell(_getBMICategory(health.bmi), font, false),
                _buildTableCell(health.stepCount?.toString() ?? '-', font, false),
                _buildTableCell(
                  health.notes?.isNotEmpty == true 
                    ? (health.notes!.length > 30 ? '${health.notes!.substring(0, 30)}...' : health.notes!)
                    : '-', 
                  font, false
                ),
              ],
            )).toList(),
          ],
        ),
        if (healthData.length > 20)
          pw.Padding(
            padding: const pw.EdgeInsets.only(top: 8),
            child: pw.Text(
              'Not: Sadece son 20 kayıt gösterilmektedir. Tüm veriler için CSV formatını kullanın.',
              style: pw.TextStyle(font: font, fontSize: 10, color: PdfColors.grey600),
            ),
          ),
      ],
    );
  }

  /// PDF tablo hücresi oluşturur
  static pw.Widget _buildTableCell(String text, pw.Font font, bool isHeader) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          font: font,
          fontSize: isHeader ? 10 : 9,
          color: isHeader ? PdfColors.black : PdfColors.grey800,
        ),
        textAlign: isHeader ? pw.TextAlign.center : pw.TextAlign.left,
      ),
    );
  }

  /// BMI kategorisini döndürür
  static String _getBMICategory(double? bmi) {
    if (bmi == null) return 'Bilinmiyor';
    if (bmi < 18.5) return 'Zayıf';
    if (bmi < 25) return 'Normal';
    if (bmi < 30) return 'Fazla Kilo';
    return 'Obez';
  }

  /// PDF'i yazdırma/önizleme olarak gösterir
  static Future<void> previewPDF({
    required List<HealthDataModel> healthData,
    required UserModel user,
    GlobalKey? chartKey,
  }) async {
    try {
      final pdf = pw.Document();
      
      // PDF içeriğini oluştur (yukarıdaki kodu kullan)
      // ... PDF oluşturma kodu ...
      
      // Yazdırma önizlemesini göster
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
        name: 'Sağlık Raporu',
        format: PdfPageFormat.a4,
      );
      
    } catch (e) {
      throw Exception('PDF önizleme hatası: $e');
    }
  }
}