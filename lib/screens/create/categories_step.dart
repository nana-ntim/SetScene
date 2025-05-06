// File location: lib/screens/create/categories_step.dart

import 'package:flutter/material.dart';

class CategoriesStep extends StatefulWidget {
  final List<String> selectedCategories;
  final double visualRating;
  final Function(List<String>) onCategoriesChanged;
  final Function(double) onVisualRatingChanged;

  const CategoriesStep({
    super.key,
    required this.selectedCategories,
    required this.visualRating,
    required this.onCategoriesChanged,
    required this.onVisualRatingChanged,
  });

  @override
  _CategoriesStepState createState() => _CategoriesStepState();
}

class _CategoriesStepState extends State<CategoriesStep> {
  final List<String> _availableCategories = [
    'Urban',
    'Nature',
    'Indoor',
    'Beach',
    'Sunset',
    'Historic',
    'Modern',
    'Abandoned',
    'Residential',
    'Industrial',
  ];

  void _toggleCategory(String category) {
    final newSelectedCategories = List<String>.from(widget.selectedCategories);

    if (newSelectedCategories.contains(category)) {
      newSelectedCategories.remove(category);
    } else {
      if (newSelectedCategories.length < 3) {
        newSelectedCategories.add(category);
      }
    }

    widget.onCategoriesChanged(newSelectedCategories);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Categories
        const Text(
          'Select Categories',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Choose up to 3 categories that best describe this location',
          style: TextStyle(color: Colors.grey[400], fontSize: 14),
        ),
        const SizedBox(height: 16),

        // Category chips
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children:
              _availableCategories.map((category) {
                final bool isSelected = widget.selectedCategories.contains(
                  category,
                );

                return GestureDetector(
                  onTap: () => _toggleCategory(category),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.blue[700] : Colors.grey[850],
                      borderRadius: BorderRadius.circular(20),
                      border:
                          isSelected
                              ? null
                              : Border.all(color: Colors.grey[800]!),
                    ),
                    child: Text(
                      category,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.grey[400],
                      ),
                    ),
                  ),
                );
              }).toList(),
        ),

        if (widget.selectedCategories.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              '${widget.selectedCategories.length}/3 categories selected',
              style: TextStyle(color: Colors.grey[500], fontSize: 12),
            ),
          ),

        const SizedBox(height: 24),

        // Visual quality rating
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[800]!, width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Rate Visual Quality',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'How visually appealing is this location for filming?',
                style: TextStyle(color: Colors.grey[400], fontSize: 14),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Poor',
                    style: TextStyle(color: Colors.grey[500], fontSize: 12),
                  ),
                  Text(
                    'Excellent',
                    style: TextStyle(color: Colors.grey[500], fontSize: 12),
                  ),
                ],
              ),
              Slider(
                value: widget.visualRating,
                min: 1.0,
                max: 5.0,
                divisions: 8,
                label: widget.visualRating.toStringAsFixed(1),
                activeColor: Colors.blue,
                inactiveColor: Colors.grey[800],
                onChanged: widget.onVisualRatingChanged,
              ),
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.visibility, color: Colors.blue, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Rating: ${widget.visualRating.toStringAsFixed(1)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Submit note
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline, color: Colors.blue, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Your location will be visible to the community after review.',
                  style: TextStyle(color: Colors.grey[300], fontSize: 14),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
