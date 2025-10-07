# Attendify

Attendify is a modern Flutter attendance tracker tailored for students who need to keep their overall attendance above the 75% threshold. The app focuses on quick daily logging, rich insights, and delightful interactions.

## ✨ Highlights

- **Smart dashboard** with personalised greeting, quick stats, calendar, and today’s classes.
- **Subject management** supporting colour-coded cards, credits, professors, and editing in modal sheets.
- **Weekly schedule builder** to design the timetable visually across all seven days.
- **Attendance marking flow** via touch-friendly bottom sheets with undo support.
- **Analytics hub** surfacing can-miss / need-to-attend calculations, weekly trends, and subject breakdowns.
- **Daily reminders** powered by local notifications and on-device storage with Hive.

## 🏗️ Tech Stack

- Flutter 3
- Riverpod for state management
- Hive for offline-first persistence
- Flutter Local Notifications + timezone for reminders
- Table Calendar for the weekly overview
- Google Fonts for typography polish

## 🚀 Getting Started

```powershell
# From the workspace root
Set-Location attendify
flutter pub get
flutter test
flutter run
```

> **Tip:** The project targets Android and iOS. For iOS, run `pod install` inside `ios/` after fetching dependencies.

## 📱 Feature Overview

### Dashboard
- Gradient header with greeting, date, overall attendance and at-risk count.
- Cards for today’s classes with quick mark buttons and status badges.
- Weekly calendar strip highlighting attendance streaks.
- Subject progress cards with colour bands, progress bars, and stat chips.
- Profile prompt and smart reminder controls.

### Subjects
- Rounded cards summarising each subject.
- Add/edit forms surfaced as modal bottom sheets.
- Palette of eight curated colours.

### Schedule
- Day chips for Monday–Sunday with intuitive selection.
- Class cards showing time range, venue, and quick actions.
- Validation that subjects exist before adding classes.

### Analytics
- Overview tile with held/attended/missed/extra counts and global percentage.
- Weekly trend mini chart.
- Per-subject analytics with “can miss” and “need to attend” counters.

## 🧪 Testing

Run the unit tests to validate attendance math and repository behaviour:

```powershell
flutter test
```

## 🤝 Contributing

Feel free to open issues or suggestions for new modules—attendance trends, predicted risk alerts, or integrations with college portals are great starting points.
