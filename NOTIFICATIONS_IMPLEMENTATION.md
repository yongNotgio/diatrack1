# Notifications/Reminders Feature - Implementation Guide

## Overview
A complete notifications/reminders system has been implemented for the DiaTrack application. Users can now view all notifications addressed to them, organized by recency, with the ability to mark them as read.

## Files Created/Modified

### 1. **New Model: `lib/models/notification.dart`**
   - `NotificationModel` class with fields:
     - `notificationId`: Unique identifier
     - `userId`: Target user
     - `userRole`: User type (doctor, secretary, patient)
     - `title`: Notification title
     - `message`: Notification message
     - `type`: Category (appointment, medication, wound, patient)
     - `referenceId`: Reference to related data
     - `createdAt`: Timestamp
     - `isRead`: Read status
   - Includes factory constructor `fromMap()` and helper methods

### 2. **New Screen: `lib/screens/notifications_screen.dart`**
   - Comprehensive notifications display interface
   - **Features:**
     - Real-time notification fetching from database
     - Pull-to-refresh functionality
     - Unread notification counter
     - Color-coded notifications by type
     - Time-ago formatting (e.g., "5m ago", "2h ago")
     - Mark individual notifications as read
     - Mark all notifications as read
     - Empty state with icon and message
     - Error handling with retry button
     - Responsive design matching app's color scheme

   - **Design Elements:**
     - Color scheme aligned with existing app (Blue: `#1DA1F2`, Green: `#19AC4A`, Red: `#E74C3C`, Purple: `#9B59B6`)
     - Icons for each notification type
     - Light background color matching app (`#F8FAFF`)
     - Poppins font family throughout
     - Smooth animations and transitions

### 3. **Updated Service: `lib/services/supabase_service.dart`**
   Added three new methods:
   
   ```dart
   // Fetch notifications for a specific user
   Future<List<Map<String, dynamic>>> getNotifications(String userId)
   
   // Mark a single notification as read
   Future<void> markNotificationAsRead(String notificationId)
   
   // Mark all notifications as read for a user
   Future<void> markAllNotificationsAsRead(String userId)
   ```

### 4. **Updated Screens with Navigation**
   Modified notification bell icons in the following screens to navigate to `NotificationsScreen`:
   - `lib/screens/home_screen.dart`
   - `lib/screens/medication.dart`
   - `lib/screens/health_metrics_history.dart`
   - `lib/screens/add_metrics_screen.dart`

## Database Integration

The implementation uses the existing `notifications` table in Supabase with the following schema:

```sql
CREATE TABLE public.notifications (
  notification_id uuid NOT NULL DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL,
  user_role text NOT NULL CHECK (user_role = ANY (ARRAY['doctor'::text, 'secretary'::text, 'patient'::text])),
  title text NOT NULL,
  message text NOT NULL,
  type text CHECK (type = ANY (ARRAY['appointment'::text, 'patient'::text, 'medication'::text, 'wound'::text])),
  reference_id uuid,
  created_at timestamp with time zone DEFAULT now(),
  is_read boolean DEFAULT false,
  CONSTRAINT notifications_pkey PRIMARY KEY (notification_id)
);
```

## How to Use

### For Users
1. Click the bell icon (🔔) in the AppBar of any screen
2. View all notifications sorted by most recent first
3. Unread notifications are highlighted with a colored border and dot indicator
4. Tap a notification to mark it as read
5. Tap the "mark all as read" icon to mark all notifications at once
6. Pull down to refresh the notification list

### For Developers - Sending Notifications

To send notifications programmatically, insert into the `notifications` table:

```dart
await supabase.from('notifications').insert({
  'user_id': patientId,
  'user_role': 'patient',
  'title': 'Appointment Reminder',
  'message': 'Your appointment with Dr. Smith is tomorrow at 2:00 PM',
  'type': 'appointment',
  'reference_id': appointmentId, // Optional
});
```

## Notification Types & Colors

| Type | Color | Icon | Usage |
|------|-------|------|-------|
| appointment | Blue `#1DA1F2` | 📅 | Appointment reminders |
| medication | Green `#19AC4A` | 💊 | Medication alerts |
| wound | Red `#E74C3C` | 🏥 | Wound care notifications |
| patient | Purple `#9B59B6` | 👤 | Patient-related updates |

## Time Formatting

Notifications display relative time:
- Less than 1 minute: "Just now"
- Less than 1 hour: "Xm ago"
- Less than 24 hours: "Xh ago"
- Less than 7 days: "Xd ago"
- Over 7 days: "MMM d, yyyy" format

## Design Consistency

The notification screen maintains design consistency with the rest of the application:
- White AppBar with DiaTrack logo
- Light blue background (`#F8FAFF`)
- Poppins font family
- Rounded corners (12px radius)
- Subtle shadows for depth
- Icon buttons with blue tint (`#1DA1F2`)
- Green success states (`#19AC4A`)

## Error Handling

- Network errors display with retry button
- Failed operations show user-friendly messages
- Empty state guidance when no notifications exist
- Try-catch blocks prevent app crashes

## Future Enhancements

Potential improvements for future releases:
- Push notifications for real-time alerts
- Notification categories/filters
- Notification history archival
- Snooze notifications
- Notification preferences/settings
- Notification sound/vibration options
- Bulk delete notifications
- Search notifications
