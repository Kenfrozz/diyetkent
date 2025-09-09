import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/form_validators.dart';

// Form field types
enum FormFieldType {
  text,
  number,
  email,
  phone,
  date,
  dropdown,
  multiselect,
  checkbox,
  radio,
  slider,
  textarea,
  tags,
}

// Dynamic Form Configuration
class DynamicFormConfig {
  final String formId;
  final String title;
  final String? description;
  final List<DynamicFormSection> sections;
  
  const DynamicFormConfig({
    required this.formId,
    required this.title,
    this.description,
    required this.sections,
  });
  
  factory DynamicFormConfig.fromJson(Map<String, dynamic> json) {
    return DynamicFormConfig(
      formId: json['formId'],
      title: json['title'],
      description: json['description'],
      sections: (json['sections'] as List)
          .map((section) => DynamicFormSection.fromJson(section))
          .toList(),
    );
  }
}

// Dynamic Form Section
class DynamicFormSection {
  final String id;
  final String title;
  final String? description;
  final List<DynamicFormFieldConfig> fields;
  final bool isCollapsible;
  final bool isExpanded;
  final int order;
  
  const DynamicFormSection({
    required this.id,
    required this.title,
    this.description,
    required this.fields,
    this.isCollapsible = false,
    this.isExpanded = true,
    this.order = 0,
  });
  
  factory DynamicFormSection.fromJson(Map<String, dynamic> json) {
    return DynamicFormSection(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      fields: (json['fields'] as List)
          .map((field) => DynamicFormFieldConfig.fromJson(field))
          .toList(),
      isCollapsible: json['isCollapsible'] ?? false,
      isExpanded: json['isExpanded'] ?? true,
      order: json['order'] ?? 0,
    );
  }
}

// Dynamic Form Field Configuration
class DynamicFormFieldConfig {
  final String id;
  final String label;
  final FormFieldType type;
  final String? hint;
  final bool isRequired;
  final String? validationPattern;
  final String? errorMessage;
  final List<String> options;
  final dynamic defaultValue;
  final double? minValue;
  final double? maxValue;
  final int? maxLength;
  final bool isEnabled;
  final String? dependsOn;
  final List<String>? showWhenValues;
  final int order;
  
  const DynamicFormFieldConfig({
    required this.id,
    required this.label,
    required this.type,
    this.hint,
    this.isRequired = false,
    this.validationPattern,
    this.errorMessage,
    this.options = const [],
    this.defaultValue,
    this.minValue,
    this.maxValue,
    this.maxLength,
    this.isEnabled = true,
    this.dependsOn,
    this.showWhenValues,
    this.order = 0,
  });
  
  factory DynamicFormFieldConfig.fromJson(Map<String, dynamic> json) {
    return DynamicFormFieldConfig(
      id: json['id'],
      label: json['label'],
      type: FormFieldType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => FormFieldType.text,
      ),
      hint: json['hint'],
      isRequired: json['isRequired'] ?? false,
      validationPattern: json['validationPattern'],
      errorMessage: json['errorMessage'],
      options: List<String>.from(json['options'] ?? []),
      defaultValue: json['defaultValue'],
      minValue: json['minValue']?.toDouble(),
      maxValue: json['maxValue']?.toDouble(),
      maxLength: json['maxLength'],
      isEnabled: json['isEnabled'] ?? true,
      dependsOn: json['dependsOn'],
      showWhenValues: json['showWhenValues'] != null 
          ? List<String>.from(json['showWhenValues'])
          : null,
      order: json['order'] ?? 0,
    );
  }
}

// Dynamic Form Builder Widget
class DynamicFormBuilder extends StatefulWidget {
  final DynamicFormConfig config;
  final Map<String, dynamic> initialValues;
  final void Function(String fieldId, dynamic value)? onFieldChanged;
  final void Function(Map<String, dynamic> values)? onFormChanged;
  final bool readOnly;
  
  const DynamicFormBuilder({
    super.key,
    required this.config,
    this.initialValues = const {},
    this.onFieldChanged,
    this.onFormChanged,
    this.readOnly = false,
  });

  @override
  State<DynamicFormBuilder> createState() => _DynamicFormBuilderState();
}

