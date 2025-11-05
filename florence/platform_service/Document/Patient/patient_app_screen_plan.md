# BioTective Patient Dashboard - Complete Screen Layout Plan

## 📱 Cross-Platform Design Philosophy

### Core Principles
1. **Mobile-First Design** - Start with mobile layouts, scale up to web
2. **Responsive Breakpoints**:
   - **Mobile**: < 600px (Phone portrait)
   - **Tablet**: 600px - 1024px (Phone landscape, tablets)
   - **Desktop**: > 1024px (Laptops, desktops)
3. **Navigation Patterns**:
   - **Mobile/Tablet**: Bottom navigation bar (5 tabs)
   - **Desktop**: Side navigation drawer (expandable)
4. **Layout Patterns**:
   - **Mobile**: Single column, stacked cards
   - **Tablet**: 2-column grid where appropriate
   - **Desktop**: 3-column grid, side panels

---

## 🗂️ Screen Hierarchy & Structure

```
ROOT
├── Authentication Flow (No Navigation)
│   ├── 1. Splash Screen
│   ├── 2. Login Screen
│   ├── 3. Register Screen
│   └── 4. Onboarding Flow (3 pages)
│
└── Main App (With Bottom/Side Navigation)
    ├── TAB 1: Home/Dashboard
    │   ├── 5. Dashboard Screen (Main)
    │   └── Modal: Quick Log Overlay
    │
    ├── TAB 2: Trends & Analytics
    │   ├── 6. Trends Overview Screen
    │   ├── 7. Glucose Trends Detail Screen
    │   ├── 8. Meal Impact Screen
    │   ├── 9. Activity Impact Screen
    │   └── 10. Weekly Report Screen
    │
    ├── TAB 3: Log Data (Modal/Center Action)
    │   ├── 11. Log Glucose Screen
    │   ├── 12. Log Meal Screen
    │   ├── 13. Log Activity Screen
    │   └── 14. Log Medication Screen
    │
    ├── TAB 4: AI Assistant
    │   ├── 15. Chat Screen
    │   ├── 16. Recommendations Feed
    │   └── 17. Recommendation Detail Screen
    │
    └── TAB 5: Profile & More
        ├── 18. Profile Screen
        ├── 19. Settings Screen
        ├── 20. Notifications Screen
        ├── 21. Calendar View Screen
        ├── 22. Achievements Screen
        ├── 23. Education Library Screen
        └── 24. Help & Support Screen
```

---

## 📄 Detailed Screen Specifications

### **PHASE 1: Authentication Flow** (4 Screens)

#### **1. Splash Screen**
**Purpose**: App initialization and auth check  
**Layout**: Centered logo and loading indicator

**Components**:
- App logo (animated)
- Loading spinner
- App version number

**Mobile/Web Layout**: Same for both (centered)

**Navigation**: 
- If authenticated → Dashboard
- If not authenticated → Login

---

#### **2. Login Screen**
**Purpose**: User authentication  
**Layout**: Centered form

**Components**:
- App logo
- Email input field
- Password input field (with show/hide toggle)
- "Forgot Password?" link
- Login button (full width)
- "Don't have an account? Register" link

**Responsive Layout**:
- **Mobile**: Full width form with padding
- **Desktop**: Centered card (max-width: 400px) with shadow

**Form Validation**:
- Email format validation
- Password minimum length (8 chars)
- Error messages below fields

**Navigation**: 
- Success → Dashboard
- "Register" → Register Screen

---

#### **3. Register Screen**
**Purpose**: New user account creation  
**Layout**: Scrollable form

**Components**:
- Back button
- First name input
- Last name input
- Email input
- Password input (with strength indicator)
- Confirm password input
- Terms & conditions checkbox
- Register button
- "Already have an account? Login" link

**Responsive Layout**:
- **Mobile**: Scrollable full-width form
- **Desktop**: Centered card (max-width: 450px)

**Form Validation**:
- All fields required
- Email format validation
- Password matching validation
- Password strength indicator (weak/medium/strong)

**Navigation**: 
- Success → Onboarding Flow
- "Login" → Login Screen

---

#### **4. Onboarding Flow** (3 pages)
**Purpose**: First-time user introduction  
**Layout**: Swipeable full-screen pages

**Page 1: Welcome**
- Large icon (heart/health symbol)
- Title: "Welcome to BioTective"
- Description: "Your personal health companion for managing chronic diseases"
- "Next" button

**Page 2: Features**
- Icon: Chart/analytics
- Title: "Track Your Health"
- Description: "Log glucose, meals, activities, and medications easily"
- "Next" button
- "Skip" button

**Page 3: AI Assistant**
- Icon: Brain/AI symbol
- Title: "AI-Powered Insights"
- Description: "Get personalized recommendations powered by AI"
- "Get Started" button

**Responsive Layout**:
- **Mobile**: Full screen vertical layout
- **Desktop**: Centered content (max-width: 600px)

**Navigation**: "Get Started" → Profile Setup (or Dashboard)

---

### **PHASE 2: Main Dashboard (TAB 1)** (1 Screen + 1 Modal)

#### **5. Dashboard Screen (Home)**
**Purpose**: At-a-glance health overview  
**Layout**: Scrollable card-based layout

**Components** (in order):

1. **Header Section**
   - Greeting: "Good morning, [Name]"
   - Current date
   - Notification bell icon (with badge)

