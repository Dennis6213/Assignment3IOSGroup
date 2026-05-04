# FlashcardsApp

A SwiftUI flashcard app with spaced repetition scheduling built using SwiftData.

## Features
- Create and manage flashcard decks
- SM-2 scheduling for review intervals
- Flip-card study sessions with self-grading
- Stats and streak tracking via Swift Charts
- JSON import for bulk card creation
- Daily review reminders

## Tech Stack
iOS 17+, SwiftUI, SwiftData, Swift Charts, UserNotifications

## JSON Import Format

```json
{
  "deck_name": "Deck Name",
  "description": "Optional",
  "cards": [
    {
      "front": "Question",
      "back": "Answer",
      "hint": "Optional hint"
    }
  ]
}
```

## Project Structure
```
FlashcardsApp/
├── Models/          Deck, Card, ReviewLog, Grade
├── Scheduler/       SM-2 algorithm
├── Persistence/     SwiftData setup, DeckRepository
├── Views/
│   ├── Decks/       DeckListView, DeckDetailView
│   ├── Cards/       CardEditorView
│   ├── Study/       StudySessionView, FlipCardView
│   └── Stats/       StatsView
├── Notifications/   ReminderScheduler
├── ImportExport/    JSONImporter, JSONExporter
└── Resources/       Sample JSON decks
```