class _DynamicFormBuilderState extends State<DynamicFormBuilder> {
  final Map<String, dynamic> _values = {};
  final Map<String, GlobalKey<FormState>> _sectionKeys = {};
  
  @override
  void initState() {
    super.initState();
    _initializeValues();
    _initializeSectionKeys();
  }
  
  void _initializeValues() {
    _values.addAll(widget.initialValues);
    
    // Set default values for fields that don't have values
    for (final section in widget.config.sections) {
      for (final field in section.fields) {
        if (!_values.containsKey(field.id) && field.defaultValue != null) {
          _values[field.id] = field.defaultValue;
        }
      }
    }
  }
  
  void _initializeSectionKeys() {
    for (final section in widget.config.sections) {
      _sectionKeys[section.id] = GlobalKey<FormState>();
    }
  }
  
  void _handleFieldChanged(String fieldId, dynamic value) {
    setState(() {
      _values[fieldId] = value;
    });
    
    widget.onFieldChanged?.call(fieldId, value);
    widget.onFormChanged?.call(Map.from(_values));
  }
  
  bool _shouldShowField(DynamicFormFieldConfig field) {
    if (field.dependsOn == null || field.showWhenValues == null) {
      return true;
    }
    
    final dependentValue = _values[field.dependsOn];
    return field.showWhenValues!.contains(dependentValue?.toString());
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Form header
        if (widget.config.title.isNotEmpty) ...[
          Text(
            widget.config.title,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
        ],
        
        if (widget.config.description?.isNotEmpty == true) ...[
          Text(
            widget.config.description!,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 16),
        ],
        
        // Form sections
        ...widget.config.sections
            .where((section) => section.fields.any(_shouldShowField))
            .map((section) => _buildSection(section)),
      ],
    );
  }
  
  Widget _buildSection(DynamicFormSection section) {
    final sectionKey = _sectionKeys[section.id]!;
    final visibleFields = section.fields.where(_shouldShowField).toList();
    
    if (visibleFields.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Form(
        key: sectionKey,
        child: section.isCollapsible
            ? ExpansionTile(
                title: Text(
                  section.title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                subtitle: section.description != null
                    ? Text(section.description!)
                    : null,
                initiallyExpanded: section.isExpanded,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: visibleFields
                          .map((field) => _buildField(field))
                          .toList(),
                    ),
                  ),
                ],
              )
            : Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      section.title,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    if (section.description != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        section.description!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    ...visibleFields
                        .map((field) => _buildField(field)),
                  ],
                ),
              ),
      ),
    );
  }
  
  Widget _buildField(DynamicFormFieldConfig field) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: _buildFieldWidget(field),
    );
  }
  
  Widget _buildFieldWidget(DynamicFormFieldConfig field) {
    if (!field.isEnabled && !widget.readOnly) {
      return const SizedBox.shrink();
    }
    
    switch (field.type) {
      case FormFieldType.text:
        return _buildTextField(field);
      case FormFieldType.number:
        return _buildNumberField(field);
      case FormFieldType.email:
        return _buildEmailField(field);
      case FormFieldType.phone:
        return _buildPhoneField(field);
      case FormFieldType.textarea:
        return _buildTextAreaField(field);
      case FormFieldType.dropdown:
        return _buildDropdownField(field);
      case FormFieldType.multiselect:
        return _buildMultiSelectField(field);
      case FormFieldType.checkbox:
        return _buildCheckboxField(field);
      case FormFieldType.radio:
        return _buildRadioField(field);
      case FormFieldType.slider:
        return _buildSliderField(field);
      case FormFieldType.date:
        return _buildDateField(field);
      case FormFieldType.tags:
        return _buildTagsField(field);
    }
  }
  
  Widget _buildTextField(DynamicFormFieldConfig field) {
    return TextFormField(
      initialValue: _values[field.id]?.toString(),
      decoration: InputDecoration(
        labelText: field.label,
        hintText: field.hint,
        border: const OutlineInputBorder(),
      ),
      maxLength: field.maxLength,
      readOnly: widget.readOnly,
      validator: (value) => _validateField(field, value),
      onChanged: (value) => _handleFieldChanged(field.id, value),
    );
  }
  
  Widget _buildNumberField(DynamicFormFieldConfig field) {
    return TextFormField(
      initialValue: _values[field.id]?.toString(),
      decoration: InputDecoration(
        labelText: field.label,
        hintText: field.hint,
        border: const OutlineInputBorder(),
      ),
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))],
      readOnly: widget.readOnly,
      validator: (value) => _validateField(field, value),
      onChanged: (value) {
        final numValue = double.tryParse(value);
        _handleFieldChanged(field.id, numValue);
      },
    );
  }
  
  Widget _buildEmailField(DynamicFormFieldConfig field) {
    return TextFormField(
      initialValue: _values[field.id]?.toString(),
      decoration: InputDecoration(
        labelText: field.label,
        hintText: field.hint,
        border: const OutlineInputBorder(),
      ),
      keyboardType: TextInputType.emailAddress,
      readOnly: widget.readOnly,
      validator: (value) => FlutterFormValidators.email(value),
      onChanged: (value) => _handleFieldChanged(field.id, value),
    );
  }
  
  Widget _buildPhoneField(DynamicFormFieldConfig field) {
    return TextFormField(
      initialValue: _values[field.id]?.toString(),
      decoration: InputDecoration(
        labelText: field.label,
        hintText: field.hint,
        border: const OutlineInputBorder(),
      ),
      keyboardType: TextInputType.phone,
      readOnly: widget.readOnly,
      validator: (value) => FlutterFormValidators.phone(value),
      onChanged: (value) => _handleFieldChanged(field.id, value),
    );
  }
  
  Widget _buildTextAreaField(DynamicFormFieldConfig field) {
    return TextFormField(
      initialValue: _values[field.id]?.toString(),
      decoration: InputDecoration(
        labelText: field.label,
        hintText: field.hint,
        border: const OutlineInputBorder(),
      ),
      maxLines: 4,
      maxLength: field.maxLength,
      readOnly: widget.readOnly,
      validator: (value) => _validateField(field, value),
      onChanged: (value) => _handleFieldChanged(field.id, value),
    );
  }
  
  Widget _buildDropdownField(DynamicFormFieldConfig field) {
    return DropdownButtonFormField<String>(
      value: _values[field.id]?.toString(),
      decoration: InputDecoration(
        labelText: field.label,
        hintText: field.hint,
        border: const OutlineInputBorder(),
      ),
      items: field.options.map((option) {
        return DropdownMenuItem<String>(
          value: option,
          child: Text(option),
        );
      }).toList(),
      validator: (value) => _validateField(field, value),
      onChanged: widget.readOnly ? null : (value) => _handleFieldChanged(field.id, value),
    );
  }
  
  Widget _buildMultiSelectField(DynamicFormFieldConfig field) {
    final selectedItems = _values[field.id] as List<String>? ?? [];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          field.label,
          style: Theme.of(context).textTheme.labelLarge,
        ),
        if (field.hint != null) ...[
          const SizedBox(height: 4),
          Text(
            field.hint!,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey[600],
            ),
          ),
        ],
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: field.options.map((option) {
            final isSelected = selectedItems.contains(option);
            return FilterChip(
              label: Text(option),
              selected: isSelected,
              onSelected: widget.readOnly ? null : (selected) {
                List<String> newList = List.from(selectedItems);
                if (selected) {
                  newList.add(option);
                } else {
                  newList.remove(option);
                }
                _handleFieldChanged(field.id, newList);
              },
            );
          }).toList(),
        ),
      ],
    );
  }
  
  Widget _buildCheckboxField(DynamicFormFieldConfig field) {
    return CheckboxListTile(
      title: Text(field.label),
      subtitle: field.hint != null ? Text(field.hint!) : null,
      value: _values[field.id] as bool? ?? false,
      onChanged: widget.readOnly ? null : (value) => _handleFieldChanged(field.id, value),
      controlAffinity: ListTileControlAffinity.leading,
    );
  }
  
  Widget _buildRadioField(DynamicFormFieldConfig field) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          field.label,
          style: Theme.of(context).textTheme.labelLarge,
        ),
        if (field.hint != null) ...[
          const SizedBox(height: 4),
          Text(
            field.hint!,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey[600],
            ),
          ),
        ],
        const SizedBox(height: 8),
        ...field.options.map((option) {
          return RadioListTile<String>(
            title: Text(option),
            value: option,
            groupValue: _values[field.id]?.toString(),
            onChanged: widget.readOnly ? null : (value) => _handleFieldChanged(field.id, value),
            dense: true,
          );
        }),
      ],
    );
  }
  
  Widget _buildSliderField(DynamicFormFieldConfig field) {
    final value = (_values[field.id] as double?) ?? (field.minValue ?? 0.0);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              field.label,
              style: Theme.of(context).textTheme.labelLarge,
            ),
            Text(
              value.toStringAsFixed(1),
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        if (field.hint != null) ...[
          const SizedBox(height: 4),
          Text(
            field.hint!,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey[600],
            ),
          ),
        ],
        Slider(
          value: value,
          min: field.minValue ?? 0.0,
          max: field.maxValue ?? 100.0,
          divisions: ((field.maxValue ?? 100.0) - (field.minValue ?? 0.0)).toInt(),
          onChanged: widget.readOnly ? null : (newValue) => _handleFieldChanged(field.id, newValue),
        ),
      ],
    );
  }
  
  Widget _buildDateField(DynamicFormFieldConfig field) {
    final value = _values[field.id] as DateTime?;
    
    return TextFormField(
      controller: TextEditingController(
        text: value != null 
            ? '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}'
            : '',
      ),
      decoration: InputDecoration(
        labelText: field.label,
        hintText: field.hint ?? 'GG/AA/YYYY',
        border: const OutlineInputBorder(),
        suffixIcon: const Icon(Icons.calendar_today),
      ),
      readOnly: true,
      validator: (value) => _validateField(field, value),
      onTap: widget.readOnly ? null : () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: value ?? DateTime.now(),
          firstDate: DateTime(1900),
          lastDate: DateTime(2100),
        );
        if (picked != null) {
          _handleFieldChanged(field.id, picked);
        }
      },
    );
  }
  
  Widget _buildTagsField(DynamicFormFieldConfig field) {
    final selectedTags = _values[field.id] as List<String>? ?? [];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          field.label,
          style: Theme.of(context).textTheme.labelLarge,
        ),
        if (field.hint != null) ...[
          const SizedBox(height: 4),
          Text(
            field.hint!,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey[600],
            ),
          ),
        ],
        const SizedBox(height: 8),
        if (selectedTags.isNotEmpty) ...[
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: selectedTags.map((tag) {
              return Chip(
                label: Text(tag),
                deleteIcon: const Icon(Icons.close, size: 18),
                onDeleted: widget.readOnly ? null : () {
                  final newList = List<String>.from(selectedTags);
                  newList.remove(tag);
                  _handleFieldChanged(field.id, newList);
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
        ],
        if (!widget.readOnly) ...[
          TextFormField(
            decoration: const InputDecoration(
              hintText: 'Etiket eklemek için yazın ve Enter\'a basın',
              border: OutlineInputBorder(),
              suffixIcon: Icon(Icons.add),
            ),
            onFieldSubmitted: (value) {
              if (value.trim().isNotEmpty && !selectedTags.contains(value.trim())) {
                final newList = List<String>.from(selectedTags);
                newList.add(value.trim());
                _handleFieldChanged(field.id, newList);
              }
            },
          ),
        ],
      ],
    );
  }
  
  String? _validateField(DynamicFormFieldConfig field, String? value) {
    if (field.isRequired && (value == null || value.trim().isEmpty)) {
      return field.errorMessage ?? '${field.label} gereklidir';
    }
    
    if (field.validationPattern != null && value != null && value.isNotEmpty) {
      final regex = RegExp(field.validationPattern!);
      if (!regex.hasMatch(value)) {
        return field.errorMessage ?? 'Geçersiz format';
      }
    }
    
    return null;
  }
  
  // Public methods for form validation and data access
  bool validateForm() {
    bool isValid = true;
    for (final key in _sectionKeys.values) {
      if (key.currentState?.validate() != true) {
        isValid = false;
      }
    }
    return isValid;
  }
  
  Map<String, dynamic> getFormData() {
    return Map.from(_values);
  }
  
  void setFormData(Map<String, dynamic> data) {
    setState(() {
      _values.clear();
      _values.addAll(data);
    });
  }
  
  void resetForm() {
    setState(() {
      _values.clear();
      _initializeValues();
    });
  }
}