2. **Current Glucose Status Card** (Hero Card)
   - Latest glucose reading (large number)
   - Unit (mg/dL)
   - Status indicator (Low/Normal/High) with color
   - Time since reading
   - Color-coded background (green/yellow/red)

3. **Today's Quick Stats Row** (3 cards)
   - Average glucose today
   - Meals logged (2/3)
   - Activity minutes (45/60)

4. **Quick Log Actions Grid** (4 buttons)
   - Log Glucose (red icon)
   - Log Meal (orange icon)
   - Log Activity (green icon)
   - Log Medication (blue icon)

5. **AI Insight Card** (Featured Recommendation)
   - Purple gradient background
   - Lightbulb icon
   - Title: "Today's Insight"
   - Recommendation text (truncated)
   - Tap to expand

6. **Upcoming Reminders List** (max 3 items)
   - Icon + reminder text + time
   - "View all" link if more than 3

7. **Active Alerts** (if any)
   - Warning/critical alerts
   - Dismissible

**Responsive Layout**:
- **Mobile**: 
  - Single column
  - Cards stack vertically
  - Quick stats: 3 columns in a row
  - Quick actions: 2x2 grid

- **Tablet**: 
  - 2-column layout for stats
  - Quick actions: 4 in a row

- **Desktop**:
  - 3-column grid
  - Hero card spans 2 columns
  - Sidebar for reminders

**Interactions**:
- Pull to refresh
- Tap quick actions → Opens logging modal
- Tap AI insight → Opens recommendation detail
- Tap reminder → Shows reminder detail

---

#### **Quick Log Modal** (Overlay)
**Purpose**: Fast data logging without navigation  
**Layout**: Bottom sheet (mobile) or centered modal (desktop)

**Components**:
- Title: "Quick Log"
- 4 large action buttons with icons:
  - Log Glucose
  - Log Meal
  - Log Activity
  - Log Medication
- Close button (X)

**Responsive Layout**:
- **Mobile**: Bottom sheet slides up (70% screen height)
- **Desktop**: Centered modal (400x500px)

**Navigation**: Each button → Respective logging screen

---

### **PHASE 3: Trends & Analytics (TAB 2)** (5 Screens)

#### **6. Trends Overview Screen**
**Purpose**: Visualize glucose trends and statistics  
**Layout**: Scrollable with multiple chart sections

**Components** (in order):

1. **Header**
   - Title: "Health Trends"
   - Export button (PDF/CSV)

2. **Time Period Selector**
   - Horizontal scrollable chips
   - Options: Today | 3 Days | Week | 2 Weeks | Month | 3 Months | Custom
   - Currently selected is highlighted

3. **Glucose Line Chart Card**
   - Title: "Glucose Levels"
   - Line chart with target range shaded
   - Color-coded data points (green/yellow/red)
   - X-axis: Time
   - Y-axis: Glucose (mg/dL)
   - Interactive: Tap points to see details

4. **Time in Range Card**
   - Pie/donut chart
   - Percentages: In Range (green) | Above (red) | Below (yellow)
   - Legend with percentages

5. **Statistics Summary Card**
   - Grid layout (2x2 or 2x3):
     - Average glucose
     - Standard deviation
     - Estimated HbA1c
     - Total readings
     - Highest reading
     - Lowest reading

6. **AI Pattern Insights Card**
   - Blue info box
   - Icon: Lightbulb
   - Text: AI-detected patterns
   - Example: "Your glucose is most stable on weekdays"

7. **Detailed Analysis Buttons**
   - "Meal Impact Analysis" → Screen 8
   - "Activity Impact Analysis" → Screen 9
   - "Weekly Report" → Screen 10

**Responsive Layout**:
- **Mobile**: 
  - Single column
  - Charts: Full width
  - Stats: 2-column grid

- **Tablet/Desktop**:
  - Charts side by side (2 columns)
  - Stats: 3-column grid
  - More chart real estate

**Interactions**:
- Swipe/scroll between time periods
- Pinch to zoom on charts (mobile)
- Hover to see data points (desktop)

---

#### **7. Glucose Trends Detail Screen**
**Purpose**: Deep dive into glucose data  
**Layout**: Full-screen chart view

**Components**:
- Back button
- Time period selector
- Full-screen line chart
- Daily average bar chart
- Pattern heatmap (day of week × hour of day)
- Export data button

**Responsive Layout**:
- **Mobile**: Vertical stack, swipe between charts
- **Desktop**: Multiple charts in grid, more data visible

---

#### **8. Meal Impact Screen**
**Purpose**: Analyze how different foods affect glucose  
**Layout**: Scrollable list + charts

**Components**:
- Title: "Meal Impact Analysis"
- Time period selector
- **Meal Response Chart**: Before/after glucose for each meal
- **Food Ranking List**:
  - Food name
  - Average glucose spike
  - Color indicator (low/medium/high impact)
- **Best/Worst Foods Section**
  - Top 5 best foods (green)
  - Top 5 worst foods (red)
- AI recommendations based on data

**Responsive Layout**:
- **Mobile**: List view, tap to expand
- **Desktop**: Split view (chart | list)

---

#### **9. Activity Impact Screen**
**Purpose**: Show how exercise affects glucose  
**Layout**: Similar to meal impact

**Components**:
- Title: "Activity Impact Analysis"
- Time period selector
- **Activity-Glucose Correlation Chart**
  - Line chart with activity markers
