import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/glass_theme.dart';
import '../../../ai_quiz/presentation/pages/quiz_chat_page.dart';
import '../../../tasks/data/models/task_model.dart';
import '../../../tasks/presentation/bloc/task_bloc.dart';
import '../../../timer/presentation/pages/pomodoro_page.dart';

class StudentDashboardPage extends StatefulWidget {
  const StudentDashboardPage({
    required this.accessToken,
    required this.userName,
    required this.onLogout,
    super.key,
  });

  final String accessToken;
  final String userName;
  final VoidCallback onLogout;

  @override
  State<StudentDashboardPage> createState() => _StudentDashboardPageState();
}

class _StudentDashboardPageState extends State<StudentDashboardPage> {
  static const _categories = ['All', 'Homework', 'Exams', 'Projects'];
  final _tasksKey = GlobalKey();
  String _selectedCategory = 'All';
  bool _showCompletedTasks = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GlassTheme.primaryDark,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 920),
            child: BlocBuilder<TaskBloc, TaskState>(
              builder: (context, state) {
                final tasks = state is TaskLoadedState
                    ? state.tasks
                    : const <TaskModel>[];
                final filteredTasks = _selectedCategory == 'All'
                    ? tasks
                    : tasks
                          .where(
                            (task) =>
                                task.category.toLowerCase() ==
                                _selectedCategory.toLowerCase(),
                          )
                          .toList();
                final completedTaskCount = tasks
                    .where((task) => task.isCompleted)
                    .length;
                final pendingTaskCount = tasks.length - completedTaskCount;
                final pendingTasks =
                    filteredTasks.where((task) => !task.isCompleted).toList()
                      ..sort(
                        (first, second) =>
                            first.dueDate.compareTo(second.dueDate),
                      );
                final completedTasks =
                    filteredTasks.where((task) => task.isCompleted).toList()
                      ..sort(
                        (first, second) =>
                            first.dueDate.compareTo(second.dueDate),
                      );
                return CustomScrollView(
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 22),
                      sliver: SliverToBoxAdapter(
                        child: _DashboardHeader(
                          userName: widget.userName,
                          onLogout: widget.onLogout,
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      sliver: SliverToBoxAdapter(
                        child: _TaskAnalyticsBar(
                          total: tasks.length,
                          completed: completedTaskCount,
                          pending: pendingTaskCount,
                        ),
                      ),
                    ),
                    SliverPadding(
                      key: _tasksKey,
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                      sliver: SliverToBoxAdapter(
                        child: Row(
                          children: [
                            const Expanded(
                              child: Text(
                                'Your tasks',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Text(
                              '${pendingTasks.length} remaining',
                              style: const TextStyle(color: Colors.white54),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.only(bottom: 16),
                      sliver: SliverToBoxAdapter(
                        child: _CategoryFilters(
                          categories: _categories,
                          selected: _selectedCategory,
                          onSelected: (category) =>
                              setState(() => _selectedCategory = category),
                        ),
                      ),
                    ),
                    if (state is TaskLoadingState)
                      const SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(
                          child: CircularProgressIndicator(
                            color: GlassTheme.accentNeon,
                          ),
                        ),
                      )
                    else if (state is TaskErrorState)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: _TaskLoadError(message: state.message),
                      )
                    else ...[
                      if (pendingTasks.isEmpty)
                        const SliverPadding(
                          padding: EdgeInsets.fromLTRB(16, 4, 16, 12),
                          sliver: SliverToBoxAdapter(
                            child: Text(
                              'No pending tasks in this view.',
                              style: TextStyle(color: Colors.white54),
                            ),
                          ),
                        )
                      else
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 22),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) => _TaskTile(
                                task: pendingTasks[index],
                                index: index,
                              ),
                              childCount: pendingTasks.length,
                            ),
                          ),
                        ),
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                        sliver: SliverToBoxAdapter(
                          child: _CompletedTasksHeader(
                            count: completedTasks.length,
                            expanded: _showCompletedTasks,
                            onTap: () => setState(
                              () => _showCompletedTasks = !_showCompletedTasks,
                            ),
                          ),
                        ),
                      ),
                      if (_showCompletedTasks && completedTasks.isNotEmpty)
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) => _TaskTile(
                                task: completedTasks[index],
                                index: index,
                              ),
                              childCount: completedTasks.length,
                            ),
                          ),
                        ),
                    ],
                    const SliverPadding(
                        padding: EdgeInsets.fromLTRB(16, 30, 16, 14),
                        sliver: SliverToBoxAdapter(
                          child: _SectionHeading(
                            title: 'Study tools',
                            subtitle: 'Build focus and test your knowledge.',
                          ),
                        ),
                    ),
                    _FeatureGrid(
                        accessToken: widget.accessToken,
                        onTasksTap: _scrollToTasks,
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 96)),
                  ],
                );
              },
            ),
          ),
        ),
      ),
      floatingActionButton: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: FloatingActionButton.extended(
            onPressed: _showAddTaskSheet,
            backgroundColor: GlassTheme.cyanAccent.withValues(alpha: 0.82),
            foregroundColor: Colors.white,
            icon: const Icon(Icons.add),
            label: const Text('Add task'),
          ),
        ),
      ),
    );
  }

  Future<void> _scrollToTasks() async {
    final targetContext = _tasksKey.currentContext;
    if (targetContext != null) {
      await Scrollable.ensureVisible(
        targetContext,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _showAddTaskSheet() async {
    final task = await showModalBottomSheet<TaskModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _AddTaskSheet(),
    );
    if (task != null && mounted) {
      context.read<TaskBloc>().add(CreateTaskEvent(task));
    }
  }
}

class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader({required this.userName, required this.onLogout});

  final String userName;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final name = userName.trim();
    final firstName = name.isEmpty ? 'there' : name.split(RegExp(r'\s+')).first;
    final hour = DateTime.now().hour;
    final greeting = switch (hour) {
      < 12 => 'Good morning',
      < 17 => 'Good afternoon',
      _ => 'Good evening',
    };
    final initial = firstName == 'there' ? 'S' : firstName[0].toUpperCase();

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$greeting,',
                style: const TextStyle(
                  color: Colors.white60,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                firstName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 25,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                MaterialLocalizations.of(context)
                    .formatMediumDate(DateTime.now()),
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        CircleAvatar(
          radius: 21,
          backgroundColor: GlassTheme.cyanAccent.withValues(alpha: 0.16),
          child: Text(
            initial,
            style: const TextStyle(
              color: GlassTheme.cyanAccent,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 4),
        IconButton(
          tooltip: 'Sign out',
          onPressed: onLogout,
          icon: const Icon(Icons.logout_rounded),
          style: IconButton.styleFrom(
            foregroundColor: Colors.white70,
            backgroundColor: Colors.white.withValues(alpha: 0.06),
          ),
        ),
      ],
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 19,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          subtitle,
          style: const TextStyle(color: Colors.white54, fontSize: 12),
        ),
      ],
    );
  }
}

