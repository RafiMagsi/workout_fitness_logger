# Workout Logger — beginner blueprint

This project is a small fitness logging app focused on a fast, satisfying demo. It is not trying to be a full fitness platform. The goal is a polished, minimal app that looks great on video.

## What it does

- Log workouts quickly by choosing a type and entering duration and a value.
- Track different metrics: calories moved, exercise minutes, stand hours, active minutes, steps, weight, and more.
- Show today's activity through an Apple Fitness-style rings summary.
- Show progress over time with animated charts.
- Show a clean history grouped by day.

## What makes it feel modern

- Dark background with soft glassy cards.
- Gentle motion on key widgets.
- Clear accent colors used sparingly for focus.
- Metric-aware entries so the same log screen can support different kinds of tracking.
- A demo-friendly flow where the user logs once and immediately sees the result.

## Where to look first

- `lib/main.dart` — app entry point and router wiring
- `lib/core/theme/app.dart` — visual design tokens
- `lib/features/workout/presentation/pages/home_page.dart` — main home experience
- `lib/features/workout/presentation/pages/log_page.dart` — log flow
- `lib/features/progress/presentation/pages/progress_page.dart` — charts and trends
- `lib/features/history/presentation/pages/history_page.dart` — history timeline
- `lib/features/workout/data/workout_storage.dart` — local persistence and demo seeds
- `lib/shared/widgets/activity_rings.dart` — rings widget used on home
- `lib/shared/widgets/glass_card.dart` — shared card primitives

## How the demo flow works

1. The app starts with a few seeded entries so the rings and charts are not empty.
2. The user taps + and picks an exercise type.
3. The user enters duration and a value.
4. The entry is saved to local storage.
5. The home or progress screen immediately reflects the new entry.

## Simple extension ideas

- Add goals and daily targets.
- Add a week or month selector for progress.
- Add body measurement tracking.
- Add export to CSV or share.
- Add calendar-based history navigation.
