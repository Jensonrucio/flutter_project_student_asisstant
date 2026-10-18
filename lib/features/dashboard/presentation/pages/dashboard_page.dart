import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
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
    required this.isDarkTheme,
    required this.onThemeChanged,
    super.key,
  });

  final String accessToken;
  final String userName;
  final VoidCallback onLogout;
  final bool isDarkTheme;
  final ValueChanged<bool> onThemeChanged;

  @override
  State<StudentDashboardPage> createState() => _StudentDashboardPageState();
}

class _StudentDashboardPageState extends State<StudentDashboardPage> {
  static const _categories = ['All', 'Homework', 'Exams', 'Projects'];
  static const _dueDateFilters = ['Any date', 'Today', 'Tomorrow', 'Later'];
  static const _priorities = ['Any priority', 'High', 'Medium', 'Low'];
  final _tasksKey = GlobalKey();
  final _pomodoroController = PomodoroTimerController();
  String _selectedCategory = 'All';
  String _selectedDueDateFilter = 'Any date';
  String _selectedPriority = 'Any priority';
  bool _showCompletedTasks = false;

  @override
  void dispose() {
    _pomodoroController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GlassTheme.background(context),
      body: Stack(
        children: [
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 920),
                child: BlocBuilder<TaskBloc, TaskState>(
                  builder: (context, state) {
                    final tasks = state is TaskLoadedState
                        ? state.tasks
                        : const <TaskModel>[];
                    final now = DateTime.now();
                    final today = DateTime(now.year, now.month, now.day);
                    final urgentTaskCount = tasks.where((task) {
                      final daysUntilDue = _daysUntilDate(task.dueDate, today);
                      return !task.isCompleted &&
                          (daysUntilDue == 0 || daysUntilDue == 1);
                    }).length;
                    final filteredTasks = tasks.where((task) {
                      final matchesCategory =
                          _selectedCategory == 'All' ||
                          task.category.toLowerCase() ==
                              _selectedCategory.toLowerCase();
                      final matchesPriority =
                          _selectedPriority == 'Any priority' ||
                          task.priority.toLowerCase() ==
                              _selectedPriority.toLowerCase();
                      final dueDay = DateTime(
                        task.dueDate.year,
                        task.dueDate.month,
                        task.dueDate.day,
                      );
                      final daysUntilDue = _daysUntilDate(dueDay, today);
                      final matchesDueDate = switch (_selectedDueDateFilter) {
                        'Today' => daysUntilDue == 0,
                        'Tomorrow' => daysUntilDue == 1,
                        'Later' => daysUntilDue > 7,
                        _ => true,
                      };
                      return matchesCategory &&
                          matchesPriority &&
                          matchesDueDate;
                    }).toList();
                    final completedTaskCount = tasks
                        .where((task) => task.isCompleted)
                        .length;
                    final pendingTaskCount = tasks.length - completedTaskCount;
                    final pendingTasks =
                        filteredTasks
                            .where((task) => !task.isCompleted)
                            .toList()
                          ..sort(
                            (first, second) =>
                                first.dueDate.compareTo(second.dueDate),
                          );
                    final urgentTasks = pendingTasks.where((task) {
                      return _daysUntilDate(task.dueDate, today) <= 0;
                    }).toList();
                    final dueTomorrowTasks = pendingTasks.where((task) {
                      return _daysUntilDate(task.dueDate, today) == 1;
                    }).toList();
                    final dueSoonTasks = pendingTasks.where((task) {
                      final daysUntilDue = _daysUntilDate(task.dueDate, today);
                      return daysUntilDue >= 2 && daysUntilDue <= 7;
                    }).toList();
                    final laterTasks = pendingTasks.where((task) {
                      return _daysUntilDate(task.dueDate, today) > 7;
                    }).toList();
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
                              isDarkTheme: widget.isDarkTheme,
                              onThemeChanged: widget.onThemeChanged,
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
                        if (urgentTaskCount > 0)
                          SliverPadding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                            sliver: SliverToBoxAdapter(
                              child: _DueTomorrowAlert(
                                count: urgentTaskCount,
                                onTap: () {
                                  setState(() {
                                    _selectedCategory = 'All';
                                    _selectedDueDateFilter = 'Any date';
                                    _selectedPriority = 'Any priority';
                                  });
                                  _scrollToTasks();
                                },
                              ),
                            ),
                          ),
                        SliverPadding(
                          key: _tasksKey,
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                          sliver: SliverToBoxAdapter(
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'Your tasks',
                                    style: TextStyle(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Text(
                                  '${pendingTasks.length} remaining',
                                  style: TextStyle(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SliverPadding(
                          padding: const EdgeInsets.only(bottom: 16),
                          sliver: SliverToBoxAdapter(
                            child: Column(
                              children: [
                                _TaskFilterChips(
                                  title: 'Category',
                                  options: _categories,
                                  selected: _selectedCategory,
                                  onSelected: (value) =>
                                      setState(() => _selectedCategory = value),
                                ),
                                const SizedBox(height: 8),
                                _TaskFilterChips(
                                  title: 'Due date',
                                  options: _dueDateFilters,
                                  selected: _selectedDueDateFilter,
                                  onSelected: (value) => setState(
                                    () => _selectedDueDateFilter = value,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                _TaskFilterChips(
                                  title: 'Priority',
                                  options: _priorities,
                                  selected: _selectedPriority,
                                  onSelected: (value) =>
                                      setState(() => _selectedPriority = value),
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (state is TaskLoadingState)
                          SliverFillRemaining(
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
                            SliverPadding(
                              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                              sliver: SliverToBoxAdapter(
                                child: Text(
                                  'No pending tasks in this view.',
                                  style: TextStyle(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                                ),
                              ),
                            )
                          else ...[
                            ..._buildTaskSection(
                              context: context,
                              title: 'Overdue and due today',
                              subtitle: 'Handle these first',
                              tasks: urgentTasks,
                              allTasks: pendingTasks,
                              color: const Color(0xFFFF5B68),
                              icon: Icons.priority_high_rounded,
                            ),
                            ..._buildTaskSection(
                              context: context,
                              title: 'Due tomorrow',
                              subtitle: 'Make these your next priority',
                              tasks: dueTomorrowTasks,
                              allTasks: pendingTasks,
                              color: const Color(0xFFFF7043),
                              icon: Icons.notifications_active_outlined,
                            ),
                            ..._buildTaskSection(
                              context: context,
                              title: 'Due soon',
                              subtitle: 'Due within the next 7 days',
                              tasks: dueSoonTasks,
                              allTasks: pendingTasks,
                              color: const Color(0xFFFFC45C),
                              icon: Icons.schedule_rounded,
                            ),
                            ..._buildTaskSection(
                              context: context,
                              title: 'Upcoming',
                              subtitle: 'More than 7 days away',
                              tasks: laterTasks,
                              allTasks: pendingTasks,
                              color: const Color(0xFF70D9C0),
                              icon: Icons.event_available_outlined,
                            ),
                          ],
                          SliverPadding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                            sliver: SliverToBoxAdapter(
                              child: _CompletedTasksHeader(
                                count: completedTasks.length,
                                expanded: _showCompletedTasks,
                                onTap: () => setState(
                                  () => _showCompletedTasks =
                                      !_showCompletedTasks,
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
                          onPomodoroTap: _openPomodoro,
                        ),
                        const SliverToBoxAdapter(child: SizedBox(height: 96)),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 88,
            child: SafeArea(
              top: false,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 920),
                  child: _MinimizedPomodoroBanner(
                    controller: _pomodoroController,
                    onOpen: _openPomodoro,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: FloatingActionButton.extended(
            onPressed: _showAddTaskSheet,
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Theme.of(context).colorScheme.onPrimary,
            icon: const Icon(Icons.add),
            label: const Text('Add task'),
          ),
        ),
      ),
    );
  }

  Future<void> _openPomodoro() async {
    _pomodoroController.restore();
    await Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (_) => PomodoroPage(
          controller: _pomodoroController,
          onMinimize: () => Navigator.of(context).pop(),
        ),
      ),
    );
    if (mounted && _pomodoroController.hasSession) {
      _pomodoroController.minimize();
    }
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

class _MinimizedPomodoroBanner extends StatelessWidget {
  const _MinimizedPomodoroBanner({
    required this.controller,
    required this.onOpen,
  });

  final PomodoroTimerController controller;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        if (!controller.hasSession || !controller.isMinimized) {
          return const SizedBox.shrink();
        }

        final isAlarmPlaying = controller.isAlarmPlaying;
        final controlTooltip = isAlarmPlaying
            ? 'Stop alarm'
            : controller.isRunning
            ? 'Pause timer'
            : 'Resume timer';

        return Container(
          decoration: GlassTheme.glassBoxDecoration(context, borderRadius: 18),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Row(
              children: [
                Icon(
                  isAlarmPlaying
                      ? Icons.alarm_on_rounded
                      : Icons.timer_outlined,
                  color: isAlarmPlaying
                      ? Theme.of(context).colorScheme.error
                      : GlassTheme.cyanAccent,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: InkWell(
                    onTap: onOpen,
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            isAlarmPlaying
                                ? 'Focus session complete'
                                : controller.isRunning
                                ? 'Pomodoro running'
                                : 'Pomodoro paused',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            controller.timeString,
                            style: TextStyle(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                IconButton(
                  tooltip: controlTooltip,
                  visualDensity: VisualDensity.compact,
                  onPressed: isAlarmPlaying
                      ? controller.stopAlarm
                      : controller.isRunning
                      ? controller.pause
                      : controller.start,
                  icon: Icon(
                    isAlarmPlaying
                        ? Icons.stop_circle_outlined
                        : controller.isRunning
                        ? Icons.pause_circle_outline
                        : Icons.play_circle_outline,
                  ),
                ),
                IconButton(
                  tooltip: 'Open Pomodoro timer',
                  visualDensity: VisualDensity.compact,
                  onPressed: onOpen,
                  icon: const Icon(Icons.open_in_full),
                ),
                IconButton(
                  tooltip: 'Close Pomodoro timer',
                  visualDensity: VisualDensity.compact,
                  onPressed: controller.closeSession,
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

enum _DashboardMenuAction { lightTheme, darkTheme, signOut }

class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader({
    required this.userName,
    required this.onLogout,
    required this.isDarkTheme,
    required this.onThemeChanged,
  });

  final String userName;
  final VoidCallback onLogout;
  final bool isDarkTheme;
  final ValueChanged<bool> onThemeChanged;

  @override
  Widget build(BuildContext context) {
    final name = userName.trim();
    final firstName = name.isEmpty ? 'there' : name.split(RegExp(r'\s+')).first;
    final hour = DateTime.now().hour;
    final greeting = switch (hour) {
      < 12 => 'Good Morning',
      < 17 => 'Good Afternoon',
      _ => 'Good Evening',
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
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                firstName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 25,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                MaterialLocalizations.of(context)
                    .formatMediumDate(DateTime.now()),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 12,
                ),
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
        PopupMenuButton<_DashboardMenuAction>(
          tooltip: 'Main menu',
          onSelected: (action) {
            switch (action) {
              case _DashboardMenuAction.lightTheme:
                onThemeChanged(false);
              case _DashboardMenuAction.darkTheme:
                onThemeChanged(true);
              case _DashboardMenuAction.signOut:
                onLogout();
            }
          },
          icon: const Icon(Icons.more_vert),
          itemBuilder: (context) => [
            PopupMenuItem<_DashboardMenuAction>(
              value: _DashboardMenuAction.lightTheme,
              child: Row(
                children: [
                  const Icon(Icons.light_mode_outlined),
                  const SizedBox(width: 10),
                  const Text('Light theme'),
                  if (!isDarkTheme) ...[
                    const Spacer(),
                    Icon(
                      Icons.check,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ],
                ],
              ),
            ),
            PopupMenuItem<_DashboardMenuAction>(
              value: _DashboardMenuAction.darkTheme,
              child: Row(
                children: [
                  const Icon(Icons.dark_mode_outlined),
                  const SizedBox(width: 10),
                  const Text('Dark theme'),
                  if (isDarkTheme) ...[
                    const Spacer(),
                    Icon(
                      Icons.check,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ],
                ],
              ),
            ),
            const PopupMenuDivider(),
            const PopupMenuItem<_DashboardMenuAction>(
              value: _DashboardMenuAction.signOut,
              child: Row(
                children: [
                  Icon(Icons.logout_rounded),
                  SizedBox(width: 10),
                  Text('Sign out'),
                ],
              ),
            ),
          ],
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
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 19,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          subtitle,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontSize: 12,
          ),
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
      context: context,
      borderRadius: 18,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      child: Row(
        children: [
          Expanded(
            child: _AnalyticsMetric(
              label: 'Total',
              value: total,
              accent: Theme.of(context).colorScheme.onSurface,
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
      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.12),
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
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontSize: 11,
          ),
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
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Icon(
                expanded ? Icons.expand_less : Icons.expand_more,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureGrid extends StatelessWidget {
  const _FeatureGrid({
    required this.onTasksTap,
    required this.onPomodoroTap,
    required this.accessToken,
  });

  final VoidCallback onTasksTap;
  final VoidCallback onPomodoroTap;
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
            title: 'Streak Buddy',
            subtitle: '15 min focus',
            accent: GlassTheme.cyanAccent,
            compact: true,
            onTap: onPomodoroTap,
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
          context: context,
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
                      color: Theme.of(context).colorScheme.onSurface,
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
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
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

class _TaskFilterChips extends StatelessWidget {
  const _TaskFilterChips({
    required this.title,
    required this.options,
    required this.selected,
    required this.onSelected,
  });

  final String title;
  final List<String> options;
  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            title,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 4),
        SizedBox(
          height: 42,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: options.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final option = options[index];
              final isSelected = option == selected;
              return ChoiceChip(
                label: Text(option),
                selected: isSelected,
                onSelected: (_) => onSelected(option),
                selectedColor: Theme.of(context).colorScheme.primary,
                backgroundColor: Theme.of(context).colorScheme.onSurface
                    .withValues(alpha: 0.08),
                side: BorderSide(
                  color: isSelected
                      ? GlassTheme.cyanAccent
                      : Theme.of(context).colorScheme.outlineVariant,
                ),
                labelStyle: TextStyle(
                  color: isSelected
                      ? Theme.of(context).colorScheme.onPrimary
                      : Theme.of(context).colorScheme.onSurface,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                ),
                showCheckmark: false,
              );
            },
          ),
        ),
      ],
    );
  }
}

List<Widget> _buildTaskSection({
  required BuildContext context,
  required String title,
  required String subtitle,
  required List<TaskModel> tasks,
  required List<TaskModel> allTasks,
  required Color color,
  required IconData icon,
}) {
  if (tasks.isEmpty) return const [];

  return [
    SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      sliver: SliverToBoxAdapter(
        child: Row(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 7),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: color,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${tasks.length}',
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
    SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) => _TaskTile(
            task: tasks[index],
            index: allTasks.indexOf(tasks[index]),
          ),
          childCount: tasks.length,
        ),
      ),
    ),
  ];
}

class _DueTomorrowAlert extends StatelessWidget {
  const _DueTomorrowAlert({required this.count, required this.onTap});

  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final alertColor = Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFFFF9A76)
        : const Color(0xFFB94324);
    return Container(
      decoration: BoxDecoration(
        color: alertColor.withValues(alpha: 0.11),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: alertColor.withValues(alpha: 0.38)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: alertColor.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.notifications_active_rounded,
                    color: alertColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'PRIORITY TASK',
                        style: TextStyle(
                          color: alertColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.7,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '$count ${count == 1 ? 'task' : 'tasks'} need attention. Tap to review.',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.arrow_forward_rounded, color: alertColor, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

int _daysUntilDate(DateTime date, DateTime today) {
  return DateTime.utc(
    date.year,
    date.month,
    date.day,
  ).difference(DateTime.utc(today.year, today.month, today.day)).inDays;
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
    final daysUntilDue = _daysUntilDate(dueDay, today);
    final dueLabel = switch (daysUntilDue) {
      < 0 => 'Overdue',
      0 => 'Due Today',
      1 => 'Due Tomorrow',
      _ => 'In $daysUntilDue Days',
    };
    final dueColor = daysUntilDue <= 0
        ? const Color(0xFFFF7A86)
        : daysUntilDue == 1
        ? const Color(0xFFFF7043)
        : daysUntilDue <= 2
        ? const Color(0xFFFFC45C)
        : const Color(0xFF70D9C0);
    final isDueTomorrow = daysUntilDue == 1 && !task.isCompleted;
    final isDueSoon =
        daysUntilDue >= 2 && daysUntilDue <= 7 && !task.isCompleted;
    final isTimeSensitive = isDueTomorrow || isDueSoon;
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
        child: InkWell(
          onTap: () => _showTaskDetails(context, task),
          borderRadius: BorderRadius.circular(18),
          child: GlassTheme.glassContainer(
            context: context,
            borderRadius: 18,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Row(
              children: [
                if (isTimeSensitive)
                  Container(
                    width: 4,
                    height: 52,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: dueColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
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
                          color: task.isCompleted
                              ? Theme.of(context).colorScheme.onSurfaceVariant
                              : Theme.of(context).colorScheme.onSurface,
                          decoration: task.isCompleted
                              ? TextDecoration.lineThrough
                              : null,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        task.category,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontSize: 12,
                        ),
                      ),
                      if (task.description.trim().isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          task.description,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
                            fontSize: 12,
                            height: 1.35,
                          ),
                        ),
                      ],
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
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (isTimeSensitive) ...[
                                Icon(
                                  isDueTomorrow
                                      ? Icons.notifications_active_outlined
                                      : Icons.schedule_rounded,
                                  size: 13,
                                  color: dueColor,
                                ),
                                const SizedBox(width: 4),
                              ],
                              Text(
                                isDueTomorrow
                                    ? 'DUE TOMORROW'
                                    : isDueSoon
                                    ? 'DUE IN $daysUntilDue DAYS'
                                    : dueLabel,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: dueColor,
                                  fontSize: isTimeSensitive ? 11 : 10,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: isTimeSensitive ? 0.25 : 0,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 5,
                  ),
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
      ),
    );
  }
}

Future<void> _showTaskDetails(BuildContext context, TaskModel task) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _TaskDetailsSheet(task: task),
  );
}

class _TaskDetailsSheet extends StatelessWidget {
  const _TaskDetailsSheet({required this.task});

  final TaskModel task;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final notes = task.description;
    final hasNotes = notes.trim().isNotEmpty;
    final priorityColor = switch (task.priority.toLowerCase()) {
      'high' => const Color(0xFFFF5B68),
      'low' => const Color(0xFF56D6A0),
      _ => const Color(0xFFFFC45C),
    };
    final dateLabel = MaterialLocalizations.of(context)
        .formatFullDate(task.dueDate);

    return SafeArea(
      top: false,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
        builder: (context, progress, child) => Opacity(
          opacity: progress,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - progress)),
            child: child,
          ),
        ),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.85,
          ),
          decoration: BoxDecoration(
            color: GlassTheme.background(context),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(22, 12, 22, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: colorScheme.onSurfaceVariant.withValues(
                        alpha: 0.4,
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        task.title,
                        style: TextStyle(
                          color: colorScheme.onSurface,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Close task details',
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _TaskDetailBadge(
                      icon: Icons.folder_outlined,
                      label: task.category,
                    ),
                    _TaskDetailBadge(
                      icon: Icons.flag_outlined,
                      label: task.priority,
                      color: priorityColor,
                    ),
                    _TaskDetailBadge(
                      icon: task.isCompleted
                          ? Icons.check_circle_outline
                          : Icons.radio_button_unchecked,
                      label: task.isCompleted ? 'Completed' : 'Pending',
                      color: task.isCompleted
                          ? const Color(0xFF56D6A0)
                          : colorScheme.primary,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _TaskDetailSection(
                  title: 'Due date',
                  icon: Icons.event_outlined,
                  child: Text(
                    dateLabel,
                    style: TextStyle(
                      color: colorScheme.onSurface,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                _TaskDetailSection(
                  title: 'Notes',
                  icon: Icons.notes_outlined,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (hasNotes)
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton.icon(
                            onPressed: () async {
                              try {
                                await Clipboard.setData(
                                  ClipboardData(text: notes),
                                );
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Notes copied to clipboard.'),
                                  ),
                                );
                              } on PlatformException {
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Unable to copy notes.'),
                                  ),
                                );
                              }
                            },
                            icon: const Icon(Icons.copy_outlined, size: 18),
                            label: const Text('Copy notes'),
                          ),
                        ),
                      Text(
                        hasNotes ? notes : 'No notes added yet.',
                        style: TextStyle(
                          color: hasNotes
                              ? colorScheme.onSurface
                              : colorScheme.onSurfaceVariant,
                          fontSize: 15,
                          height: 1.55,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TaskDetailBadge extends StatelessWidget {
  const _TaskDetailBadge({required this.icon, required this.label, this.color});

  final IconData icon;
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final badgeColor = color ?? Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: badgeColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: badgeColor),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: badgeColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _TaskDetailSection extends StatelessWidget {
  const _TaskDetailSection({
    required this.title,
    required this.icon,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: GlassTheme.cyanAccent),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        child,
      ],
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
            Icon(
              Icons.cloud_off_outlined,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              size: 34,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
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
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
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
                        color: Theme.of(context).colorScheme.onSurfaceVariant
                            .withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Add a task',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
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
                          dropdownColor: Theme.of(context).colorScheme.surface,
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
                          dropdownColor: Theme.of(context).colorScheme.surface,
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
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Theme.of(context)
                            .colorScheme
                            .onPrimary,
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
    labelStyle: TextStyle(
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    ),
    filled: true,
    fillColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.06),
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
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme
              .copyWith(primary: GlassTheme.cyanAccent),
        ),
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
