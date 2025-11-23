# Notifications Screen - UI/UX Reference

## Screen Layout

```
┌─────────────────────────────────────┐
│ ← [Logo]          [↻] [🔔 Active]   │ ← AppBar
├─────────────────────────────────────┤
│                                     │
│ "You have 2 unread notifications"   │ ← Unread count (if any)
│                                     │
├─────────────────────────────────────┤
│                                     │
│ ┌─────────────────────────────────┐ │
│ │ 📅 Appointment Reminder        ● │ ← Unread indicator
│ │    Your appointment with Dr.   │ │
│ │    Smith is tomorrow...         │ │
│ │    2h ago                       │ │
│ └─────────────────────────────────┘ │
│                                     │
│ ┌─────────────────────────────────┐ │
│ │ 💊 Take Your Medication         │ │
│ │    Remember to take your       │ │
│ │    insulin before dinner       │ │
│ │    5h ago                       │ │
│ └─────────────────────────────────┘ │
│                                     │
│ ┌─────────────────────────────────┐ │
│ │ 🏥 Wound Check                  │ │ ← Read notification (no indicator)
│ │    Time for your weekly wound   │ │
│ │    photo upload                 │ │
│ │    1d ago                       │ │
│ └─────────────────────────────────┘ │
│                                     │
└─────────────────────────────────────┘
```

## Notification Card Design

### Unread Notification (with border highlight)
```
┌─── Colored Left Border ────────────────┐
│ [Icon] Title                        ●  │
│ Box    Message text...                 │
│        Time ago                        │
└────────────────────────────────────────┘
```

### Read Notification (normal)
```
┌──────────────────────────────────────┐
│ [Icon] Title                           │
│ Box    Message text...                 │
│        Time ago                        │
└──────────────────────────────────────┘
```

## Color Palette

| Element | Hex Code | Usage |
|---------|----------|-------|
| Background | #F8FAFF | Page background |
| Card Background | #FFFFFF | Notification cards |
| Primary Blue | #1DA1F2 | AppBar, icons, links |
| Success Green | #19AC4A | Medication, positive actions |
| Alert Red | #E74C3C | Wound care, urgent |
| Purple | #9B59B6 | Patient info |
| Gray | #BDC3C7 | Timestamps, secondary text |
| Light Gray | #ECF0F1 | Read card borders |
| Dark Gray | #2C3E50 | Titles |

## Typography

| Element | Font | Weight | Size | Color |
|---------|------|--------|------|-------|
| Title | Poppins | 600 | 14px | Primary Blue |
| Message | Poppins | 400 | 13px | Gray |
| Timestamp | Poppins | 400 | 12px | Light Gray |
| Counter | Poppins | 600 | 14px | Primary Blue |

## Interactive States

### Notification Card
- **Idle**: Light gray border, white background
- **Unread**: Colored border (type-specific), white background, blue dot
- **Pressed**: Slight elevation increase
- **Tapped**: Transitions to read state with animation

### Buttons
- **Mark All Read**: Blue icon, responds to tap with success message
- **Refresh**: Blue icon, shows loading state during fetch
- **Back**: Blue icon, standard navigation behavior

## Empty State

```
┌─────────────────────────────────────┐
│                                     │
│                                     │
│         🔔 (Large Icon)             │
│      No notifications yet            │
│    Check back later for updates      │
│                                     │
│                                     │
└─────────────────────────────────────┘
```

## Error State

```
┌─────────────────────────────────────┐
│                                     │
│                                     │
│    ⚠️ (Error Icon - Red)            │
│   Error loading notifications       │
│   [Error message here]              │
│                                     │
│       [Retry Button]                │
│                                     │
│                                     │
└─────────────────────────────────────┘
```

## Loading State

```
┌─────────────────────────────────────┐
│                                     │
│                                     │
│          ◠ Loading...               │
│     (Circular progress indicator)   │
│                                     │
│                                     │
└─────────────────────────────────────┘
```

## Interaction Flow

```
User taps notification bell icon
            ↓
    NotificationsScreen loads
            ↓
    Check if already read
            ↓
    Yes → Display card (normal style)
    No  → Display card (highlighted, colored border)
            ↓
    User taps notification
            ↓
    Mark as read (API call)
    Update UI (remove highlight)
            ↓
    Card transitions to read state
```

## Responsive Behavior

- **Small phones (320px)**: Single column, full-width cards
- **Medium phones (375px+)**: Single column with 16px margins
- **Large phones (600px+)**: Single column with 24px side margins
- **Tablets (768px+)**: Could expand to 2 columns (future enhancement)

## Accessibility

- High contrast for text (WCAG AA compliance)
- Icons have semantic meaning
- Touch targets: 44x44 minimum
- Color not the only indicator (dot + border for unread)
- Relative time labels for better understanding
- Error messages are clear and actionable

## Performance

- Lazy loading notifications on scroll (future enhancement)
- Pagination for large notification lists (future enhancement)
- Cached data to minimize API calls
- Debounced refresh actions