- **Activity List**:
  - Activity type
  - Average glucose drop
  - Duration
- **Activity Effectiveness Ranking**
  - Which activities lower glucose most
- Recommendations for optimal activity timing

**Responsive Layout**:
- **Mobile**: Vertical list
- **Desktop**: Chart + side panel

---

#### **10. Weekly Report Screen**
**Purpose**: Auto-generated weekly health summary  
**Layout**: Report-style document

**Components**:
- Week range (e.g., "Jan 15-21, 2025")
- **Overall Rating**: Excellent/Good/Needs Improvement
- **Glucose Control Summary**:
  - Average glucose
  - Time in range %
  - Trend (improving/stable/declining)
- **Best Day of the Week**
- **Most Challenging Day**
- **Top 3 Achievements**
  - 7-day logging streak ✓
  - 85% time in range ✓
  - 5 hours of activity ✓
- **Areas for Improvement** (3 items)
- **AI-Generated Summary** (paragraph)
- "Download PDF" button
- "Share with Clinician" button

**Responsive Layout**:
- **Mobile**: Single column, scrollable
- **Desktop**: A4-like layout (printable)

---

### **PHASE 4: Data Logging (TAB 3)** (4 Screens)

#### **11. Log Glucose Screen**
**Purpose**: Record glucose reading  
**Layout**: Form-based modal/screen

**Components**:
- Title: "Log Glucose"
- Close button
- **Glucose Value Input**
  - Large number input
  - Unit: mg/dL
  - Number keyboard
  - Visual indicator (low/normal/high) updates as typing
- **Context Selector** (choice chips)
  - Before Meal
  - After Meal
  - Bedtime
  - Random
  - Fasting
- **Date/Time Picker**
  - Defaults to now
  - Calendar icon to change
- **Notes Field** (optional)
  - Multiline text input
  - "Any additional notes..."
- **Photo Upload** (optional)
  - Camera icon
  - "Attach photo"
- **Save Button** (full width, prominent)

**Validation**:
- Value required
- Value must be 20-600 mg/dL
- Context required

**Responsive Layout**:
- **Mobile**: Bottom sheet modal (90% height)
- **Desktop**: Centered modal (500x700px)

**Success Action**:
- Show success toast
- Close modal
- Refresh dashboard

---

#### **12. Log Meal Screen**
**Purpose**: Record meal intake  
**Layout**: Form with photo option

**Components**:
- Title: "Log Meal"
- Close button
- **Meal Type Selector** (4 buttons)
  - Breakfast | Lunch | Dinner | Snack
- **Meal Description**
  - Multiline text input
  - "What did you eat?"
  - Placeholder: "e.g., Grilled chicken with rice and vegetables"
- **Photo Upload**
  - Large upload area with icon
  - "Upload meal photo"
  - Gallery or camera option
  - Multiple photos allowed
- **Estimated Carbs** (optional)
  - Number input
  - Unit: grams
- **Portion Size** (optional)
  - Dropdown: Small / Medium / Large / Extra Large
- **Date/Time Picker**
- **Notes Field** (optional)
- **Save Button**

**Validation**:
- Meal type required
- Description required

**Responsive Layout**:
- **Mobile**: Full screen, scrollable
- **Desktop**: Centered modal, larger photo preview

---

#### **13. Log Activity Screen**
**Purpose**: Record physical activity  
**Layout**: Form-based

**Components**:
- Title: "Log Activity"
- Close button
- **Activity Type Dropdown**
  - Walking, Running, Cycling, Swimming, Gym, Yoga, Sports, Housework, Other
- **Activity Name** (optional)
  - Text input
  - Example: "Morning jog in park"
- **Duration**
  - Number input
  - Unit: minutes
  - Stepper buttons (+/- 5 min)
- **Intensity Selector** (3 buttons)
  - Light | Moderate | Vigorous
  - Color coded
- **Date/Time Picker**
- **Additional Metrics** (optional, expandable)
  - Calories burned
  - Distance (km)
  - Steps
- **Notes Field** (optional)
- **Save Button**

**Validation**:
- Activity type required
- Duration required (> 0)
- Intensity required

**Responsive Layout**:
- **Mobile**: Modal or full screen
- **Desktop**: Compact modal

---

#### **14. Log Medication Screen**
**Purpose**: Record medication intake  
**Layout**: Simple form

**Components**:
- Title: "Log Medication"
- Close button
- **Medication Selector**
  - Dropdown of user's medications
  - "Add new medication" option
- **Dosage**
  - Text input
  - Example: "1 tablet" or "10 units"
- **Time Taken**
  - Time picker
  - Defaults to now
- **Date Picker**
- **Notes Field** (optional)
- **Save Button**

**If "Add new medication"**:
- Modal overlay:
  - Medication name
  - Type (Insulin, Oral, Injectable, Other)
  - Dosage
  - Schedule times (optional)
  - Save medication

**Validation**:
- Medication required
- Dosage required
- Time required

**Responsive Layout**:
- **Mobile**: Bottom sheet
- **Desktop**: Small centered modal

---

### **PHASE 5: AI Assistant (TAB 4)** (3 Screens)

#### **15. Chat Screen**
**Purpose**: AI-powered health assistant  
**Layout**: Chat interface

**Components**:

1. **Header**
   - Title: "AI Health Assistant"
   - Info icon (explains what AI can do)

