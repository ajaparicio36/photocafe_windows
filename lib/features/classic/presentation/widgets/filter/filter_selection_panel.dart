import 'package:flutter/material.dart';
import 'package:photocafe_windows/features/classic/presentation/constants/filter_constants.dart';

class FilterSelectionPanel extends StatelessWidget {
  final String? selectedFilter;
  final bool isApplyingFilter;
  final Function(String) onFilterSelected;
  final VoidCallback onApplyFilter;

  const FilterSelectionPanel({
    super.key,
    required this.selectedFilter,
    required this.isApplyingFilter,
    required this.onFilterSelected,
    required this.onApplyFilter,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Theme.of(context).colorScheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Choose Filter',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),

          // Filter options
          Expanded(
            child: ListView.separated(
              itemCount: FilterConstants.availableFilters.length,
              separatorBuilder: (context, index) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final filterName = FilterConstants.availableFilters[index];
                final isSelected = selectedFilter == filterName;

                return Container(
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.outline,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(20),
                    leading: Radio<String>(
                      value: filterName,
                      groupValue: selectedFilter,
                      onChanged: (value) {
                        if (value != null) {
                          onFilterSelected(value);
                        }
                      },
                    ),
                    title: Text(
                      filterName,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? Theme.of(context).colorScheme.primary
                            : null,
                      ),
                    ),
                    subtitle: Text(
                      _getFilterDescription(filterName),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontSize: 16,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                    onTap: () => onFilterSelected(filterName),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 32),

          // Apply button
          Container(
            width: double.infinity,
            height: 80,
            child: ElevatedButton(
              onPressed: isApplyingFilter ? null : onApplyFilter,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: isApplyingFilter
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 32,
                          height: 32,
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            color: Theme.of(context).colorScheme.onPrimary,
                          ),
                        ),
                        const SizedBox(width: 20),
                        Text(
                          'Applying Filter...',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.auto_fix_high_rounded, size: 32),
                        const SizedBox(width: 16),
                        Text(
                          selectedFilter != null
                              ? 'Apply $selectedFilter'
                              : 'Select a Filter',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  String _getFilterDescription(String filterName) {
    switch (filterName) {
      case 'No Filter':
        return 'Keep your photos as they are';
      case FilterConstants.vintageFilterName:
        return 'Add a classic vintage look with warm tones';
      default:
        return 'Apply this filter to your photos';
    }
  }
}
