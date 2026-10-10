# Workout Fitness Logger

An Apple Fitness-style workout logging app built with Flutter, designed for quick entry, visually satisfying progress, and a clean social-media reel demo flow.

This app is intended to be filmed as a short demo reel: a single tap to log, an immediate visual payoff in the chart/rings, and a polished dark interface with subtle motion.

## Design direction

- Dark, space-inspired surface palette with soft glassy cards
- Apple Fitness-inspired activity rings module for today's progress
- Motion-forward cards and charts with gentle entrances and scaling
- Metric-aware logging: move, exercise, stand, active minutes, steps, weight, and more
- Quick type selection, fast numeric entry, optional note
- Progress page with animated bar charts, trend deltas, and export/share
- History page as a clean chronological timeline with metric chips and notes

## Screens

- `/` Home — activity rings, today summary tiles, quick actions, recent activity
- `/log` Log — fast contextual workout entry with type chips, duration, value, metric toggle, note
- `/progress` Progress — animated charts, metric switching, weekly view, trend and highlights
- `/history` History — grouped timeline by day with metric chips and notes

## Architecture

- Clean feature-based layout under `lib/features/`
- Riverpod for state and async data
- GoRouter for navigation with simple page transitions
- Local JSON file storage for entries via `WorkoutStorage`
- Domain models in `lib/features/workout/domain/`
- Shared UI primitives in `lib/shared/widgets/`

## Dependencies

- Flutter SDK
- fl_chart
- intl
- path_provider
- uuid
- json_annotation
- equatable
- flutter_riverpod
- go_router
- shimmer
- flutter_animate
- table_calendar
- share_plus

## Getting started

From the project root:

```bash
flutter pub get
flutter run
```

For iOS:

```bash
flutter run -d ios
```

For Android:

```bash
flutter run -d android
```

## Demo notes

For the best reel result:

- preload some demo entries so charts and rings are not empty
- show one quick log action and then the immediate progress update
- keep the framing tight on the phone screen with a clean background
- use gentle motion in the UI; avoid cluttered backgrounds

## Future improvements

- Calendar-based history and week/month navigation
- Goals and custom daily targets
- Charts for multiple metrics side by side
- Sync support or cloud backup
- Watch-style haptic and quick log interactions