2. **Suggested Questions** (top section)
   - Horizontal scrollable chips
   - Pre-written questions:
     - "Why did my glucose spike?"
     - "What should I eat for lunch?"
     - "How am I doing this week?"
     - "Explain my last recommendation"

3. **Chat Messages Area** (scrollable)
   - AI messages: Left-aligned, light gray bubble
   - User messages: Right-aligned, blue bubble
   - AI can include:
     - Text responses
     - Mini charts (inline)
     - Links to recommendations
     - Data references with timestamps

4. **Input Area** (bottom, fixed)
   - Text input field
   - Microphone icon (voice input)
   - Send button

**Message Types**:
- Text only
- Text + inline chart
- Text + data table
- Text + action buttons

**Responsive Layout**:
- **Mobile**: Full screen chat
- **Desktop**: Chat window (60% width) + sidebar with context

**Interactions**:
- Tap suggested question → Sends as message
- Scroll up to load history
- Tap chart in message → Expands
- Long press message → Copy text

---

#### **16. Recommendations Feed**
**Purpose**: List of all AI recommendations  
**Layout**: Filterable list

**Components**:

1. **Header**
   - Title: "Recommendations"
   - Filter button

2. **Filter Tabs**
   - Active | Completed | Dismissed
   - Count badges

3. **Recommendation Cards** (scrollable list)
   Each card contains:
   - Category icon (meal/activity/sleep/timing/lifestyle/medication)
   - Priority badge (Urgent/High/Medium/Low)
   - Title (bold)
   - Short explanation (2 lines, truncated)
   - Time generated ("2 hours ago")
   - Action buttons:
     - "Mark Done" (checkmark)
     - "Dismiss" (X)
     - "View Details" (tap whole card)

4. **Empty State**
   - If no recommendations:
     - Icon: Checkmark in circle
     - Text: "All caught up! No active recommendations"

**Responsive Layout**:
- **Mobile**: Single column list
- **Tablet**: 2-column grid
- **Desktop**: 3-column grid

**Interactions**:
- Swipe card (mobile) → Mark done or dismiss
- Tap card → Opens detail screen

---

#### **17. Recommendation Detail Screen**
**Purpose**: Full recommendation view  
**Layout**: Scrollable detail page

**Components**:
- Back button
- **Header**
  - Category icon (large)
  - Title
  - Priority badge
  - Date generated
- **Why This Matters Section**
  - Heading
  - Full explanation paragraph
  - Optional: Supporting chart/data
- **Action Steps Section**
  - Highlighted box (blue background)
  - Lightbulb icon
  - Step-by-step instructions
  - Bullet points or numbered list
- **Related Data Section** (optional)
  - "This recommendation is based on:"
  - List of data points with timestamps
  - Mini chart
- **Action Buttons** (bottom, fixed)
  - "Mark as Done" (green, full width)
  - "Dismiss" (text button)
  - "Snooze for 1 day" (text button)

**Responsive Layout**:
- **Mobile**: Full screen, scrollable
- **Desktop**: Centered column (max-width: 700px)

---

### **PHASE 6: Profile & More (TAB 5)** (7 Screens)

#### **18. Profile Screen**
**Purpose**: User account and health profile overview  
**Layout**: List-based menu

**Components**:

1. **Profile Header Card**
   - Avatar (circular)
   - Name
   - Email
   - Streak badge ("30-day streak 🔥")
   - Edit profile button

2. **Health Summary Card**
   - Diabetes Type
   - Target Range (70-180 mg/dL)
   - Latest HbA1c
   - Member Since date
   - Edit button

3. **Menu Items** (cards/list items)
   - Calendar View → Screen 21
   - Achievements → Screen 22
   - Education Library → Screen 23
   - Notifications → Screen 20
   - Settings → Screen 19
   - Help & Support → Screen 24

4. **Log Out Button**
   - Red text, bottom of screen
   - Confirmation dialog

**Responsive Layout**:
- **Mobile**: Full width cards
- **Desktop**: Centered column (max-width: 600px)

---

#### **19. Settings Screen**
**Purpose**: App configuration  
**Layout**: Grouped settings list

**Components**:

**Account Section**
- Change Password
- Email Preferences
- Two-Factor Authentication

**Health Profile Section**
- Update Health Information
- Diabetes Type
- Target Glucose Range
- Activity Goals
- Medications List

**App Preferences Section**
- Dark Mode (toggle)
- Glucose Units (mg/dL or mmol/L)
- Language
- Notifications Settings → Sub-screen

**Data & Privacy Section**
- Export My Data
- Data Sharing Preferences
- Privacy Policy
- Terms of Service

**About Section**
- App Version
- Check for Updates

**Responsive Layout**:
- **Mobile**: Scrollable list
- **Desktop**: Two-column layout

---

#### **20. Notifications Screen**
**Purpose**: View and manage all notifications  
**Layout**: Grouped list

**Components**:

1. **Header**
   - Title: "Notifications"
   - "Mark all as read" button
   - Filter button (All/Unread)

2. **Grouped Notifications**
   - **Today**
   - **Yesterday**
   - **This Week**
   - **Older**

3. **Notification Item**
   - Icon (type-based: reminder/alert/insight/achievement)
   - Title (bold if unread)
   - Message
   - Time
   - Unread dot indicator
   - Swipe to delete (mobile)

4. **Empty State**
   - Icon: Bell with checkmark
   - Text: "You're all caught up!"

