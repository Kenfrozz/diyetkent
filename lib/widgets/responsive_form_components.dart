import 'package:flutter/material.dart';
import '../theme/pre_consultation_form_theme.dart';

/// Responsive form section card that adapts to screen size
class ResponsiveFormSection extends StatelessWidget {
  final String title;
  final List<Widget> children;
  final IconData? icon;
  final String? subtitle;
  final bool isRequired;
  
  const ResponsiveFormSection({
    super.key,
    required this.title,
    required this.children,
    this.icon,
    this.subtitle,
    this.isRequired = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: PreConsultationFormTheme.spacingM),
      child: Card(
        elevation: PreConsultationFormTheme.elevationS,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(PreConsultationFormTheme.radiusM),
        ),
        child: Padding(
          padding: PreConsultationFormTheme.responsivePadding(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader(context),
              const SizedBox(height: PreConsultationFormTheme.spacingM),
              ...children,
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildSectionHeader(BuildContext context) {
    return Row(
      children: [
        if (icon != null) ...[
          Container(
            padding: const EdgeInsets.all(PreConsultationFormTheme.spacingS),
            decoration: BoxDecoration(
              color: PreConsultationFormTheme.primaryTeal.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(PreConsultationFormTheme.radiusS),
            ),
            child: Icon(
              icon,
              color: PreConsultationFormTheme.primaryTeal,
              size: PreConsultationFormTheme.isMobile(context) ? 20 : 24,
            ),
          ),
          const SizedBox(width: PreConsultationFormTheme.spacingM),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: PreConsultationFormTheme.isMobile(context)
                          ? PreConsultationFormTheme.headingSmall
                          : PreConsultationFormTheme.headingMedium,
                    ),
                  ),
                  if (isRequired)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: PreConsultationFormTheme.spacingS,
                        vertical: PreConsultationFormTheme.spacingXS,
                      ),
                      decoration: BoxDecoration(
                        color: PreConsultationFormTheme.errorColor,
                        borderRadius: BorderRadius.circular(PreConsultationFormTheme.radiusS),
                      ),
                      child: Text(
                        'Gerekli',
                        style: PreConsultationFormTheme.caption.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
              if (subtitle != null) ...[
                const SizedBox(height: PreConsultationFormTheme.spacingXS),
                Text(
                  subtitle!,
                  style: PreConsultationFormTheme.bodySmall,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// Responsive form field row that stacks on mobile
class ResponsiveFormRow extends StatelessWidget {
  final List<Widget> children;
  final double spacing;
  
  const ResponsiveFormRow({
    super.key,
    required this.children,
    this.spacing = PreConsultationFormTheme.spacingM,
  });

  @override
  Widget build(BuildContext context) {
    if (PreConsultationFormTheme.isMobile(context)) {
      // Stack vertically on mobile
      return Column(
        children: children
            .expand((child) => [child, SizedBox(height: spacing)])
            .toList()
          ..removeLast(), // Remove last spacer
      );
    } else {
      // Display horizontally on tablet/desktop
      return Row(
        children: children
            .expand((child) => [Expanded(child: child), SizedBox(width: spacing)])
            .toList()
          ..removeLast(), // Remove last spacer
      );
    }
  }
}

/// Responsive slider with adaptive layout
class ResponsiveSliderTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final double value;
  final double min;
  final double max;
  final int? divisions;
  final ValueChanged<double> onChanged;
  final String Function(double)? valueFormatter;
  
  const ResponsiveSliderTile({
    super.key,
    required this.title,
    this.subtitle,
    required this.value,
    required this.min,
    required this.max,
    this.divisions,
    required this.onChanged,
    this.valueFormatter,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(context),
        const SizedBox(height: PreConsultationFormTheme.spacingS),
        _buildSlider(context),
        const SizedBox(height: PreConsultationFormTheme.spacingS),
        _buildValueChip(),
        const SizedBox(height: PreConsultationFormTheme.spacingM),
      ],
    );
  }
  
  Widget _buildHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: PreConsultationFormTheme.isMobile(context)
              ? PreConsultationFormTheme.bodyMedium.copyWith(fontWeight: FontWeight.w600)
              : PreConsultationFormTheme.bodyLarge.copyWith(fontWeight: FontWeight.w600),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: PreConsultationFormTheme.spacingXS),
          Text(
            subtitle!,
            style: PreConsultationFormTheme.bodySmall,
          ),
        ],
      ],
    );
  }
  
  Widget _buildSlider(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: PreConsultationFormTheme.spacingS,
            vertical: PreConsultationFormTheme.spacingXS,
          ),
          decoration: BoxDecoration(
            color: PreConsultationFormTheme.primaryTeal.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(PreConsultationFormTheme.radiusS),
          ),
          child: Text(
            min.round().toString(),
            style: PreConsultationFormTheme.bodySmall.copyWith(
              fontWeight: FontWeight.w600,
              color: PreConsultationFormTheme.primaryTeal,
            ),
          ),
        ),
        Expanded(
          child: Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            divisions: divisions,
            onChanged: onChanged,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: PreConsultationFormTheme.spacingS,
            vertical: PreConsultationFormTheme.spacingXS,
          ),
          decoration: BoxDecoration(
            color: PreConsultationFormTheme.primaryTeal.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(PreConsultationFormTheme.radiusS),
          ),
          child: Text(
            max.round().toString(),
            style: PreConsultationFormTheme.bodySmall.copyWith(
              fontWeight: FontWeight.w600,
              color: PreConsultationFormTheme.primaryTeal,
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildValueChip() {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: PreConsultationFormTheme.spacingM,
          vertical: PreConsultationFormTheme.spacingS,
        ),
        decoration: BoxDecoration(
          color: PreConsultationFormTheme.primaryTeal,
          borderRadius: BorderRadius.circular(PreConsultationFormTheme.radiusL),
          boxShadow: [
            BoxShadow(
              color: PreConsultationFormTheme.primaryTeal.withValues(alpha: 0.3),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          valueFormatter?.call(value) ?? '${value.round()}',
          style: PreConsultationFormTheme.bodyMedium.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

/// Responsive radio group that adapts layout based on screen size
class ResponsiveRadioGroup<T> extends StatelessWidget {
  final String title;
  final String? subtitle;
  final T? value;
  final List<T> options;
  final List<String> labels;
  final ValueChanged<T?> onChanged;
  final bool isRequired;
  
  const ResponsiveRadioGroup({
    super.key,
    required this.title,
    this.subtitle,
    required this.value,
    required this.options,
    required this.labels,
    required this.onChanged,
    this.isRequired = false,
  });

  @override
  Widget build(BuildContext context) {
    assert(options.length == labels.length, 'Options and labels must have the same length');
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(context),
        const SizedBox(height: PreConsultationFormTheme.spacingS),
        if (PreConsultationFormTheme.isMobile(context))
          _buildVerticalLayout(context)
        else
          _buildHorizontalLayout(context),
      ],
    );
  }
  
  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: PreConsultationFormTheme.isMobile(context)
                    ? PreConsultationFormTheme.bodyMedium.copyWith(fontWeight: FontWeight.w600)
                    : PreConsultationFormTheme.bodyLarge.copyWith(fontWeight: FontWeight.w600),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: PreConsultationFormTheme.spacingXS),
                Text(
                  subtitle!,
                  style: PreConsultationFormTheme.bodySmall,
                ),
              ],
            ],
          ),
        ),
        if (isRequired)
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: PreConsultationFormTheme.spacingS,
              vertical: PreConsultationFormTheme.spacingXS,
            ),
            decoration: BoxDecoration(
              color: PreConsultationFormTheme.errorColor,
              borderRadius: BorderRadius.circular(PreConsultationFormTheme.radiusS),
            ),
            child: Text(
              '*',
              style: PreConsultationFormTheme.caption.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
      ],
    );
  }
  
  Widget _buildVerticalLayout(BuildContext context) {
    return Column(
      children: options.asMap().entries.map((entry) {
        final index = entry.key;
        final option = entry.value;
        final label = labels[index];
        
        return RadioListTile<T>(
          title: Text(label),
          value: option,
          groupValue: value,
          activeColor: PreConsultationFormTheme.primaryTeal,
          onChanged: onChanged,
          contentPadding: EdgeInsets.zero,
        );
      }).toList(),
    );
  }
  
  Widget _buildHorizontalLayout(BuildContext context) {
    return Wrap(
      spacing: PreConsultationFormTheme.spacingM,
      runSpacing: PreConsultationFormTheme.spacingS,
      children: options.asMap().entries.map((entry) {
        final index = entry.key;
        final option = entry.value;
        final label = labels[index];
        
        return InkWell(
          onTap: () => onChanged(option),
          borderRadius: BorderRadius.circular(PreConsultationFormTheme.radiusS),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: PreConsultationFormTheme.spacingM,
              vertical: PreConsultationFormTheme.spacingS,
            ),
            decoration: BoxDecoration(
              color: value == option 
                  ? PreConsultationFormTheme.primaryTeal
                  : PreConsultationFormTheme.primaryTeal.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(PreConsultationFormTheme.radiusS),
              border: Border.all(
                color: value == option 
                    ? PreConsultationFormTheme.primaryTeal
                    : PreConsultationFormTheme.primaryTeal.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  value == option ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                  color: value == option 
                      ? Colors.white
                      : PreConsultationFormTheme.primaryTeal,
                  size: 18,
                ),
                const SizedBox(width: PreConsultationFormTheme.spacingS),
                Text(
                  label,
                  style: PreConsultationFormTheme.bodyMedium.copyWith(
                    color: value == option 
                        ? Colors.white
                        : PreConsultationFormTheme.primaryTeal,
                    fontWeight: value == option ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

/// Responsive progress indicator with step visualization
class ResponsiveProgressHeader extends StatelessWidget {
  final int currentStep;
  final List<String> stepTitles;
  final List<String> stepDescriptions;
  final double completionPercentage;
  final Widget? extraInfo;
  
  const ResponsiveProgressHeader({
    super.key,
    required this.currentStep,
    required this.stepTitles,
    required this.stepDescriptions,
    required this.completionPercentage,
    this.extraInfo,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: PreConsultationFormTheme.progressHeaderDecoration,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: PreConsultationFormTheme.responsivePadding(context),
          child: Column(
            children: [
              _buildStepInfo(context),
              const SizedBox(height: PreConsultationFormTheme.spacingM),
              _buildProgressIndicator(context),
              if (extraInfo != null) ...[
                const SizedBox(height: PreConsultationFormTheme.spacingM),
                extraInfo!,
              ],
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildStepInfo(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                stepTitles[currentStep],
                style: PreConsultationFormTheme.isMobile(context)
                    ? PreConsultationFormTheme.headingMedium.copyWith(color: Colors.white)
                    : PreConsultationFormTheme.headingLarge.copyWith(color: Colors.white),
              ),
              const SizedBox(height: PreConsultationFormTheme.spacingXS),
              Text(
                stepDescriptions[currentStep],
                style: PreConsultationFormTheme.bodyMedium.copyWith(
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: PreConsultationFormTheme.spacingM),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              'Adım ${currentStep + 1}/${stepTitles.length}',
              style: PreConsultationFormTheme.caption.copyWith(color: Colors.white70),
            ),
            const SizedBox(height: PreConsultationFormTheme.spacingXS),
            Text(
              '${(completionPercentage * 100).round()}% Tamamlandı',
              style: PreConsultationFormTheme.bodySmall.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }
  
  Widget _buildProgressIndicator(BuildContext context) {
    return Column(
      children: [
        LinearProgressIndicator(
          value: completionPercentage,
          backgroundColor: Colors.white24,
          valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
          minHeight: PreConsultationFormTheme.isMobile(context) ? 6 : 8,
        ),
        if (!PreConsultationFormTheme.isMobile(context)) ...[
          const SizedBox(height: PreConsultationFormTheme.spacingS),
          _buildStepIndicators(context),
        ],
      ],
    );
  }
  
  Widget _buildStepIndicators(BuildContext context) {
    return Row(
      children: List.generate(stepTitles.length, (index) {
        final isActive = index == currentStep;
        final isCompleted = index < currentStep;
        
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(
              right: index < stepTitles.length - 1 ? PreConsultationFormTheme.spacingXS : 0,
            ),
            child: Column(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: isCompleted 
                        ? Colors.white 
                        : isActive 
                            ? Colors.white
                            : Colors.white30,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: isCompleted
                        ? const Icon(
                            Icons.check,
                            size: 16,
                            color: PreConsultationFormTheme.primaryTeal,
                          )
                        : Text(
                            '${index + 1}',
                            style: TextStyle(
                              color: isActive 
                                  ? PreConsultationFormTheme.primaryTeal
                                  : Colors.white70,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: PreConsultationFormTheme.spacingXS),
                Text(
                  stepTitles[index],
                  style: PreConsultationFormTheme.caption.copyWith(
                    color: isActive ? Colors.white : Colors.white60,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}