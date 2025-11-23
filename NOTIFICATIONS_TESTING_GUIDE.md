# Testing & Example Usage - Notifications Feature

## Quick Start Testing

### 1. Manual Testing in App

#### Step 1: Add Test Notifications to Database
Connect to your Supabase project and run this SQL:

```sql
INSERT INTO notifications (user_id, user_role, title, message, type, is_read)
VALUES 
  (
    '[YOUR_PATIENT_ID]',
    'patient',
    'Appointment Reminder',
    'Your appointment with Dr. Johnson is tomorrow at 2:00 PM',
    'appointment',
    false
  ),
  (
    '[YOUR_PATIENT_ID]',
    'patient',
    'Medication Reminder',
    'Time to take your morning insulin dose',
    'medication',
    false
  ),
  (
    '[YOUR_PATIENT_ID]',
    'patient',
    'Wound Care Alert',
    'Please upload your weekly wound care photos',
    'wound',
    true
  ),
  (
    '[YOUR_PATIENT_ID]',
    'patient',
    'Lab Results Available',
    'Your HbA1c test results are now available. Your doctor recommends reviewing them.',
    'patient',
    false
  );
```

#### Step 2: Navigate to Notifications
1. Log in to the app
2. Click the bell icon (🔔) in any screen's AppBar
3. Observe the notifications displayed

#### Step 3: Test Mark as Read
- Tap individual unread notifications
- Verify the colored border and dot disappear
- Tap "Mark All Read" button
- Verify all notifications lose their unread indicators

#### Step 4: Test Refresh
- Pull down on the notifications list
- Verify the loading indicator shows
- New notifications (if added) should appear

---

## Programmatic Testing

### Creating Notifications from Code

```dart
// In any screen or service
final supabase = Supabase.instance.client;

// Send appointment notification
await supabase.from('notifications').insert({
  'user_id': patientId,
  'user_role': 'patient',
  'title': 'Appointment Scheduled',
  'message': 'Your appointment with Dr. Smith has been confirmed for tomorrow at 3:00 PM',
  'type': 'appointment',
  'reference_id': appointmentId,
});

// Send medication notification
await supabase.from('notifications').insert({
  'user_id': patientId,
  'user_role': 'patient',
  'title': 'Take Your Medication',
  'message': 'Time to take your Metformin dosage',
  'type': 'medication',
  'reference_id': medicationId,
});

// Send wound care notification
await supabase.from('notifications').insert({
  'user_id': patientId,
  'user_role': 'patient',
  'title': 'Weekly Wound Check',
  'message': 'Please upload your wound photos for this week',
  'type': 'wound',
  'reference_id': metricId,
});

// Send patient notification
await supabase.from('notifications').insert({
  'user_id': patientId,
  'user_role': 'patient',
  'title': 'Profile Updated',
  'message': 'Your profile information has been updated successfully',
  'type': 'patient',
});
```

### Unit Testing Example

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:your_app/services/supabase_service.dart';