class _TaskAnalyticsBar extends StatelessWidget {
  const _TaskAnalyticsBar({
    required this.total,
    required this.completed,
    required this.pending,
  });

  final int total;
  final int completed;
  final int pending;

  @override
  Widget build(BuildContext context) {
    return GlassTheme.glassContainer(
      borderRadius: 18,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      child: Row(
        children: [
          Expanded(
            child: _AnalyticsMetric(
              label: 'Total',
              value: total,
              accent: Colors.white,
            ),
          ),
          _AnalyticsDivider(),
          Expanded(
            child: _AnalyticsMetric(
              label: 'Done',
              value: completed,
              accent: const Color(0xFF56D6A0),
            ),
          ),
          _AnalyticsDivider(),
          Expanded(
            child: _AnalyticsMetric(
              label: 'Pending',
              value: pending,
              accent: const Color(0xFFFFC45C),
            ),
          ),
        ],
      ),
    );
  }
}

class _AnalyticsDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 30,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      color: Colors.white.withValues(alpha: 0.12),
    );
  }
}

class _AnalyticsMetric extends StatelessWidget {
  const _AnalyticsMetric({
    required this.label,
    required this.value,
    required this.accent,
  });

  final String label;
  final int value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$value',
          style: TextStyle(
            color: accent,
            fontSize: 19,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: Colors.white60, fontSize: 11),
        ),
      ],
    );
  }
}

class _CompletedTasksHeader extends StatelessWidget {
  const _CompletedTasksHeader({
    required this.count,
    required this.expanded,
    required this.onTap,
  });

