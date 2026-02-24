# FutPlanner Component Library

> Catálogo de componentes ya diseñados y disponibles para reutilización.
> Actualizado: Enero 2025

---

## Status Legend

- ✅ **Designed & Implemented** - Ready to use
- 🎨 **Designed Only** - In Stitch, pending implementation
- 📋 **Planned** - Not yet designed
- 🔄 **Needs Update** - Requires redesign

---

## Core Components

### Navigation

| Component | Status | Location | Platform |
|-----------|--------|----------|----------|
| Bottom Navigation Bar | 🎨 | `/doc/design/core/` | Mobile |
| Sidebar Navigation | 📋 | - | Web |
| Top App Bar | 🎨 | `/doc/design/core/` | Both |
| Breadcrumbs | 📋 | - | Web |

### Buttons & Actions

| Component | Status | Location | Platform |
|-----------|--------|----------|----------|
| Primary Button | 🎨 | `/doc/design/core/` | Both |
| Secondary Button | 🎨 | `/doc/design/core/` | Both |
| Ghost Button | 🎨 | `/doc/design/core/` | Both |
| FAB (Floating Action Button) | 🎨 | `/doc/design/core/` | Mobile |
| Icon Button | 🎨 | `/doc/design/core/` | Both |

### Forms & Inputs

| Component | Status | Location | Platform |
|-----------|--------|----------|----------|
| Text Input | 🎨 | `/doc/design/core/` | Both |
| Search Bar | 🎨 | `/doc/design/my_players/` | Both |
| Filter Chips | 🎨 | `/doc/design/my_players/` | Both |
| Dropdown Select | 📋 | - | Both |
| Date Picker | 📋 | - | Both |
| Toggle Switch | 🎨 | `/doc/design/my_players/` | Both |

### Feedback

| Component | Status | Location | Platform |
|-----------|--------|----------|----------|
| Snackbar/Toast | 🎨 | `/doc/design/core/` | Both |
| Loading Skeleton | 🎨 | `/doc/design/core/` | Both |
| Empty State | 🎨 | `/doc/design/core/` | Both |
| Error State | 📋 | - | Both |
| Pull to Refresh | 🎨 | `/doc/design/core/` | Mobile |

---

## Feature: Core / Auth

| Component | Status | Location | Notes |
|-----------|--------|----------|-------|
| Splash Screen | 🎨 | `/doc/design/core/` | Logo animation, dark bg |
| Login Screen | 🎨 | `/doc/design/core/` | Email/password, social |
| Register Screen | 📋 | - | Similar to login |

---

## Feature: Dashboard

| Component | Status | Location | Notes |
|-----------|--------|----------|-------|
| Dashboard Page | 🎨 | `/doc/design/core/` | Mobile version |
| Quick Stats Card | 🎨 | `/doc/design/core/` | Icon + value + label |
| Upcoming Event Card | 🎨 | `/doc/design/core/` | Countdown, type badge |
| Quick Actions Row | 🎨 | `/doc/design/core/` | Horizontal buttons |
| Activity Feed Item | 📋 | - | - |

---

## Feature: My Players

| Component | Status | Location | Notes |
|-----------|--------|----------|-------|
| Players List Page | 🎨 | `/doc/design/my_players/` | With search & filters |
| Player Card | 🎨 | `/doc/design/my_players/` | Photo, name, #, position, status |
| Player Detail Page | 🎨 | `/doc/design/my_players/` | Tabs: Info, Attendance, Stats |
| Player Stats Widget | 🎨 | `/doc/design/my_players/` | Games, attendance %, goals |
| Position Badge | 🎨 | `/doc/design/my_players/` | Line color coded |
| Status Indicator | 🎨 | `/doc/design/my_players/` | Available/Injured/Suspended |
| Add Player Form | 📋 | - | Multi-step or single |

---

## Feature: Attendance

| Component | Status | Location | Notes |
|-----------|--------|----------|-------|
| Attendance Tracker Page | 🎨 | `/doc/design/my_players/` | Session-based |
| Attendance Toggle Row | 🎨 | `/doc/design/my_players/` | Player + 4 status buttons |
| Attendance Summary | 🎨 | `/doc/design/my_players/` | 18/22 Present (82%) |
| Attendance History List | 📋 | - | Per player |

