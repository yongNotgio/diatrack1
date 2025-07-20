# DiaTrack - Health Metrics History

A comprehensive Flutter application for diabetes management and health monitoring, featuring a detailed health metrics history interface.

## Features

### Health Metrics History Screen

The health metrics history screen provides a comprehensive view of patient health data with the following features:

#### Overview Tab
- **Overview Cards**: Display average blood glucose, blood pressure (systolic/diastolic), and risk classification
- **Blood Sugar Chart**: Interactive line chart showing blood glucose trends over the past week
- **Blood Pressure Chart**: Bar chart displaying systolic and diastolic pressure over the past month
- **Wound Photos Section**: Grid display of wound photos with date/time information
- **Health Metrics Submissions**: Detailed list of all health metric entries with edit/delete functionality

#### Tables Tab
- **Search Functionality**: Real-time search across all metrics
- **Filter & Export**: Advanced filtering and data export capabilities
- **Blood Glucose Table**: Tabular view of blood glucose readings
- **Blood Pressure Table**: Tabular view of blood pressure readings
- **Risk Classification Table**: Tabular view of risk classifications

### Key Features

1. **Real-time Data**: All data is fetched from Supabase database in real-time
2. **Interactive Charts**: Built with fl_chart for smooth, interactive data visualization
3. **Responsive Design**: Optimized for mobile devices with clean, modern UI
4. **Error Handling**: Comprehensive error handling with user-friendly messages
5. **Data Management**: Full CRUD operations for health metrics
6. **Image Support**: Wound photo gallery with full-screen viewing capability

## Project Structure

```
lib/
├── models/
│   └── health_metric.dart          # Health metric data model
├── services/
│   └── supabase_service.dart       # Database operations
├── utils/
│   └── date_formatter.dart         # Date formatting utilities
├── widgets/
│   ├── overview_cards.dart         # Overview metrics cards
│   ├── blood_sugar_chart.dart      # Blood glucose chart widget
│   ├── blood_pressure_chart.dart   # Blood pressure chart widget
│   ├── wound_photos_section.dart   # Wound photos display
│   └── metrics_table.dart          # Data tables widget
└── screens/
    └── health_metrics_history.dart # Main history screen
```

## Dependencies

- `flutter`: Core Flutter framework
- `supabase_flutter`: Backend database and authentication
- `fl_chart`: Interactive charts and graphs
- `image_picker`: Image selection and upload
- `intl`: Internationalization and date formatting
- `shared_preferences`: Local data storage
- `dotted_border`: UI styling
- `flutter_dotenv`: Environment variable management

## Database Schema

The application uses the following Supabase table structure:

### health_metrics
- `id`: Primary key
- `patient_id`: Foreign key to patients table
- `blood_glucose`: Blood glucose reading (mg/dL)
- `bp_systolic`: Systolic blood pressure (mmHg)
- `bp_diastolic`: Diastolic blood pressure (mmHg)
- `pulse_rate`: Heart rate (bpm)
- `wound_photo_url`: URL to wound photo
- `food_photo_url`: URL to food photo
- `notes`: Additional notes
- `submission_date`: Date and time of submission
- `updated_at`: Last update timestamp

## Getting Started

1. Clone the repository
2. Install dependencies: `flutter pub get`
3. Configure Supabase credentials in `.env` file
4. Run the application: `flutter run`

## Usage

### Health Metrics History

1. **Overview Tab**: View summary metrics and charts
   - Overview cards show averages and risk classification
   - Blood sugar chart displays weekly trends
   - Blood pressure chart shows monthly data
   - Wound photos are displayed in a grid format

2. **Tables Tab**: Detailed data tables
   - Search functionality for quick data access
   - Filter and export options
   - Separate tables for glucose, pressure, and risk data

3. **Data Management**:
   - Edit existing metrics
   - Delete metrics with confirmation
   - Real-time data refresh

### Charts and Visualizations

- **Blood Sugar Chart**: Line chart with interactive tooltips
- **Blood Pressure Chart**: Bar chart with systolic/diastolic comparison
- **Responsive Design**: Charts adapt to different screen sizes

### Image Management

- **Wound Photos**: Grid display with date/time information
- **Gallery View**: Full-screen photo viewing
- **Error Handling**: Graceful handling of missing images

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For support and questions, please contact the development team or create an issue in the repository.