void main() {
  group('Notifications Service', () {
    late SupabaseService supabaseService;

    setUp(() {
      supabaseService = SupabaseService();
    });

    test('getNotifications returns list of notifications', () async {
      final patientId = 'test-patient-id';
      
      final notifications = await supabaseService.getNotifications(patientId);
      
      expect(notifications, isA<List<Map<String, dynamic>>>());
    });

    test('markNotificationAsRead updates is_read to true', () async {
      final notificationId = 'test-notification-id';
      
      await supabaseService.markNotificationAsRead(notificationId);
      
      // Verify in database that is_read is true
    });

    test('markAllNotificationsAsRead marks all user notifications', () async {
      final patientId = 'test-patient-id';
      
      await supabaseService.markAllNotificationsAsRead(patientId);
      
      // Verify in database that all user notifications have is_read = true
    });
  });
}
```

---

## Integration Points

### 1. Appointment Notifications
When an appointment is created (in your appointment service):

```dart
// After creating appointment
await supabase.from('notifications').insert({
  'user_id': patientId,
  'user_role': 'patient',
  'title': 'Appointment Confirmed',
  'message': 'Your appointment with ${doctorName} is scheduled for ${appointmentDate}',
  'type': 'appointment',
  'reference_id': appointmentId,
});
```

### 2. Medication Reminders
When a medication schedule is created:

```dart
// After creating medication schedule
await supabase.from('notifications').insert({
  'user_id': patientId,
  'user_role': 'patient',
  'title': 'Medication Time',
  'message': 'Time to take ${medicationName}',
  'type': 'medication',
  'reference_id': medicationId,
});
```

### 3. Health Metrics Reminders
When reminding users to submit metrics:

```dart
// After checking metrics haven't been submitted today
await supabase.from('notifications').insert({
  'user_id': patientId,
  'user_role': 'patient',
  'title': 'Submit Health Metrics',
  'message': 'Please submit your daily health metrics',
  'type': 'patient',
});
```

### 4. Wound Care Alerts
When wound photos are requested:

```dart
// When wound follow-up is due
await supabase.from('notifications').insert({
  'user_id': patientId,
  'user_role': 'patient',
  'title': 'Wound Care Due',
  'message': 'Time for your weekly wound assessment and photo upload',
  'type': 'wound',
  'reference_id': metricId,
});
```

---

## Debugging

### Enable Console Logs
Add to `NotificationsScreen`:

```dart
@override
void initState() {
  super.initState();
  print('NotificationsScreen initialized for patient: ${widget.patientId}');
  _loadNotifications();
}

void _loadNotifications() {
  print('Loading notifications...');
  setState(() {
    _notificationsFuture = _supabaseService.getNotifications(widget.patientId)
        .then((notifications) {
          print('Loaded ${notifications.length} notifications');
          return notifications;
        })
        .catchError((error) {
          print('Error loading notifications: $error');
          rethrow;
        });
  });
}
```

### Common Issues & Solutions

| Issue | Solution |
|-------|----------|
| No notifications appearing | Check that patientId matches user_id in database |
| Notifications not updating | Verify is_read column is being updated in database |
| Navigation not working | Ensure NotificationsScreen import is correct |
| Icons not showing | Verify Icons class is imported from material |
| Colors not matching | Check Color hex values match design specifications |
| Timestamp format wrong | Verify DateTime.parse() is working correctly |

---

## Performance Optimization

### For Large Notification Lists (100+)
```dart
// Implement pagination
Future<List<Map<String, dynamic>>> getNotificationsPage(
  String userId,
  int page,
  int pageSize,
) async {
  final offset = page * pageSize;
  final response = await supabase
      .from('notifications')
      .select()
      .eq('user_id', userId)
      .order('created_at', ascending: false)
      .range(offset, offset + pageSize - 1);
  return List<Map<String, dynamic>>.from(response);
}
```

### Implement Lazy Loading
```dart
late ScrollController _scrollController;

@override
void initState() {
  super.initState();
  _scrollController = ScrollController();
  _scrollController.addListener(_onScroll);
}

void _onScroll() {
  if (_scrollController.position.pixels ==
      _scrollController.position.maxScrollExtent) {
    // Load more notifications
    _loadMoreNotifications();
  }
}
```

---

## Future Enhancements To Consider

1. **Real-time Updates**
   ```dart
   // Use Supabase real-time subscriptions
   supabase
       .from('notifications')
       .on(RealtimeListenTypes.postgresChanges, ...)
       .listen();
   ```

2. **Push Notifications**
   - Integrate Firebase Cloud Messaging
   - Send notifications to device

3. **Notification Categories**
   - Filter by type
   - Category-specific settings

4. **Archive/Delete**
   - Soft delete with restore option
   - Bulk operations

5. **Notification Templates**
   - Pre-built message templates
   - Internationalization support