---

## Feature: Training / Calendar

| Component | Status | Location | Notes |
|-----------|--------|----------|-------|
| Calendar Page | 🎨 | `/doc/design/my_players/` | Week/month view |
| Calendar Event Item | 🎨 | `/doc/design/my_players/` | Color by type |
| Training Detail | 📋 | - | - |
| Add Training Form | 📋 | - | - |

---

## Feature: Match / Lineup

| Component | Status | Location | Notes |
|-----------|--------|----------|-------|
| Lineup Builder Page | 🎨 | `/doc/design/my_players/` | Full tactical board |
| Tactical Board | 🎨 | `/doc/design/my_players/` | Pitch + formation |
| Formation Selector | 🎨 | `/doc/design/my_players/` | Dropdown 4-3-3, etc |
| Player Pool List | 🎨 | `/doc/design/my_players/` | Draggable players |
| Position Marker | 🎨 | `/doc/design/my_players/` | Player on pitch |
| Substitutes Bench | 🎨 | `/doc/design/my_players/` | Below pitch |

---

## Feature: Opponents (Scouting)

| Component | Status | Location | Notes |
|-----------|--------|----------|-------|
| Opponents List Page | 🎨 | `/doc/design/my_players/` | Card grid |
| Opponent Card | 🎨 | `/doc/design/my_players/` | Logo, name, W-D-L |
| Opponent Detail Page | 📋 | - | History, notes |
| Match History Item | 📋 | - | Date, result, venue |
| Scouting Notes Editor | 📋 | - | Rich text |
| Add Opponent Form | 📋 | - | Logo upload |

---

## Feature: Communication

| Component | Status | Location | Notes |
|-----------|--------|----------|-------|
| Team Chat Page | 🎨 | `/doc/design/my_players/` | Group messages |
| Message Bubble | 🎨 | `/doc/design/my_players/` | Sent/received |
| Announcement Card | 📋 | - | - |
| Confirmation Request | 📋 | - | Training/match RSVP |

---

## Feature: Settings / Profile

| Component | Status | Location | Notes |
|-----------|--------|----------|-------|
| Settings Page | 📋 | - | - |
| Profile Header | 📋 | - | Photo, name, email |
| Settings Section | 📋 | - | Grouped options |
| Theme Toggle | 📋 | - | Dark/Light |
| Language Selector | 📋 | - | Spanish default |

---

## Design Patterns Reference

### List with Search & Filters
```
┌─────────────────────────┐
│ [🔍 Search...        ]  │ ← Sticky search
├─────────────────────────┤
│ [Chip] [Chip] [Chip] →  │ ← Horizontal scroll filters
├─────────────────────────┤
│ ┌─────────────────────┐ │
│ │     Card Item       │ │
│ └─────────────────────┘ │
│ ┌─────────────────────┐ │
│ │     Card Item       │ │
│ └─────────────────────┘ │
│          ...            │
├─────────────────────────┤
│         [FAB]           │ ← Bottom right
└─────────────────────────┘
```

### Detail Page with Tabs
```
┌─────────────────────────┐
│ ← Back       [Edit] [⋮] │ ← App bar
├─────────────────────────┤
│                         │
│    [  Photo/Header  ]   │ ← Collapsible
│      Name, Subtitle     │
│                         │
├─────────────────────────┤
│ [Tab1] [Tab2] [Tab3]    │ ← Tab bar
├─────────────────────────┤
│                         │
│      Tab Content        │
│                         │
└─────────────────────────┘
```

### Attendance Row
```
┌─────────────────────────────────────────┐
│ [Photo] Name              [✓][✗][⚠][⏱] │
└─────────────────────────────────────────┘
  44pt   flex                 44pt each
```

---

## How to Update This File

When a new component is designed in Stitch:

1. Download HTML to `/doc/design/{feature}/`
2. Update this file:
   - Change status from 📋 to 🎨
   - Add location path
   - Add notes if relevant

When a component is implemented:
1. Update status from 🎨 to ✅