**Notification Types**:
- Reminders (blue)
- Alerts (orange/red)
- Insights (purple)
- Achievements (green)
- Recommendations (teal)

**Responsive Layout**:
- **Mobile**: Full width list
- **Desktop**: Centered column with sidebar for filters

---

#### **21. Calendar View Screen**
**Purpose**: Visual overview of health data by date  
**Layout**: Calendar + daily detail

**Components**:

1. **Month/Year Selector**
   - < October 2025 >
   - "Today" button

2. **Calendar Grid**
   - Each day shows:
     - Date number
     - Color indicator (green/yellow/red) for glucose control
     - Dots for logged data (glucose/meal/activity/medication)
   - Current day highlighted
   - Selected day has border

3. **Selected Day Detail Panel** (below calendar)
   - Date (e.g., "Monday, Oct 22")
   - Summary stats:
     - Avg glucose
     - Meals logged
     - Activities
     - Medications taken
   - "View Details" button → Navigates to that day's data

4. **Legend**
   - Color meanings
   - Dot meanings

**Responsive Layout**:
- **Mobile**: Calendar full width, detail panel below
- **Desktop**: Calendar + sidebar detail panel

**Interactions**:
- Tap day → Shows detail panel
- Swipe left/right → Previous/next month (mobile)
- Hover day → Preview tooltip (desktop)

---

#### **22. Achievements Screen**
**Purpose**: Gamification and progress tracking  
**Layout**: Grid of achievement cards

**Components**:

1. **Header**
   - Title: "Achievements"
   - Total points: "2,450 points"
   - Current level: "Level 12"

2. **Progress Bar**
   - Visual progress to next level
   - "850 points to Level 13"

3. **Filter Tabs**
   - All | Unlocked | Locked

4. **Achievement Grid**
   Each achievement card:
   - Icon/badge (large)
   - Name
   - Description
   - Points value
   - Status: Unlocked (colored) or Locked (grayscale)
   - Date unlocked (if unlocked)

5. **Categories**
   - Consistency (logging streaks)
   - Glucose Control (time in range)
   - Activity (exercise goals)
   - Knowledge (education completed)
   - Engagement (app usage)

**Achievement Examples**:
- "First Steps" - Log your first glucose reading (10 pts)
- "Week Warrior" - 7-day logging streak (50 pts)
- "Month Master" - 30-day logging streak (200 pts)
- "Glucose Guardian" - 80% time in range for a week (100 pts)
- "Active Achiever" - 7 days of activity logs (75 pts)

**Responsive Layout**:
- **Mobile**: 2-column grid
- **Tablet**: 3-column grid
- **Desktop**: 4-column grid

**Interactions**:
- Tap achievement → Shows detail modal with description and date

---

#### **23. Education Library Screen**
**Purpose**: Health education resources  
**Layout**: Categorized content library

**Components**:

1. **Header**
   - Title: "Education Library"
   - Search bar

2. **Featured Content** (horizontal scroll)
   - Large cards with thumbnail images
   - Title overlay

3. **Categories** (expandable sections)
   - Understanding Diabetes
   - Nutrition Basics
   - Exercise Guidelines
   - Medication Management
   - Complications Prevention
   - Living Well with Diabetes

4. **Content Cards** (in each category)
   - Thumbnail image or icon
   - Type badge (Article/Video/Infographic/Quiz)
   - Title
   - Brief summary
   - Estimated read time
   - Completion checkmark (if completed)

5. **My Progress Section**
   - Articles read: 12/45
   - Videos watched: 5/20
   - Quizzes completed: 3/10
   - Progress bar

**Responsive Layout**:
- **Mobile**: Single column, stack cards
- **Tablet**: 2-column grid
- **Desktop**: 3-column grid + sidebar filters

**Interactions**:
- Tap content → Opens content viewer
- Mark as complete
- Bookmark for later

---

#### **24. Help & Support Screen**
**Purpose**: Get help and contact support  
**Layout**: FAQ + contact options

**Components**:

1. **Search Bar**
   - "How can we help?"

2. **Quick Actions** (buttons)
   - Contact Support
   - Report a Bug
   - Feature Request
   - FAQ

3. **FAQ Section** (expandable items)
   - "How do I log my glucose?"
   - "What if I miss a medication?"
   - "How accurate is the AI?"
   - "Can I share data with my doctor?"
   - "How do I export my data?"
   - Each item expands to show answer

4. **Contact Options**
   - Email Support
   - Live Chat (if available)
   - Phone: [Number]
   - Office Hours

5. **Resources**
   - User Guide (PDF)
   - Video Tutorials
   - Community Forum (external link)

**Responsive Layout**:
- **Mobile**: Single column
- **Desktop**: Two-column (FAQ | Contact options)

---

## 🎨 Cross-Platform Design Specifications

### **Navigation Patterns**

#### **Mobile Navigation** (< 600px)
```
┌─────────────────────────┐
│     Screen Content      │
│                         │
│                         │
│                         │
└─────────────────────────┘
┌───┬───┬───┬───┬───────┐
│ 🏠 │📊│ ➕ │💬│  👤   │
│Home│Trd│Log│AI│Profile│
└───┴───┴───┴───┴───────┘
```

#### **Desktop Navigation** (> 1024px)
```
┌──────┬──────────────────┐
│ 🏠   │                  │
│ 📊   │   Main Content   │
│ ➕   │                  │
│ 💬   │                  │
│ 👤   │                  │
│      │                  │
└──────┴──────────────────┘
```

