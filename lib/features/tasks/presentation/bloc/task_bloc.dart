import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;

import '../../../../core/constants/api_constants.dart';
import '../../data/models/task_model.dart';

abstract class TaskEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class FetchTasksEvent extends TaskEvent {}

class CreateTaskEvent extends TaskEvent {
  final TaskModel task;

  CreateTaskEvent(this.task);

  @override
  List<Object?> get props => [
    task.title,
    task.category,
    task.priority,
    task.dueDate,
  ];
}

class DeleteTaskEvent extends TaskEvent {
  final int taskId;

  DeleteTaskEvent(this.taskId);

  @override
  List<Object?> get props => [taskId];
}

class ToggleTaskCompletionEvent extends TaskEvent {
  final int taskId;
  final bool currentStatus;

  ToggleTaskCompletionEvent(this.taskId, this.currentStatus);

  @override
  List<Object?> get props => [taskId, currentStatus];
}

abstract class TaskState extends Equatable {
  @override
  List<Object?> get props => [];
}

class TaskInitialState extends TaskState {}

class TaskLoadingState extends TaskState {}

class TaskLoadedState extends TaskState {
  final List<TaskModel> tasks;

  TaskLoadedState(this.tasks);

  @override
  List<Object?> get props => [tasks];
}

class TaskErrorState extends TaskState {
  final String message;

  TaskErrorState(this.message);

  @override
  List<Object?> get props => [message];
}

class TaskBloc extends Bloc<TaskEvent, TaskState> {
  final http.Client _httpClient;
  final bool _ownsHttpClient;
  final String accessToken;
  final List<TaskModel> _pendingLocalTasks = [];
  List<TaskModel> _currentTasks = [];
  int _nextLocalId = -1;

  TaskBloc({http.Client? client, this.accessToken = ''})
    : _httpClient = client ?? http.Client(),
      _ownsHttpClient = client == null,
      super(TaskInitialState()) {
    on<FetchTasksEvent>(_onFetchTasks);
    on<ToggleTaskCompletionEvent>(_onToggleTask);
    on<CreateTaskEvent>((event, emit) async {
      final localTask = TaskModel(
        id: _nextLocalId--,
        title: event.task.title,
        description: event.task.description,
        category: event.task.category,
        priority: event.task.priority,
        dueDate: event.task.dueDate,
      );
      _pendingLocalTasks.add(localTask);
      _currentTasks = [..._currentTasks, localTask];
      emit(TaskLoadedState(List.of(_currentTasks)));

      try {
        final response = await _httpClient.post(
          Uri.parse(ApiConstants.tasksEndpoint),
          headers: _authHeaders,
          body: json.encode(event.task.toJson()),
        );
        if (response.statusCode == 200 || response.statusCode == 201) {
          add(FetchTasksEvent());
        }
      } catch (_) {
        // Keep the task visible locally when the API is unavailable.
      }
    });
    on<DeleteTaskEvent>((event, emit) async {
      if (event.taskId < 0) {
        _pendingLocalTasks.removeWhere((task) => task.id == event.taskId);
        _currentTasks.removeWhere((task) => task.id == event.taskId);
        emit(TaskLoadedState(List.of(_currentTasks)));
        return;
      }
      try {
        final response = await _httpClient.delete(
          Uri.parse('${ApiConstants.tasksEndpoint}?id=${event.taskId}'),
          headers: _authHeaders,
        );
        if (response.statusCode == 200 || response.statusCode == 204) {
          add(FetchTasksEvent());
        } else {
          emit(TaskErrorState('Task deletion failed (${response.statusCode})'));
        }
      } catch (e) {
        emit(TaskErrorState('Task deletion failed: $e'));
      }
    });
  }

  Future<void> _onFetchTasks(
    FetchTasksEvent event,
    Emitter<TaskState> emit,
  ) async {
    if (_currentTasks.isEmpty) emit(TaskLoadingState());
    try {
      final response = await _httpClient.get(
        Uri.parse(ApiConstants.tasksEndpoint),
        headers: _authHeaders,
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final serverTasks = data.map((e) => TaskModel.fromJson(e)).toList();
        _pendingLocalTasks.removeWhere(
          (localTask) =>
              serverTasks.any((serverTask) => _sameTask(localTask, serverTask)),
        );
        _currentTasks = [...serverTasks, ..._pendingLocalTasks];
        emit(TaskLoadedState(List.of(_currentTasks)));
      } else {
        if (_currentTasks.isEmpty) {
          emit(TaskErrorState('Failed to connect to XAMPP REST API'));
        } else {
          emit(TaskLoadedState(List.of(_currentTasks)));
        }
      }
    } catch (e) {
      if (_currentTasks.isEmpty) {
        emit(TaskErrorState(e.toString()));
      } else {
        emit(TaskLoadedState(List.of(_currentTasks)));
      }
    }
  }

  Future<void> _onToggleTask(
    ToggleTaskCompletionEvent event,
    Emitter<TaskState> emit,
  ) async {
    if (event.taskId < 0) {
      final index = _pendingLocalTasks.indexWhere(
        (task) => task.id == event.taskId,
      );
      if (index >= 0) {
        final task = _pendingLocalTasks[index];
        final updatedTask = TaskModel(
          id: task.id,
          title: task.title,
          description: task.description,
          category: task.category,
          priority: task.priority,
          dueDate: task.dueDate,
          isCompleted: !event.currentStatus,
        );
        _pendingLocalTasks[index] = updatedTask;
        _currentTasks = _currentTasks
            .map((item) => item.id == event.taskId ? updatedTask : item)
            .toList();
        emit(TaskLoadedState(List.of(_currentTasks)));
      }
      return;
    }
    try {
      await _httpClient.put(
        Uri.parse(ApiConstants.tasksEndpoint),
        headers: _authHeaders,
        body: json.encode({
          'id': event.taskId,
          'is_completed': !event.currentStatus,
        }),
      );
      add(FetchTasksEvent());
    } catch (e) {
      emit(TaskErrorState('Update sync failed'));
    }
  }

  bool _sameTask(TaskModel first, TaskModel second) {
    return first.title == second.title &&
        first.category == second.category &&
        first.priority == second.priority &&
        first.dueDate.year == second.dueDate.year &&
        first.dueDate.month == second.dueDate.month &&
        first.dueDate.day == second.dueDate.day;
  }

  Map<String, String> get _authHeaders => {
    'Accept': 'application/json',
    'Content-Type': 'application/json',
    if (accessToken.isNotEmpty) 'Authorization': 'Bearer $accessToken',
  };

  @override
  Future<void> close() {
    if (_ownsHttpClient) _httpClient.close();
    return super.close();
  }
}
