import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/pre_consultation_form_provider.dart';
import 'pre_consultation_form_page_provider.dart';

/// Wrapper widget that provides the PreConsultationFormProvider and displays the form
/// This allows the form to be used with Provider state management while maintaining
/// a clean separation of concerns.
class PreConsultationFormWrapper extends StatelessWidget {
  final String? formId;
  final String userId;
  final String? dietitianId;

  const PreConsultationFormWrapper({
    Key? key,
    this.formId,
    required this.userId,
    this.dietitianId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => PreConsultationFormProvider(),
      child: PreConsultationFormPageProvider(
        formId: formId,
        userId: userId,
        dietitianId: dietitianId,
      ),
    );
  }
}