import 'package:flutter/material.dart';
import 'package:photocafe_windows/features/classic/presentation/constants/filter_constants.dart';
import 'package:photocafe_windows/core/colors/colors.dart';

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
        color: const Color(0xFF76220B),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Choose Filter',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontSize: 32,
              color: const Color(0xFFFFFBEE),
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
                        ? const Color(0xFFFFFBEE)
                        : const Color(0xFF5A1908),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(20),
                      leading: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isSelected
                              ? const Color(0xFFFFFBEE)
                              : Colors.transparent,
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFF76220B)
                                : const Color(0xFFFFFBEE),
                            width: 2,
                          ),
                        ),
                        child: isSelected
                            ? Icon(
                                Icons.check,
                                size: 16,
                                color: const Color(0xFF76220B),
                              )
                            : null,
                      ),
                      title: Text(
                        filterName,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? const Color(0xFF76220B)
                              : const Color(0xFFFFFBEE),
                        ),
                      ),
                      subtitle: Text(
                        _getFilterDescription(filterName),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontSize: 16,
                          color: isSelected
                              ? const Color(0xFF76220B).withOpacity(0.8)
                              : const Color(0xFFFFFBEE).withOpacity(0.8),
                        ),
                      ),
                      onTap: () => onFilterSelected(filterName),
                    ),
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
                backgroundColor: isApplyingFilter
                    ? const Color(0xFFFFFBEE).withOpacity(0.5)
                    : const Color(0xFFFFFBEE),
                foregroundColor: isApplyingFilter
                    ? const Color(0xFF76220B).withOpacity(0.5)
                    : const Color(0xFF76220B),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                shadowColor: Colors.transparent,
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
                            color: const Color(0xFF76220B).withOpacity(0.5),
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
