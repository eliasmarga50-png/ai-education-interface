import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/models/course.dart';
import '../../../shared/widgets/app_empty_state.dart';
import '../../../shared/widgets/app_spacing.dart';
import '../../../shared/widgets/pressable_scale.dart';
import '../../../shared/widgets/responsive_layout.dart';
import '../data/course_data.dart';
import 'course_details_screen.dart';

class CoursesScreen extends StatefulWidget {
  const CoursesScreen({super.key});

  @override
  State<CoursesScreen> createState() => _CoursesScreenState();
}

class _CoursesScreenState extends State<CoursesScreen> {
  String _selectedCategory = 'All';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  final List<String> _categories = const [
    'All',
    'Programming',
    'Design',
    'AI',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Course> get _filteredCourses {
    return CourseData.courses.where((course) {
      final matchesCategory = _selectedCategory == 'All' ||
          course.category.toLowerCase() == _selectedCategory.toLowerCase();
      final matchesSearch = _searchQuery.isEmpty ||
          course.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          course.description.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          course.category.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesCategory && matchesSearch;
    }).toList();
  }

  void _selectCategory(String category) {
    if (_selectedCategory != category) {
      HapticFeedback.selectionClick();
      setState(() {
        _selectedCategory = category;
      });
    }
  }

  void _resetFilters() {
    HapticFeedback.lightImpact();
    setState(() {
      _selectedCategory = 'All';
      _searchQuery = '';
      _searchController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredCourses;
    final isWide = !ResponsiveBreakpoints.isMobile(context);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Courses',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            Text(
              'Learn something new today',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppSpacing.maxContentWidth),
          child: ListView(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            padding: isWide ? AppSpacing.pagePaddingTablet : AppSpacing.pagePaddingMobile,
            children: [
              _SearchField(
                controller: _searchController,
                query: _searchQuery,
                onChanged: (val) {
                  setState(() {
                    _searchQuery = val.trim();
                  });
                },
                onClear: () {
                  _searchController.clear();
                  setState(() {
                    _searchQuery = '';
                  });
                },
              ),
              const SizedBox(height: 24),
              const _SectionTitle(title: 'Categories'),
              const SizedBox(height: 12),
              _CategoryList(
                categories: _categories,
                selectedCategory: _selectedCategory,
                onCategorySelected: _selectCategory,
              ),
              const SizedBox(height: 28),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const _SectionTitle(title: 'Popular Courses'),
                  Text(
                    '${filtered.length} courses',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              const SizedBox(height: 14),

              if (filtered.isEmpty)
                AppEmptyState(
                  icon: Icons.search_off_rounded,
                  title: 'No courses found',
                  message: _searchQuery.isNotEmpty
                      ? 'No courses match "$_searchQuery". Try searching for another topic or resetting filters.'
                      : 'No courses found in category "$_selectedCategory".',
                  actionLabel: 'Reset filters',
                  onAction: _resetFilters,
                )
              else if (isWide)
                LayoutBuilder(
                  builder: (context, constraints) {
                    final crossAxisCount = constraints.maxWidth > 800 ? 3 : 2;
                    return GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        mainAxisExtent: 110,
                      ),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        return CourseCard(course: filtered[index]);
                      },
                    );
                  },
                )
              else
                ...filtered.map(
                  (course) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: CourseCard(course: course),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  final String query;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  const _SearchField({
    required this.controller,
    required this.query,
    required this.onChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: 'Search courses by name or topic...',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: query.isNotEmpty
            ? IconButton(
                tooltip: 'Clear search',
                icon: const Icon(Icons.clear, size: 20),
                onPressed: onClear,
              )
            : const Icon(Icons.tune_outlined, size: 20),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge,
    );
  }
}

class _CategoryList extends StatelessWidget {
  final List<String> categories;
  final String selectedCategory;
  final ValueChanged<String> onCategorySelected;

  const _CategoryList({
    required this.categories,
    required this.selectedCategory,
    required this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: categories.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = category == selectedCategory;

          return ChoiceChip(
            label: Text(category),
            selected: isSelected,
            onSelected: (_) {
              onCategorySelected(category);
            },
          );
        },
      ),
    );
  }
}

class CourseCard extends StatelessWidget {
  final Course course;

  const CourseCard({
    super.key,
    required this.course,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '${course.title}, ${course.category}, ${course.level}, ${course.lessons} lessons, rating ${course.rating}',
      child: PressableScale(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CourseDetailsScreen(
                course: course,
              ),
            ),
          );
        },
        child: Card(
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CourseDetailsScreen(
                    course: course,
                  ),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  _CourseThumbnail(
                    category: course.category,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _CourseInformation(
                      course: course,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.chevron_right,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CourseThumbnail extends StatelessWidget {
  final String category;

  const _CourseThumbnail({
    required this.category,
  });

  IconData get _icon {
    switch (category) {
      case 'Programming':
        return Icons.code_rounded;
      case 'Design':
        return Icons.palette_outlined;
      case 'AI':
        return Icons.smart_toy_outlined;
      default:
        return Icons.school_outlined;
    }
  }

  Color get _color {
    switch (category) {
      case 'Programming':
        return const Color(0xFF0284C7);
      case 'Design':
        return const Color(0xFFEC4899);
      case 'AI':
        return const Color(0xFF8B5CF6);
      default:
        return AppTheme.primaryColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(
        _icon,
        size: 32,
        color: _color,
      ),
    );
  }
}

class _CourseInformation extends StatelessWidget {
  final Course course;

  const _CourseInformation({
    required this.course,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          course.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 4),
        Text(
          '${course.level} • ${course.lessons} lessons',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            const Icon(
              Icons.star_rounded,
              size: 17,
              color: Color(0xFFF59E0B),
            ),
            const SizedBox(width: 4),
            Text(
              course.rating.toString(),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ],
    );
  }
}