  final int count;
  final bool expanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              const Icon(Icons.done_all, color: Color(0xFF56D6A0), size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Completed ($count)',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Icon(
                expanded ? Icons.expand_less : Icons.expand_more,
                color: Colors.white60,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureGrid extends StatelessWidget {
  const _FeatureGrid({required this.onTasksTap, required this.accessToken});

  final VoidCallback onTasksTap;
  final String accessToken;

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverGrid(
        gridDelegate: const _BentoGridDelegate(),
        delegate: SliverChildListDelegate([
          _FeatureTile(
            icon: Icons.auto_awesome,
            title: 'Study Buddy',
            subtitle: 'Quiz yourself from your notes',
            accent: GlassTheme.accentNeon,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => QuizChatPage(accessToken: accessToken),
              ),
            ),
          ),
          _FeatureTile(
            icon: Icons.timer_outlined,
            title: 'Pomodoro',
            subtitle: '25 min focus',
            accent: GlassTheme.cyanAccent,
            compact: true,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute<void>(builder: (_) => const PomodoroPage()),
            ),
          ),
          _FeatureTile(
            icon: Icons.check_circle_outline,
            title: 'My tasks',
            subtitle: 'Plan the next step',
            accent: Colors.lightGreenAccent,
            compact: true,
            onTap: onTasksTap,
          ),
        ]),
      ),
    );
  }
}

class _BentoGridDelegate extends SliverGridDelegate {
  const _BentoGridDelegate();

  static const _smallTileExtent = 102.0;
  static const _mainAxisSpacing = 12.0;
  static const _crossAxisSpacing = 12.0;

  @override
  SliverGridLayout getLayout(SliverConstraints constraints) {
    final tileWidth = (constraints.crossAxisExtent - _crossAxisSpacing) / 2;
    return _BentoGridLayout(
      tileWidth: tileWidth,
      smallTileExtent: _smallTileExtent,
      mainAxisSpacing: _mainAxisSpacing,
      crossAxisSpacing: _crossAxisSpacing,
    );
  }

  @override
  bool shouldRelayout(covariant _BentoGridDelegate oldDelegate) => false;
}

class _BentoGridLayout extends SliverGridLayout {
  const _BentoGridLayout({
    required this.tileWidth,
    required this.smallTileExtent,
    required this.mainAxisSpacing,
    required this.crossAxisSpacing,
  });

  final double tileWidth;
  final double smallTileExtent;
  final double mainAxisSpacing;
  final double crossAxisSpacing;

  double get _heroExtent => smallTileExtent * 2 + mainAxisSpacing;
  double get _secondRowOffset => smallTileExtent + mainAxisSpacing;

  @override
  SliverGridGeometry getGeometryForChildIndex(int index) {
    final isHero = index == 0;
    return SliverGridGeometry(
      scrollOffset: index < 2 ? 0 : _secondRowOffset,
      crossAxisOffset: index == 0 ? 0 : tileWidth + crossAxisSpacing,
      mainAxisExtent: isHero ? _heroExtent : smallTileExtent,
      crossAxisExtent: tileWidth,
    );
  }

  @override
  int getMinChildIndexForScrollOffset(double scrollOffset) =>
      scrollOffset < _heroExtent ? 0 : 2;

  @override
  int getMaxChildIndexForScrollOffset(double scrollOffset) =>
      scrollOffset < _secondRowOffset ? 1 : 2;

  @override
  double computeMaxScrollOffset(int childCount) =>
      childCount == 0 ? 0 : _heroExtent;
}

class _FeatureTile extends StatelessWidget {
  const _FeatureTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.onTap,
    this.compact = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color accent;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: GlassTheme.glassContainer(
          borderRadius: 20,
          padding: EdgeInsets.all(compact ? 12 : 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: accent, size: compact ? 25 : 38),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: compact ? 14 : 19,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    maxLines: compact ? 1 : 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white60,
                      fontSize: compact ? 10 : 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryFilters extends StatelessWidget {
  const _CategoryFilters({
    required this.categories,
    required this.selected,
    required this.onSelected,
  });

  final List<String> categories;
  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = category == selected;
          return ChoiceChip(
            label: Text(category),
            selected: isSelected,
            onSelected: (_) => onSelected(category),
            selectedColor: GlassTheme.cyanAccent,
            backgroundColor: Colors.white.withValues(alpha: 0.08),
            side: BorderSide(
              color: isSelected ? GlassTheme.cyanAccent : Colors.white24,
            ),
            labelStyle: TextStyle(
              color: isSelected ? Colors.white : Colors.white70,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            ),
            showCheckmark: false,
          );
        },
      ),
    );
  }
}

class _TaskTile extends StatelessWidget {
  const _TaskTile({required this.task, required this.index});

  final TaskModel task;
  final int index;

