enum MessagePriority { critical, high, normal, low }

enum MessageStatus { pending, transmitting, delivered, failed }

class PendingMessage {
  final String id;
  final String type; // 'SOS_DISPATCH', 'LOCATION_UPDATE', 'STATUS_ACK'
  final Map<String, dynamic> payload;
  final DateTime createdAt;
  final MessagePriority priority;
  final int retryCount;
  final MessageStatus status;
  final String? lastError;

  const PendingMessage({
    required this.id,
    required this.type,
    required this.payload,
    required this.createdAt,
    this.priority = MessagePriority.critical,
    this.retryCount = 0,
    this.status = MessageStatus.pending,
    this.lastError,
  });

  PendingMessage copyWith({
    String? id,
    String? type,
    Map<String, dynamic>? payload,
    DateTime? createdAt,
    MessagePriority? priority,
    int? retryCount,
    MessageStatus? status,
    String? lastError,
  }) {
    return PendingMessage(
      id: id ?? this.id,
      type: type ?? this.type,
      payload: payload ?? this.payload,
      createdAt: createdAt ?? this.createdAt,
      priority: priority ?? this.priority,
      retryCount: retryCount ?? this.retryCount,
      status: status ?? this.status,
      lastError: lastError ?? this.lastError,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'payload': payload,
        'createdAt': createdAt.toIso8601String(),
        'priority': priority.name,
        'retryCount': retryCount,
        'status': status.name,
        'lastError': lastError,
      };

  factory PendingMessage.fromJson(Map<String, dynamic> json) => PendingMessage(
        id: json['id'] as String,
        type: json['type'] as String,
        payload: Map<String, dynamic>.from(json['payload'] as Map),
        createdAt: DateTime.parse(json['createdAt'] as String),
        priority: MessagePriority.values.firstWhere(
          (p) => p.name == json['priority'],
          orElse: () => MessagePriority.normal,
        ),
        retryCount: (json['retryCount'] as num?)?.toInt() ?? 0,
        status: MessageStatus.values.firstWhere(
          (s) => s.name == json['status'],
          orElse: () => MessageStatus.pending,
        ),
        lastError: json['lastError'] as String?,
      );
}
