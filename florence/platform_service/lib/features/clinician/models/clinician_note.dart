class ClinicianNote {
  final String id;
  final String patientId;
  final DateTime timestamp;
  final String content;
  final bool isPrivate;
  
  ClinicianNote({
    required this.id,
    required this.patientId,
    required this.timestamp,
    required this.content,
    this.isPrivate = true,
  });
}

class Communication {
  final String id;
  final String patientId;
  final DateTime timestamp;
  final String content;
  final CommunicationType type;
  final bool isRead;
  
  Communication({
    required this.id,
    required this.patientId,
    required this.timestamp,
    required this.content,
    required this.type,
    this.isRead = false,
  });
}

enum CommunicationType {
  message,
  call,
  visit,
  followUp,
}

class ScheduledEvent {
  final String id;
  final String patientId;
  final DateTime dateTime;
  final String title;
  final String description;
  final EventType type;
  
  ScheduledEvent({
    required this.id,
    required this.patientId,
    required this.dateTime,
    required this.title,
    required this.description,
    required this.type,
  });
}

enum EventType {
  appointment,
  labTest,
  medication,
  other,
}
