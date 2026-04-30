# DiaTrack

DiaTrack is a Flutter mobile app for diabetes-focused patient self-monitoring. It connects to Supabase for data storage and supports health metric submissions, medication tracking, appointment workflows, notifications, and surgical risk assessment.

## Overview

The app allows a patient to:

- Sign in and persist session data locally.
- Submit and edit health metrics (glucose, blood pressure, pulse, notes, and wound photos).
- View historical metrics through charts, overview cards, and searchable tables.
- Track scheduled medication doses by time of day and mark doses as taken.
- View notifications and mark one or all as read.
- Schedule, reschedule, and cancel appointments with doctor/secretary workflow support.
- Run a surgical risk assessment based on latest submitted data.

## Tech Stack

- Flutter (Dart)
- Supabase (database + storage)
- `supabase_flutter`
- `flutter_dotenv`
- `fl_chart`
- `image_picker`
- `shared_preferences`
- `intl`
- `http`

## Repository Layout

This repository contains documentation at the root and the Flutter app inside the `diatrack1/` folder.

- `diatrack1/lib/main.dart`: app bootstrap, environment loading, route setup
- `diatrack1/lib/screens/`: app screens (welcome/login/home/metrics/history/medication/notifications)
- `diatrack1/lib/services/supabase_service.dart`: Supabase operations and business workflows
- `diatrack1/lib/models/`: data models
- `diatrack1/lib/widgets/`: reusable UI widgets (charts, cards, dialogs, tables)
- `diatrack1/assets/`: images/fonts

## Core Features

### 1) Authentication and Session

- Patient sign-up and login via Supabase tables.
- Session-related patient fields cached with `SharedPreferences`.
- App route decides whether to show dashboard or welcome/login based on saved patient state.

### 2) Health Metrics Submission

- Add or edit:
  - Blood glucose
  - Blood pressure (systolic/diastolic)
  - Pulse rate
  - Notes
  - Wound photo (camera/gallery)
- Stores entries in `health_metrics`.
- Automatically classifies blood pressure category.
- Supports upload/delete of images in Supabase Storage.

### 3) Health History and Visualization

- Overview tab with summary cards and visual trends.
- Blood glucose chart and blood pressure chart.
- Wound photo gallery and detail view.
- Tabular history with search/filter/export style workflows.

### 4) Medication Tracking

- Pulls medication schedule for the current date.
- Groups by time of day (morning/noon/dinner).
- Allows marking schedule items as taken.

### 5) Notifications

- Fetch notifications for current patient.
- Mark individual notifications as read.
- Mark all notifications as read.
- Notification navigation by type (`appointment`, `medication`, `wound`, `patient`).
- Home screen displays unread notification count.

### 6) Appointment Management

- Fetches next upcoming appointment with doctor/secretary details.
- Create appointment with slot-availability validation.
- Reschedule appointment with conflict checking.
- Cancel appointment.
- Creates corresponding notification/audit entries when appointment actions occur.

### 7) Surgical Risk Assessment

- Builds a request payload from patient and latest metric data.
- Calls remote risk API endpoint.
- Stores/returns risk category and displays result screen.

## Environment Variables

The app expects a `.env` file in `diatrack1/.env` and loads it at startup.

Required keys:

- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`

If these values are missing, app startup throws an exception.

## Getting Started

### Prerequisites

- Flutter SDK installed and on PATH
- A configured Android/iOS emulator or physical device
- Supabase project with matching schema and storage buckets

### Setup

1. Clone the repository.
2. Move to the app folder:
   - `cd diatrack1`
3. Install dependencies:
   - `flutter pub get`
4. Create/update `.env` inside `diatrack1/` with required keys.
5. Run the app:
   - `flutter run`

### Build Examples

- Android APK: `flutter build apk`
- iOS (macOS only): `flutter build ios`

## Data and Backend Notes

The app integrates with several Supabase tables and storage buckets, including:

- Tables (used by app code):
  - `patients`
  - `doctors`
  - `health_metrics`
  - `appointments`
  - `notifications`
  - `medication_frequencies`
  - `medication_schedules`
  - `secretary_doctor_links`
  - `audit_logs`
  - `doctor_unavailable_dates`
- Storage buckets (referenced by service logic):
  - `wound-photos`
  - `patient-profile`

Ensure your Supabase schema and policies are aligned with these operations.

## Key App Flow

1. Launch app and load `.env`.
2. Initialize Supabase.
3. Restore saved patient from local preferences.
4. If saved patient exists, go to dashboard (`HomeScreen`); otherwise show onboarding/login.
5. Patient can navigate to metrics, history, medication, and notifications screens.

## Testing

Default Flutter test scaffold is located at:

- `diatrack1/test/widget_test.dart`

Run tests with:

- `flutter test`

## Troubleshooting

- Startup fails with configuration error:
  - Verify `.env` exists in `diatrack1/` and contains valid `SUPABASE_URL` and `SUPABASE_ANON_KEY`.
- Image upload errors:
  - Confirm storage buckets exist and access policies permit upload/read/delete.
- Empty data on screens:
  - Verify patient ID mapping and table relationships in Supabase.
- Appointment scheduling conflict messages:
  - This is expected when requested slot overlaps an existing appointment window.

## Notes

- Current implementation uses direct patient credential checks against the `patients` table and not Supabase Auth.
- Keep secrets out of source control; use environment files and secure secret management in CI/CD.

## License

No license file is currently defined in this repository.