### **Responsive Grid System**

#### **Mobile Layout**
- 4-column grid
- 8px gutters
- 16px margins

#### **Tablet Layout**
- 8-column grid
- 16px gutters
- 24px margins

#### **Desktop Layout**
- 12-column grid
- 24px gutters
- 48px margins

### **Typography Scale**

| Element | Mobile | Desktop |
|---------|--------|---------|
| H1 (Page Title) | 24px | 32px |
| H2 (Section) | 20px | 28px |
| H3 (Card Title) | 18px | 20px |
| Body | 14px | 16px |
| Caption | 12px | 14px |

### **Touch Targets**

- **Minimum**: 44x44 px (mobile)
- **Recommended**: 48x48 px
- **Desktop**: Can be smaller (32x32 px)

### **Spacing System**
- 4px base unit
- Scale: 4, 8, 12, 16, 24, 32, 48, 64

---

## 📊 Development Priority & Timeline

### **Sprint 1: Foundation** (Week 1-2)
- ✅ Screens 1-4: Authentication Flow
- ✅ Navigation system
- ✅ Theme setup
- ✅ Models & services

### **Sprint 2: Core Features** (Week 3-4)
- ✅ Screen 5: Dashboard
- ✅ Screens 11-14: Data Logging
- ✅ Basic data visualization

### **Sprint 3: Analytics** (Week 5-6)
- ✅ Screens 6-10: Trends & Analytics
- ✅ Charts implementation (fl_chart)
- ✅ Statistics calculation

### **Sprint 4: AI Features** (Week 7-8)
- ✅ Screens 15-17: AI Assistant & Recommendations
- ✅ Backend AI integration
- ✅ Chat interface

### **Sprint 5: Profile & Extras** (Week 9-10)
- ✅ Screens 18-24: Profile, Settings, etc.
- ✅ Gamification
- ✅ Education library

### **Sprint 6: Polish & Testing** (Week 11-12)
- ✅ Responsive testing on all devices
- ✅ Accessibility improvements
- ✅ Performance optimization
- ✅ Bug fixes
- ✅ User acceptance testing

---

## 🎯 Screen Complexity & Effort Estimation

| Screen | Complexity | Estimated Hours | Dependencies |
|--------|-----------|-----------------|--------------|
| 1. Splash | Low | 2 | Auth service |
| 2. Login | Low | 4 | Auth service, validation |
| 3. Register | Medium | 6 | Auth service, validation |
| 4. Onboarding | Low | 4 | - |
| 5. Dashboard | High | 16 | All services, multiple widgets |
| 6. Trends Overview | High | 12 | Charts, API, statistics |
| 7. Glucose Detail | Medium | 8 | Charts library |
| 8. Meal Impact | Medium | 8 | Data analysis |
| 9. Activity Impact | Medium | 8 | Data analysis |
| 10. Weekly Report | Medium | 10 | PDF generation |
| 11. Log Glucose | Medium | 6 | Form validation |
| 12. Log Meal | Medium | 8 | Image upload, validation |
| 13. Log Activity | Medium | 6 | Form validation |
| 14. Log Medication | Low | 4 | Form validation |
| 15. Chat | High | 14 | API integration, real-time |
| 16. Recommendations | Medium | 8 | List management |
| 17. Recommendation Detail | Low | 4 | - |
| 18. Profile | Low | 4 | User data |
| 19. Settings | Medium | 8 | Multiple sub-screens |
| 20. Notifications | Medium | 6 | List management |
| 21. Calendar | Medium | 10 | Calendar widget, data aggregation |
| 22. Achievements | Low | 6 | Grid layout |
| 23. Education | Medium | 8 | Content management |
| 24. Help & Support | Low | 4 | Static content |
| **TOTAL** | - | **174 hours** | ~22 days of dev work |

---

## 🔄 State Management Strategy

### **Provider Structure**

```dart
providers/
├── auth_provider.dart           // Authentication state
├── dashboard_provider.dart      // Dashboard data
├── trends_provider.dart         // Trends & analytics
├── logging_provider.dart        // Data logging
├── chat_provider.dart           // AI chat
├── recommendations_provider.dart // Recommendations
├── profile_provider.dart        // User profile
├── notifications_provider.dart  // Notifications
└── app_state_provider.dart      // Global app state
```

### **Data Flow Pattern**

```
User Action → Provider Method → Service Layer → API/Database
                    ↓
            Update Local State
                    ↓
         Notify Listeners (UI)
                    ↓
           UI Auto-Rebuilds
```

---

## 🎨 Reusable Component Library

### **Core Components to Build First**

1. **CustomCard** - Base card with shadow and border radius
2. **CustomButton** - Primary, secondary, text variants
3. **CustomTextField** - Consistent text input with validation
4. **LoadingIndicator** - App-wide loading spinner
5. **ErrorView** - Consistent error display
6. **EmptyState** - For empty lists/screens
7. **BottomNavBar** - Main navigation (mobile/tablet)
8. **SideDrawer** - Navigation drawer (desktop)
9. **CustomAppBar** - Consistent header
10. **StatCard** - For displaying metrics
11. **ChartCard** - Wrapper for charts
12. **DataPointCard** - For logging items
13. **ConfirmationDialog** - Yes/no dialogs
14. **SuccessToast** - Success feedback
15. **DateTimePicker** - Custom date/time selector

### **Chart Components (fl_chart)**

