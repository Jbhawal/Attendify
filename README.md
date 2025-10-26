# Attendify

**Version 1.0.0**

Attendify is a modern Flutter attendance tracker designed for students to track attendance with required thresholds. The app features quick daily logging, multi-class support, rich insights, and smart notifications- all with a clean, portrait-optimized interface.

## ✨ Key Features

- **Multi-class tracking** - Track multiple classes per day with custom count support
- **Extra classes & mass bunks** - Proper handling of extra classes and mass bunk scenarios with customizable rules
- **Smart dashboard** - Personalized greeting, quick stats, calendar, and today's classes at a glance
- **Subject management** - Color-coded cards with credits, professor names, and easy editing
- **Weekly schedule** - Visual timetable builder across all seven days with class count display
- **Attendance marking** - Touch-friendly bottom sheets with undo support and past attendance marking
- **Unscheduled marking** - Mark attendance even on days without scheduled classes
- **Analytics hub** - Can-miss/need-to-attend calculations, weekly trends, consistency tracker, and subject breakdowns
- **Calendar view** - Full attendance history with gradient bubbles and class count details
- **Daily reminders** - Smart notifications powered by flutter_local_notifications

## 🚀 Getting Started

```powershell
# From the workspace root
Set-Location attendify
flutter pub get
flutter test
flutter run
```

```

> **Note:** The app is optimized for Android. Portrait orientation is locked for the best user experience.

## 📱 Feature Details

### Dashboard
- Gradient header with personalized greeting, date, overall attendance, and at-risk count
- Today's classes with quick mark buttons and status badges
- Weekly calendar strip highlighting attendance patterns
- Subject progress cards with gradient indicators, progress bars, and comprehensive stat chips
- Profile settings and smart reminder toggle

### Subjects
- Expandable cards showing held, attended, missed, extra, and mass bunk counts
- Quick actions for marking attendance and viewing full history
- Add/edit forms in modal bottom sheets
- Color palette with eight curated options
- Complete deletion of subjects including all schedules and attendance records

### Schedule
- Day selector for Monday–Sunday with intuitive navigation
- Class cards displaying time range, venue, class count, and quick actions
- Subject validation before adding classes
- Support for multiple classes per time slot

### Attendance Marking
- Present, absent, no class, extra class, and mass bunk status options
- Date range selection for bulk marking
- Unscheduled day marking with custom class count
- Past attendance restricted to today and earlier dates
- Notes field for additional context
- Extra class markers (EXTRA_ATTENDED, EXTRA_MISSED, EXTRA_MB)

### Analytics
- Overall statistics with held/attended/missed/extra counts and percentage
- Consistency tracker with current and best streaks
- Weekly attendance trend visualization
- Per-subject analytics with "can miss" and "need to attend" calculations
- Subject-wise breakdown with gradient progress indicators

### Settings & Profile
- User profile with avatar and name customization
- Mass bunk rule configuration (present/cancelled/absent)
- Attendance threshold setting (50-95%)
- Smart daily reminder with customizable time
- FAQ and app information

## 🧪 Testing

Run the comprehensive unit tests to validate attendance calculations and repository behavior:

```powershell
flutter test
```

Coverage includes:
- Attendance percentage calculations
- Multi-class count tracking
- Mass bunk rule application
- Streak calculations
- Can-miss/need-to-attend logic

## 📦 Building

Build release APK:
```powershell
flutter build apk
```

The APK will be available at: `build\app\outputs\flutter-apk\app-release.apk`

## 🤝 Contributing

Contributions welcome! Feel free to open issues or submit pull requests for:
- New features (predicted risk alerts, college portal integrations, etc.)
- UI/UX improvements
- Bug fixes
- Documentation enhancements

## 📄 License

This project is available for personal and educational use.
Made with ❤️ by Joyita.
