# Quick Reference - Notifications Feature

## 📌 Quick Start

### For Users
1. Click bell icon 🔔 in any screen
2. View all notifications
3. Tap to mark as read
4. Pull down to refresh

### For Developers
```dart
// Import
import 'screens/notifications_screen.dart';

// Navigate
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => NotificationsScreen(patientId: userId),
  ),
);

// Send notification
await supabase.from('notifications').insert({
  'user_id': userId,
  'user_role': 'patient',
  'title': 'Title',
  'message': 'Message',
  'type': 'appointment', // or 'medication', 'wound', 'patient'
});
```

## 📁 File Structure

```
lib/
├── models/
│   └── notification.dart ..................... Data model
├── screens/
│   ├── notifications_screen.dart ............ Main UI
│   ├── home_screen.dart (modified) ......... + bell navigation
│   ├── medication.dart (modified) .......... + bell navigation
│   ├── health_metrics_history.dart (modified) + bell navigation
│   └── add_metrics_screen.dart (modified) ... + bell navigation
└── services/
    └── supabase_service.dart (modified) ... + 3 new methods
```

## 🎨 Colors

| Type | Color | Hex |
|------|-------|-----|
| Appointment | Blue | #1DA1F2 |
| Medication | Green | #19AC4A |
| Wound | Red | #E74C3C |
| Patient | Purple | #9B59B6 |

## ⚙️ Service Methods

```dart
// Get notifications
getNotifications(String userId)
  → Future<List<Map<String, dynamic>>>

// Mark one as read
markNotificationAsRead(String notificationId)
  → Future<void>

// Mark all as read
markAllNotificationsAsRead(String userId)
  → Future<void>
```

## 🗃️ Database Table

```sql
notifications (
  notification_id: uuid (PK)
  user_id: uuid (FK)
  user_role: text
  title: text
  message: text
  type: text
  reference_id: uuid
  created_at: timestamp
  is_read: boolean
)
```

## 📊 Notification Types

```
appointment  → 📅 Blue   → Appointments
medication   → 💊 Green  → Medications
wound        → 🏥 Red    → Wounds
patient      → 👤 Purple → Profile/Updates
```

## 🧪 Test SQL

```sql
INSERT INTO notifications 
(user_id, user_role, title, message, type, is_read)
VALUES (
  'YOUR_USER_ID',
  'patient',
  'Test Title',
  'Test Message',
  'appointment',
  false
);
```

## 🚨 Troubleshooting

| Problem | Fix |
|---------|-----|
| No notifications | Check user_id matches |
| Not updating | Verify is_read column update |
| Navigation broken | Check import path |
| Wrong colors | Verify hex codes |
| Missing icons | Ensure Icons imported |

## ✅ Verification Checklist

- [ ] Import NotificationsScreen in screen files
- [ ] Bell icon navigates correctly
- [ ] Notifications fetch from database
- [ ] Unread indicators show
- [ ] Mark as read works
- [ ] Colors display correctly
- [ ] Time formatting works
- [ ] Empty state shows
- [ ] Error state with retry
- [ ] Pull refresh works

## 📖 Documentation Files

- `NOTIFICATIONS_SUMMARY.md` ............ Overview
- `NOTIFICATIONS_IMPLEMENTATION.md` ... Technical
- `NOTIFICATIONS_UI_REFERENCE.md` ...... Design
- `NOTIFICATIONS_TESTING_GUIDE.md` .... Testing

## 🔗 Integration Points

### Create Notification Examples

**Appointment Created**
```dart
await supabase.from('notifications').insert({
  'user_id': patientId,
  'user_role': 'patient',
  'title': 'Appointment Scheduled',
  'message': 'With Dr. ${doctorName} at ${time}',
  'type': 'appointment',
  'reference_id': appointmentId,
});
```

**Medication Reminder**
```dart
await supabase.from('notifications').insert({
  'user_id': patientId,
  'user_role': 'patient',
  'title': 'Medication Time',
  'message': 'Time to take ${medName}',
  'type': 'medication',
  'reference_id': medicationId,
});
```

**Wound Check**
```dart
await supabase.from('notifications').insert({
  'user_id': patientId,
  'user_role': 'patient',
  'title': 'Wound Check Due',
  'message': 'Upload your wound photos',
  'type': 'wound',
  'reference_id': metricId,
});
```

## 🎯 Features

✅ Fetch notifications by user
✅ Mark individual as read
✅ Mark all as read
✅ Real-time database sync
✅ Pull to refresh
✅ Type-specific colors
✅ Time-ago formatting
✅ Error handling
✅ Empty state
✅ Loading state
✅ Responsive design
✅ Accessible UI

## 🔐 Security

- Filters by user_id (user-specific data)
- Uses Supabase RLS (if configured)
- Validates user role
- Error messages don't expose data

## 🚀 To Get Started

1. Add test notifications to database
2. Click bell icon in app
3. See notifications display
4. Test mark as read
5. Integrate into your workflows

## 📞 Common Patterns

**In existing features:**
```dart
// After appointment creation
await supabase.from('notifications').insert({...});

// After medication schedule
await supabase.from('notifications').insert({...});

// After health metric submission
await supabase.from('notifications').insert({...});
```

---

**Implementation Complete** ✅
Ready for testing and integration!