1. **GlucoseLineChart** - Main glucose trend chart
2. **TimeInRangeDonutChart** - Pie/donut for percentages
3. **DailyBarChart** - Daily averages
4. **PatternHeatmap** - Day/hour heatmap
5. **MiniSparkline** - Small inline charts

---

## 📱 Responsive Breakpoint Implementation

### **Flutter Implementation Pattern**

```dart
class ResponsiveLayout extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;

  const ResponsiveLayout({
    required this.mobile,
    this.tablet,
    this.desktop,
  });

  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < 600;

  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= 600 &&
      MediaQuery.of(context).size.width < 1024;

  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= 1024;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 1024) {
          return desktop ?? tablet ?? mobile;
        } else if (constraints.maxWidth >= 600) {
          return tablet ?? mobile;
        } else {
          return mobile;
        }
      },
    );
  }
}
```

### **Usage Example**

```dart
ResponsiveLayout(
  mobile: SingleColumnDashboard(),
  tablet: TwoColumnDashboard(),
  desktop: ThreeColumnDashboard(),
)
```

---

## 🎯 Key Features Per Screen Type

### **Data Input Screens** (11-14)
- Form validation
- Auto-save drafts
- Clear error messages
- Success feedback
- Time/date pickers
- Photo upload (meals)
- Quick templates/presets

### **Data Visualization Screens** (6-10)
- Interactive charts
- Time period filtering
- Export functionality
- Zoom/pan capabilities
- Data point details on tap
- Empty states for no data
- Loading skeletons

### **List Screens** (16, 20, 22, 23)
- Pull-to-refresh
- Infinite scroll/pagination
- Search functionality
- Filter/sort options
- Empty states
- Swipe actions
- Batch operations

### **Detail Screens** (17, 7, 8, 9)
- Back navigation
- Share functionality
- Related content links
- Action buttons
- Rich media support
- Breadcrumb navigation (web)

---

## 🔐 Security & Privacy Considerations

### **Per Screen Type**

**Authentication Screens (1-4)**
- Secure password input (no autocomplete)
- Password strength indicator
- Rate limiting on login attempts
- Encrypted storage of tokens
- Biometric auth option (mobile)

**Data Entry Screens (11-14)**
- Auto-save to prevent data loss
- Offline capability with sync
- Input sanitization
- HIPAA-compliant data handling

**Profile & Settings (18-19)**
- Two-factor authentication setup
- Data export in encrypted format
- Clear consent for data sharing
- Privacy policy easily accessible

**All Screens**
- Automatic session timeout
- Sensitive data masked in screenshots
- No data caching on logout
- SSL/TLS for all API calls

---

## ♿ Accessibility Requirements

### **All Screens Must Have**

1. **Semantic Labels**
   - All interactive elements labeled
   - Screen reader friendly

2. **Keyboard Navigation** (Desktop)
   - Tab order logical
   - Enter to submit forms
   - Escape to close modals

3. **Color Contrast**
   - WCAG AA minimum (4.5:1 for text)
   - Don't rely on color alone for information

4. **Touch Targets** (Mobile)
   - Minimum 44x44 pixels
   - Adequate spacing between buttons

5. **Text Scaling**
   - Support system font size settings
   - Test at 200% zoom

6. **Alt Text**
   - All images have descriptive alt text
   - Charts have text descriptions

7. **Focus Indicators**
   - Clear visual focus states
   - Focus trap in modals

---

## 📊 Analytics & Tracking Plan

### **Events to Track Per Screen**

**Authentication (1-4)**
- Sign up started
- Sign up completed
- Login success/failure
- Onboarding completed/skipped

**Dashboard (5)**
- Dashboard viewed
- Quick action tapped (by type)
- Reminder tapped
- AI insight viewed

**Data Logging (11-14)**
- Log initiated (by type)
- Log completed (by type)
- Log cancelled
- Photo uploaded (meals)

**Trends (6-10)**
- Trends viewed
- Time period changed
- Chart interacted with
- Report downloaded

**AI Assistant (15-17)**
- Chat message sent
- Recommendation viewed
- Recommendation completed/dismissed

**Profile (18-24)**
- Settings changed
- Achievement unlocked
- Education content viewed
- Help article accessed

### **Performance Metrics**

- Screen load time
- Time to first meaningful paint
- API response times
- Chart render time
- Image upload time
- Crash rate per screen

---

## 🧪 Testing Strategy Per Screen Type

### **Authentication Flow (1-4)**
- ✅ Valid credentials login
- ✅ Invalid credentials rejection
- ✅ Password reset flow
- ✅ Form validation (all fields)
- ✅ Network error handling
- ✅ Session persistence

### **Dashboard (5)**
- ✅ Data loads correctly
- ✅ Empty state displayed when no data
- ✅ Pull to refresh works
- ✅ Quick actions navigate correctly
- ✅ Cards display responsive layout
- ✅ Real-time updates (if implemented)

### **Data Logging (11-14)**
- ✅ Form validation works
- ✅ Data saves to database
- ✅ Success feedback shown
- ✅ Error handling for failed saves
- ✅ Photo upload works (meals)
- ✅ Date/time picker functions correctly

### **Charts & Analytics (6-10)**
- ✅ Charts render with data
- ✅ Empty state shown when no data
- ✅ Time period filtering works
- ✅ Interactive elements function (tap, zoom)
- ✅ Export functionality works
- ✅ Statistics calculated correctly

