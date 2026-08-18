import 'dart:async';
import 'pending_message.dart';

class OfflineMessageQueue {
  final List<PendingMessage> _queue = [];
  final StreamController<List<PendingMessage>> _queueController =
      StreamController<List<PendingMessage>>.broadcast();

  List<PendingMessage> get pendingMessages => List.unmodifiable(_queue);
  int get queueSize => _queue.length;
  Stream<List<PendingMessage>> get queueStream => _queueController.stream;

  void enqueue(PendingMessage message) {
    _queue.add(message);
    // Sort by priority (critical first) and createdAt (oldest first)
    _queue.sort((a, b) {
      final pComp = a.priority.index.compareTo(b.priority.index);
      if (pComp != 0) return pComp;
      return a.createdAt.compareTo(b.createdAt);
    });
    _notify();
  }

  PendingMessage? dequeue() {
    if (_queue.isEmpty) return null;
    final item = _queue.removeAt(0);
    _notify();
    return item;
  }

  void markDelivered(String id) {
    _queue.removeWhere((m) => m.id == id);
    _notify();
  }

  void markFailed(String id, String error) {
    final idx = _queue.indexWhere((m) => m.id == id);
    if (idx != -1) {
      final msg = _queue[idx];
      _queue[idx] = msg.copyWith(
        retryCount: msg.retryCount + 1,
        status: MessageStatus.failed,
        lastError: error,
      );
      _notify();
    }
  }

  void _notify() {
    _queueController.add(List.unmodifiable(_queue));
  }

  void dispose() {
    _queueController.close();
  }
}