  @override
  Widget build(BuildContext context) {
    final priorityColor = switch (task.priority.toLowerCase()) {
      'high' => const Color(0xFFFF5B68),
      'low' => const Color(0xFF56D6A0),
      _ => const Color(0xFFFFC45C),
    };
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dueDay = DateTime(
      task.dueDate.year,
      task.dueDate.month,
      task.dueDate.day,
    );
    final daysUntilDue = dueDay.difference(today).inDays;
    final dueLabel = switch (daysUntilDue) {
      < 0 => 'Overdue',
      0 => 'Due Today',
      1 => 'Due Tomorrow',
      _ => 'In $daysUntilDue Days',
    };
    final dueColor = daysUntilDue <= 0
        ? const Color(0xFFFF7A86)
        : daysUntilDue <= 2
        ? const Color(0xFFFFC45C)
        : const Color(0xFF70D9C0);
    final taskKey = ValueKey(task.id ?? '${task.title}-$index');

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Dismissible(
        key: taskKey,
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 22),
          decoration: BoxDecoration(
            color: const Color(0xFFB9384B),
            borderRadius: BorderRadius.circular(18),
          ),
          child: const Icon(Icons.delete_outline, color: Colors.white),
        ),
        onDismissed: (_) {
          if (task.id != null) {
            context.read<TaskBloc>().add(DeleteTaskEvent(task.id!));
          } else {
            context.read<TaskBloc>().add(FetchTasksEvent());
          }
        },
        child: GlassTheme.glassContainer(
          borderRadius: 18,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(
            children: [
              Checkbox(
                value: task.isCompleted,
                activeColor: GlassTheme.cyanAccent,
                onChanged: task.id == null
                    ? null
                    : (_) => context.read<TaskBloc>().add(
                        ToggleTaskCompletionEvent(task.id!, task.isCompleted),
                      ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: task.isCompleted ? Colors.white54 : Colors.white,
                        decoration: task.isCompleted
                            ? TextDecoration.lineThrough
                            : null,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      task.category,
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                      ),
                    ),
                    if (!task.isCompleted) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: dueColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(9),
                          border: Border.all(
                            color: dueColor.withValues(alpha: 0.35),
                          ),
                        ),
                        child: Text(
                          dueLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: dueColor,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: priorityColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: priorityColor.withValues(alpha: 0.45),
                  ),
                ),
                child: Text(
                  task.priority,
                  style: TextStyle(
                    color: priorityColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TaskLoadError extends StatelessWidget {
  const _TaskLoadError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_outlined,
              color: Colors.white54,
              size: 34,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: () => context.read<TaskBloc>().add(FetchTasksEvent()),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddTaskSheet extends StatefulWidget {
  const _AddTaskSheet();

  @override
  State<_AddTaskSheet> createState() => _AddTaskSheetState();
}

class _AddTaskSheetState extends State<_AddTaskSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _category = 'Homework';
  String _priority = 'Medium';
  DateTime _dueDate = DateTime.now().add(const Duration(days: 1));

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF182337),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          top: false,
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Center(
                    child: Container(
                      width: 38,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white30,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Add a task',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _titleController,
                    autofocus: true,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: _inputDecoration('Task title'),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Enter a task title'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _descriptionController,
                    textCapitalization: TextCapitalization.sentences,
                    maxLines: 2,
                    decoration: _inputDecoration('Notes (optional)'),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: _category,
                          decoration: _inputDecoration('Category'),
                          dropdownColor: const Color(0xFF182337),
                          items: const ['Homework', 'Exams', 'Projects']
                              .map(
                                (value) => DropdownMenuItem(
                                  value: value,
                                  child: Text(value),
                                ),
                              )
                              .toList(),
                          onChanged: (value) =>
                              setState(() => _category = value!),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: _priority,
                          decoration: _inputDecoration('Priority'),
                          dropdownColor: const Color(0xFF182337),
                          items: const ['High', 'Medium', 'Low']
                              .map(
                                (value) => DropdownMenuItem(
                                  value: value,
                                  child: Text(value),
                                ),
                              )
                              .toList(),
                          onChanged: (value) =>
                              setState(() => _priority = value!),
                        ),
                      ),
                    ],
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: _pickDueDate,
                      icon: const Icon(Icons.calendar_today_outlined, size: 17),
                      label: Text(
                        'Due ${MaterialLocalizations.of(context).formatMediumDate(_dueDate)}',
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _submit,
                      icon: const Icon(Icons.add),
                      label: const Text('Create task'),
                      style: FilledButton.styleFrom(
                        backgroundColor: GlassTheme.cyanAccent,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label) => InputDecoration(
    labelText: label,
    labelStyle: const TextStyle(color: Colors.white60),
    filled: true,
    fillColor: Colors.white.withValues(alpha: 0.06),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
  );

  Future<void> _pickDueDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(colorScheme: const ColorScheme.dark()),
        child: child!,
      ),
    );
    if (date != null) setState(() => _dueDate = date);
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(
      context,
      TaskModel(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _category,
        priority: _priority,
        dueDate: _dueDate,
      ),
    );
  }
}