### **AI Features (15-17)**
- ✅ Messages send and receive
- ✅ Streaming responses work (if applicable)
- ✅ Chat history persists
- ✅ Recommendations load
- ✅ Actions (complete/dismiss) work
- ✅ Error handling for AI failures

---

## 🚀 Performance Optimization Plan

### **Image Optimization**
- Use `cached_network_image` package
- Lazy load images in lists
- Compress uploaded photos
- Use appropriate image formats (WebP)
- Implement progressive loading

### **List Performance**
- Use `ListView.builder` for long lists
- Implement pagination (20 items per page)
- Use `AutomaticKeepAliveClientMixin` for tabs
- Debounce search inputs
- Virtualized scrolling for large datasets

### **Chart Performance**
- Limit data points to 100-200 per chart
- Use sampling for large datasets
- Implement chart caching
- Lazy load charts (render when visible)
- Use `RepaintBoundary` for complex charts

### **State Management**
- Use `const` constructors where possible
- Implement `select` for targeted rebuilds
- Avoid rebuilding entire widget tree
- Use `ListView.separated` instead of `Column` in `SingleChildScrollView`

### **Network Optimization**
- Implement request caching
- Use pagination for lists
- Compress API requests/responses
- Implement offline-first architecture
- Debounce API calls

---

## 🎨 Design System Summary

### **Color Palette**

```dart
// Primary Colors
primaryBlue: #2563EB
primaryGreen: #10B981
primaryRed: #EF4444

// Glucose Levels
glucoseLow: #FBBF24 (Yellow)
glucoseNormal: #10B981 (Green)
glucoseHigh: #EF4444 (Red)

// UI Colors
background: #F9FAFB
surface: #FFFFFF
textPrimary: #111827
textSecondary: #6B7280
border: #E5E7EB

// Status Colors
success: #10B981
warning: #F59E0B
error: #EF4444
info: #3B82F6
```

### **Typography**

```dart
// Font: Inter or System Default
displayLarge: 32px, Bold
displayMedium: 28px, Bold
displaySmall: 24px, Bold
headlineMedium: 20px, SemiBold
titleLarge: 18px, SemiBold
titleMedium: 16px, Medium
bodyLarge: 16px, Regular
bodyMedium: 14px, Regular
bodySmall: 12px, Regular
```

### **Shadows**

```dart
// Elevation system
shadow1: 0 1px 3px rgba(0,0,0,0.1)
shadow2: 0 4px 6px rgba(0,0,0,0.1)
shadow3: 0 10px 15px rgba(0,0,0,0.1)
shadow4: 0 20px 25px rgba(0,0,0,0.1)
```

### **Border Radius**

```dart
small: 8px
medium: 12px
large: 16px
xlarge: 20px
round: 999px (pill shape)
```

---

## ✅ Definition of Done (Per Screen)

A screen is considered "done" when:

1. ✅ **Functionality**
   - All features work as specified
   - Form validation implemented
   - Error handling complete
   - Loading states implemented

2. ✅ **Responsive Design**
   - Works on mobile (320px - 600px)
   - Works on tablet (600px - 1024px)
   - Works on desktop (1024px+)
   - Tested in portrait and landscape

3. ✅ **Performance**
   - Loads in < 2 seconds
   - Smooth 60fps animations
   - No memory leaks
   - Images optimized

4. ✅ **Accessibility**
   - Screen reader compatible
   - Keyboard navigable (desktop)
   - Touch targets 44px minimum
   - Color contrast WCAG AA

5. ✅ **Testing**
   - Unit tests written
   - Widget tests written
   - Integration tests pass
   - Manual QA complete

6. ✅ **Code Quality**
   - Code reviewed
   - No linting errors
   - Properly documented
   - Follows style guide

7. ✅ **Documentation**
   - Component documented
   - API contracts defined
   - User flow documented
   - Known issues logged

---

## 🎯 Next Steps - Let's Start Building!

### **Recommended Order of Implementation**

1. **Foundation Setup** (Do this first!)
   - Project structure
   - Theme configuration
   - Navigation system
   - Core models
   - Base services

2. **Authentication Flow** (Screens 1-4)
   - Critical for testing other features
   - Relatively straightforward
   - No external dependencies

3. **Dashboard** (Screen 5)
   - Most important screen
   - Helps visualize data flow
   - Tests all services

4. **Data Logging** (Screens 11-14)
   - Need data to visualize
   - Core user functionality
   - Tests database integration

5. **Trends** (Screens 6-10)
   - Requires logged data
   - Complex but high value
   - Tests chart library

6. **AI Features** (Screens 15-17)
   - Requires backend integration
   - Can develop in parallel
   - Tests API communication

7. **Profile & Extras** (Screens 18-24)
   - Lower priority
   - Can be done incrementally
   - Polish features

---

## 📝 Ready to Start Coding?

I'm ready to help you implement any screen step-by-step. Which would you like to start with?

**Recommended starting points:**
1. **Project Setup** - Set up the Flutter project structure, theme, and navigation
2. **Screen 1-4: Authentication** - Build login/register flow
3. **Screen 5: Dashboard** - Create the main dashboard
4. **Screen 11: Log Glucose** - Simplest data entry screen

Just let me know which one you'd like to tackle first, and I'll provide:
- Complete code for all files
- Step-by-step implementation guide
- Testing instructions
- Integration with existing code

What should we build first? 🚀