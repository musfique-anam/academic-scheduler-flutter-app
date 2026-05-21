# 📘 Academic Scheduler — Technical Documentation

<div align="center">

**Comprehensive Developer & Maintainer Guide**

*Version 1.0.0 • February 2026*

[← Back to README](README.md)

</div>

---

## 📑 Table of Contents

- [📘 Academic Scheduler — Technical Documentation](#-academic-scheduler--technical-documentation)
  - [📑 Table of Contents](#-table-of-contents)
  - [1. Project Overview](#1-project-overview)
    - [1.1 What It Does](#11-what-it-does)
    - [1.2 Purpose](#12-purpose)
    - [1.3 Stakeholders](#13-stakeholders)
    - [1.4 Tech Summary](#14-tech-summary)
  - [2. Core Functionalities](#2-core-functionalities)
    - [2.1 Authentication Module](#21-authentication-module)
    - [2.2 Master Data Management](#22-master-data-management)
    - [2.3 Routine Generation](#23-routine-generation)
    - [2.4 Conflict Detection \& Resolution](#24-conflict-detection--resolution)
    - [2.5 Visualization \& Analytics](#25-visualization--analytics)
    - [2.6 Schedule Viewing](#26-schedule-viewing)
    - [2.7 Teacher Module](#27-teacher-module)
    - [2.8 Export \& Sharing](#28-export--sharing)
    - [2.9 Settings \& Personalization](#29-settings--personalization)
  - [3. Project Structure](#3-project-structure)
    - [3.1 Folder Responsibilities](#31-folder-responsibilities)
  - [4. Architecture \& Design Patterns](#4-architecture--design-patterns)
    - [4.1 Layered Architecture](#41-layered-architecture)
    - [4.2 Patterns Used](#42-patterns-used)
  - [5. Data Models](#5-data-models)
    - [5.1 `Department`](#51-department)
    - [5.2 `Teacher`](#52-teacher)
    - [5.3 `Batch`](#53-batch)
    - [5.4 `Course`](#54-course)
    - [5.5 `Room`](#55-room)
    - [5.6 `Routine`](#56-routine)
  - [6. State Management (Provider Layer)](#6-state-management-provider-layer)
  - [7. Internal API Documentation](#7-internal-api-documentation)
    - [7.1 `AuthProvider`](#71-authprovider)
    - [7.2 `RoutineProvider`](#72-routineprovider)
    - [7.3 `TeacherProvider`](#73-teacherprovider)
    - [7.4 `DepartmentProvider`, `BatchProvider`, `CourseProvider`, `RoomProvider`](#74-departmentprovider-batchprovider-courseprovider-roomprovider)
    - [7.5 `DashboardProvider`](#75-dashboardprovider)
    - [7.6 Bonus: External API Hook (Future)](#76-bonus-external-api-hook-future)
  - [8. Database Schema \& Queries](#8-database-schema--queries)
    - [8.1 Tables](#81-tables)
    - [8.2 Common Queries](#82-common-queries)
  - [9. Scheduling Algorithm Specification](#9-scheduling-algorithm-specification)
    - [9.1 Class Routine Algorithm (CSP + Greedy)](#91-class-routine-algorithm-csp--greedy)
    - [9.2 Exam Routine Algorithm](#92-exam-routine-algorithm)
    - [9.3 Conflict Types](#93-conflict-types)
  - [10. Navigation Routes](#10-navigation-routes)
  - [11. Build \& Deployment](#11-build--deployment)
    - [11.1 Build Configuration (`android/app/build.gradle.kts`)](#111-build-configuration-androidappbuildgradlekts)
    - [11.2 Build Commands](#112-build-commands)
    - [11.3 Output Location](#113-output-location)
  - [12. Testing Strategy](#12-testing-strategy)
  - [13. Troubleshooting](#13-troubleshooting)
  - [14. Glossary](#14-glossary)
  - [📌 How to Add to GitHub](#-how-to-add-to-github)

---

## 1. Project Overview

### 1.1 What It Does

**Academic Scheduler** is a Flutter-based Android application that automates the generation, validation, and distribution of university **class routines** and **exam schedules**. It replaces manual spreadsheet-based scheduling with an intelligent, conflict-aware engine that produces optimized timetables in seconds.

### 1.2 Purpose

| Goal | Description |
|:-----|:------------|
| **Automation** | Eliminate hours of manual routine crafting |
| **Accuracy** | Detect & prevent teacher/room/batch conflicts |
| **Accessibility** | Mobile-first delivery for all stakeholders |
| **Maintainability** | Easy mid-semester updates without rebuilding |

### 1.3 Stakeholders

- **Administrators / Coordinators** — full CRUD + generation authority
- **Teachers** — view personal schedules, declare availability
- **Students** *(roadmap)* — read-only filtered views

### 1.4 Tech Summary

| Layer | Technology |
|:------|:-----------|
| UI | Flutter 3.x + Material Design 3 |
| Language | Dart 3.x |
| State | Provider (ChangeNotifier) |
| Database | SQLite (sqflite) |
| Storage | Shared Preferences, Path Provider |
| Export | `printing`, `pdf` |

---

## 2. Core Functionalities

### 2.1 Authentication Module
- Multi-role login (Admin / Teacher) via `AuthProvider`
- Persistent session via Shared Preferences
- Logout confirmation + secure session clearing
- Smart back navigation with exit-app guard

### 2.2 Master Data Management
| Entity | Operations |
|:-------|:-----------|
| Departments | Create, Read, Update, Delete |
| Teachers | Create, Read, Update, Delete + workload tracking |
| Courses | Create, Read, Update, Delete + batch mapping |
| Batches | Create, Read, Update, Delete + program-type tagging |
| Rooms | Create, Read, Update, Delete + capacity & floor metadata |
| Bulk Insert | CSV / structured payload import |

### 2.3 Routine Generation
- **Class Routine (Auto):** CSP solver assigns courses to time slots
- **Exam Routine (Auto):** date-range scheduling with gap-day enforcement
- **Manual Mode:** explicit slot-by-slot entry with validation
- **Modes:** Central (cross-departmental) or Batch-wise

### 2.4 Conflict Detection & Resolution
- Real-time detection of:
  - Teacher double-bookings
  - Room double-bookings
  - Batch double-bookings
- Visual conflict highlighting with severity colors
- Drag-and-drop manual resolution screen

### 2.5 Visualization & Analytics
- Live dashboard with totals (departments, teachers, courses, etc.)
- Weekly bar-chart overview
- Recent activity feed
- Notification center with badges
- Workload summary per teacher

### 2.6 Schedule Viewing
- Tabbed view (Class / Exam)
- Multi-dimensional filters (Batch, Teacher, Day, Room)
- Color-coded grid cells
- Auto-tab selection from generation context

### 2.7 Teacher Module
- Personal teaching dashboard
- Availability declaration
- Interested-course preference
- Filtered routine view
- Personal workload visualization

### 2.8 Export & Sharing
- PDF generation (print-ready)
- Image export
- OS-native print support

### 2.9 Settings & Personalization
- Light / Dark / System theme
- Notification preferences
- Profile editing with image picker
- Password change

---

## 3. Project Structure
academic-scheduler-flutter-app/
│
├── android/ # Android-specific build files
│ └── app/build.gradle.kts # compileSdk=35, ndkVersion=27.0.12077973
│
├── assets/
│ ├── images/ # App logos, splash branding
│ └── screenshots/ # README documentation images
│
├── lib/
│ │
│ ├── data/
│ │ └── models/ # Pure data classes (no business logic)
│ │ ├── batch_model.dart
│ │ ├── course_model.dart
│ │ ├── department_model.dart
│ │ ├── room_model.dart
│ │ ├── routine_model.dart
│ │ └── teacher_model.dart
│ │
│ ├── providers/ # ChangeNotifier-based state managers
│ │ ├── auth_provider.dart
│ │ ├── batch_provider.dart
│ │ ├── course_provider.dart
│ │ ├── dashboard_provider.dart
│ │ ├── department_provider.dart
│ │ ├── merge_provider.dart
│ │ ├── profile_provider.dart
│ │ ├── room_provider.dart
│ │ ├── routine_provider.dart # Core scheduling engine
│ │ ├── settings_provider.dart
│ │ ├── teacher_provider.dart
│ │ └── theme_provider.dart
│ │
│ ├── presentation/
│ │ ├── screens/
│ │ │ ├── splash_screen.dart
│ │ │ ├── login_screen.dart
│ │ │ │
│ │ │ ├── admin/
│ │ │ │ ├── admin_dashboard.dart
│ │ │ │ ├── department_screen.dart
│ │ │ │ ├── teacher_screen.dart
│ │ │ │ ├── teacher_add_edit_screen.dart
│ │ │ │ ├── teacher_profile_screen.dart
│ │ │ │ ├── batch_screen.dart
│ │ │ │ ├── course_screen.dart
│ │ │ │ ├── room_screen.dart
│ │ │ │ ├── routine_generation_screen.dart
│ │ │ │ ├── view_routine_screen.dart
│ │ │ │ ├── conflict_resolution_screen.dart
│ │ │ │ ├── workload_summary_screen.dart
│ │ │ │ ├── merge_section_screen.dart
│ │ │ │ ├── room_assignment_screen.dart
│ │ │ │ ├── data_insertion_screen.dart
│ │ │ │ ├── profile_screen.dart
│ │ │ │ ├── edit_profile_screen.dart
│ │ │ │ └── settings_screen.dart
│ │ │ │
│ │ │ └── teacher/
│ │ │ ├── teacher_dashboard.dart
│ │ │ ├── teacher_profile_screen.dart
│ │ │ ├── teacher_availability_screen.dart
│ │ │ ├── teacher_interested_courses_screen.dart
│ │ │ └── teacher_routine_screen.dart
│ │ │
│ │ └── widgets/
│ │ ├── error_widget.dart
│ │ └── loading_widget.dart
│ │
│ ├── utils/
│ │ └── logo_widget.dart
│ │
│ └── main.dart # App entry point + route table
│
├── test/ # Unit & widget tests
├── pubspec.yaml # Dependency manifest
├── README.md # Project overview
├── DOCUMENTATION.md # ← This file
└── LICENSE

### 3.1 Folder Responsibilities

| Folder | Responsibility |
|:-------|:---------------|
| `data/models/` | Plain Dart classes; serialization (`fromMap` / `toMap`) |
| `providers/` | Business logic, state, persistence calls |
| `presentation/screens/` | UI screens consuming providers |
| `presentation/widgets/` | Reusable UI components |
| `utils/` | Helpers, constants, custom paint widgets |

---

## 4. Architecture & Design Patterns

### 4.1 Layered Architecture
┌──────────────────────────────────────────────┐
│ UI LAYER (screens/, widgets/) │
│ - Stateless / Stateful widgets │
│ - Consumer<Provider> for reactivity │
└────────────────────┬─────────────────────────┘
│ reads + dispatches
▼
┌──────────────────────────────────────────────┐
│ STATE LAYER (providers/) │
│ - ChangeNotifier subclasses │
│ - Holds in-memory state │
│ - Calls into business logic │
└────────────────────┬─────────────────────────┘
│
▼
┌──────────────────────────────────────────────┐
│ BUSINESS LOGIC LAYER │
│ - Scheduling algorithm │
│ - Conflict detection │
│ - Validation rules │
└────────────────────┬─────────────────────────┘
│
▼
┌──────────────────────────────────────────────┐
│ DATA LAYER (models/, db helpers) │
│ - SQLite via sqflite │
│ - Shared Preferences for tokens │
└──────────────────────────────────────────────┘



### 4.2 Patterns Used

| Pattern | Where |
|:--------|:------|
| **Provider / ChangeNotifier** | All state managers |
| **Repository (lite)** | Inside providers (DB calls abstracted) |
| **Singleton** | Database helper instance |
| **Builder** | `Consumer`, `TweenAnimationBuilder` |
| **Strategy** | Class vs. Exam routine generators |
| **Observer** | `notifyListeners()` flow |

---

## 5. Data Models

### 5.1 `Department`

```dart
class Department {
  final int? id;
  final String name;
  final String code;

  Map<String, dynamic> toMap();
  factory Department.fromMap(Map<String, dynamic> map);
}
```

### 5.2 `Teacher`

```dart
class Teacher {
  final int? id;
  final String name;
  final String email;
  final String phone;
  final String designation;
  final int departmentId;
}
```

### 5.3 `Batch`

```dart
class Batch {
  final int? id;
  final String batchNo;
  final String programType;        // 'HSC' | 'Diploma'
  final int departmentId;
  final String? departmentName;    // joined field
}
```

### 5.4 `Course`

```dart
class Course {
  final int? id;
  final String code;
  final String title;
  final double credit;
  final int batchId;
  final int? teacherId;
}
```

### 5.5 `Room`

```dart
class Room {
  final int? id;
  final String roomNo;
  final int floor;
  final int capacity;
}
```

### 5.6 `Routine`

```dart
class Routine {
  final int? id;
  final int batchId;
  final int courseId;
  final int? teacherId;
  final int? roomId;
  final String? roomNo;
  final String day;
  final int slot;
  final String type;               // 'Class' | 'Exam'
  final DateTime? date;            // exams only
}
```

---

## 6. State Management (Provider Layer)

All providers extend `ChangeNotifier` and are registered in `main.dart` via `MultiProvider`.

| Provider | Responsibility |
|:---------|:---------------|
| `AuthProvider` | Login, logout, current user, role detection |
| `DashboardProvider` | Aggregate stats, notifications, activities |
| `DepartmentProvider` | Department CRUD |
| `TeacherProvider` | Teacher CRUD, profile load |
| `BatchProvider` | Batch CRUD with department joins |
| `CourseProvider` | Course CRUD with batch filtering |
| `RoomProvider` | Room CRUD |
| `RoutineProvider` | Generation, conflicts, workloads, progress |
| `MergeProvider` | Section merging |
| `ProfileProvider` | User profile editing |
| `SettingsProvider` | Settings & preferences |
| `ThemeProvider` | Theme switching |

---

## 7. Internal API Documentation

> The app is fully offline-first. "API" here refers to the **public Dart methods exposed by each provider** — the contract UI screens depend on.

### 7.1 `AuthProvider`

```dart
class AuthProvider extends ChangeNotifier {
  Map<String, dynamic>? get currentUser;
  bool get isAdmin;
  bool get isTeacher;

  Future<bool> login({required String email, required String password});
  Future<void> logout();
  Future<void> loadSession();
}
```

| Method | Returns | Description |
|:-------|:--------|:------------|
| `login(email, password)` | `bool` | Authenticates user; persists session on success |
| `logout()` | `void` | Clears session & navigates to login |
| `loadSession()` | `void` | Restores session on app startup |

### 7.2 `RoutineProvider`

```dart
class RoutineProvider extends ChangeNotifier {
  List<Routine> get routines;
  List<Conflict> get conflicts;
  Map<int, int> get workloads;
  double get progress;             // 0.0 – 1.0
  String? get error;
  bool get hasConflicts;
  bool get hasOverload;

  Future<void> generateClassRoutine({
    required int departmentId,
    required String programType,
    required Function(String) onStatusUpdate,
  });

  Future<void> generateExamRoutine({
    required List<int> departmentIds,
    required List<int> batchIds,
    required DateTime startDate,
    required DateTime endDate,
    required int gapDays,
  });

  Future<void> resolveConflict(int routineId, Map<String, dynamic> changes);
  void clear();
}
```

### 7.3 `TeacherProvider`

```dart
class TeacherProvider extends ChangeNotifier {
  List<Teacher> get teachers;

  Future<void> loadTeachers();
  Future<int> addTeacher(Teacher teacher);
  Future<bool> updateTeacher(Teacher teacher);
  Future<bool> deleteTeacher(int id);
  Teacher? findById(int id);
}
```

### 7.4 `DepartmentProvider`, `BatchProvider`, `CourseProvider`, `RoomProvider`

All follow the same standard CRUD contract:

```dart
class XxxProvider extends ChangeNotifier {
  List<Xxx> get items;

  Future<void> loadXxx();
  Future<int> addXxx(Xxx item);
  Future<bool> updateXxx(Xxx item);
  Future<bool> deleteXxx(int id);
}
```

### 7.5 `DashboardProvider`

```dart
class DashboardProvider extends ChangeNotifier {
  int get totalDepartments;
  int get totalTeachers;
  int get totalBatches;
  int get totalCourses;
  int get totalRooms;
  int get totalStudents;
  int get activeClasses;
  int get todayRoutines;
  int get todayClasses;
  int get pendingTasks;
  int get unreadCount;
  bool get hasUnreadNotifications;
  List<Map<String, dynamic>> get recentActivities;

  Future<void> loadDashboard();
  void markNotificationsRead();
}
```

### 7.6 Bonus: External API Hook (Future)

Reserved namespace for cloud sync (Firestore):

```dart
abstract class CloudSyncApi {
  Future<void> pushRoutine(Routine routine);
  Future<List<Routine>> pullRoutines({required int departmentId});
  Stream<List<Routine>> watchRoutines({required int batchId});
}
```

---

## 8. Database Schema & Queries

### 8.1 Tables

```sql
CREATE TABLE departments (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  code TEXT UNIQUE NOT NULL
);

CREATE TABLE teachers (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  email TEXT UNIQUE,
  phone TEXT,
  designation TEXT,
  department_id INTEGER,
  FOREIGN KEY (department_id) REFERENCES departments(id) ON DELETE SET NULL
);

CREATE TABLE batches (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  batch_no TEXT NOT NULL,
  program_type TEXT NOT NULL,
  department_id INTEGER NOT NULL,
  FOREIGN KEY (department_id) REFERENCES departments(id) ON DELETE CASCADE
);

CREATE TABLE courses (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  code TEXT NOT NULL,
  title TEXT NOT NULL,
  credit REAL NOT NULL,
  batch_id INTEGER NOT NULL,
  teacher_id INTEGER,
  FOREIGN KEY (batch_id) REFERENCES batches(id) ON DELETE CASCADE,
  FOREIGN KEY (teacher_id) REFERENCES teachers(id) ON DELETE SET NULL
);

CREATE TABLE rooms (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  room_no TEXT UNIQUE NOT NULL,
  floor INTEGER NOT NULL,
  capacity INTEGER NOT NULL
);

CREATE TABLE routines (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  batch_id INTEGER NOT NULL,
  course_id INTEGER NOT NULL,
  teacher_id INTEGER,
  room_id INTEGER,
  day TEXT NOT NULL,
  slot INTEGER NOT NULL,
  type TEXT NOT NULL DEFAULT 'Class',
  date TEXT,
  FOREIGN KEY (batch_id) REFERENCES batches(id),
  FOREIGN KEY (course_id) REFERENCES courses(id),
  FOREIGN KEY (teacher_id) REFERENCES teachers(id),
  FOREIGN KEY (room_id) REFERENCES rooms(id)
);
```

### 8.2 Common Queries

```sql
-- All routines for a batch
SELECT r.*, c.code, c.title, t.name AS teacher_name, ro.room_no
FROM routines r
JOIN courses c ON r.course_id = c.id
LEFT JOIN teachers t ON r.teacher_id = t.id
LEFT JOIN rooms ro ON r.room_id = ro.id
WHERE r.batch_id = ?
ORDER BY r.day, r.slot;

-- Detect teacher conflicts
SELECT teacher_id, day, slot, COUNT(*) AS cnt
FROM routines
WHERE teacher_id IS NOT NULL
GROUP BY teacher_id, day, slot
HAVING cnt > 1;

-- Workload per teacher
SELECT teacher_id, COUNT(*) AS total_classes
FROM routines
WHERE teacher_id IS NOT NULL
GROUP BY teacher_id;
```

---

## 9. Scheduling Algorithm Specification

### 9.1 Class Routine Algorithm (CSP + Greedy)

**Inputs:** courses, teachers, rooms, batches, time-slots, working-days

**Steps:**

1. **Initialize** empty routine list, conflict list, workload map
2. **Sort courses** by credit-hour (desc) — high-credit first
3. **For each course:**
   - Filter eligible teachers (assigned + available)
   - Filter free time slots (no batch double-booking)
   - Filter free rooms (capacity ≥ batch size)
   - **Assign** first valid `(teacher, slot, room)` triple
   - Increment teacher workload
4. **Validate:** scan for residual conflicts, mark them
5. **Emit** `(routines, conflicts, workloads)`

**Complexity:** `O(C × T × S × R)` worst case where C=courses, T=teachers, S=slots, R=rooms.

### 9.2 Exam Routine Algorithm

**Inputs:** batches, date-range, gap-days, available rooms

**Steps:**

1. Generate ordered exam-date list within range
2. For each (batch × course):
   - Find next valid date respecting `gap_days` per batch
   - Allocate room with sufficient capacity
   - Commit assignment
3. Validate no batch has two exams within `gap_days`

### 9.3 Conflict Types

| Code | Description |
|:----:|:------------|
| `TEACHER_DOUBLE` | Same teacher, same slot |
| `ROOM_DOUBLE` | Same room, same slot |
| `BATCH_DOUBLE` | Same batch, same slot |
| `OVERLOAD` | Teacher exceeds max-credits |
| `NO_GAP` | Exam violates gap-day rule |

---

## 10. Navigation Routes

Defined in `main.dart`:

| Route | Screen | Access |
|:------|:-------|:------:|
| `/` | `SplashScreen` | Public |
| `/login` | `LoginScreen` | Public |
| `/admin/dashboard` | `AdminDashboard` | Admin |
| `/teacher/dashboard` | `TeacherDashboard` | Teacher |

All other navigation uses `Navigator.push(MaterialPageRoute(...))` with widget instances.

---

## 11. Build & Deployment

### 11.1 Build Configuration (`android/app/build.gradle.kts`)

```kotlin
android {
    compileSdk = 35
    ndkVersion = "27.0.12077973"
    defaultConfig {
        minSdk = 23
        targetSdk = 35
    }
}
```

### 11.2 Build Commands

```bash
# Debug
flutter run

# Profile
flutter run --profile

# Release APK
flutter build apk --release

# Split APKs by ABI
flutter build apk --split-per-abi --release

# AppBundle for Play Store
flutter build appbundle --release
```

### 11.3 Output Location
build/app/outputs/flutter-apk/app-release.apk

---

## 12. Testing Strategy

| Layer | Tool | Coverage Target |
|:------|:-----|:---------------:|
| Unit | `flutter_test` | 70% (providers, models) |
| Widget | `flutter_test` | Key screens |
| Integration | `integration_test` | End-to-end flows |

```bash
flutter test                              # all tests
flutter test test/providers/              # provider tests only
flutter test --coverage                   # generate coverage
```

---

## 13. Troubleshooting

| Issue | Resolution |
|:------|:-----------|
| **Build fails with SDK 34 warning** | Update `compileSdk = 35` |
| **NDK version mismatch** | Set `ndkVersion = "27.0.12077973"` |
| **Hot reload doesn't update splash** | Use **R** (full restart) instead of **r** |
| **Empty dropdowns** | Call `loadXxx()` in `initState` post-frame |
| **Conflicts not detected** | Verify `RoutineProvider.clear()` before re-run |
| **DB schema changes ignored** | Bump `version` in DB helper or uninstall app |

---

## 14. Glossary

| Term | Definition |
|:-----|:-----------|
| **CSP** | Constraint Satisfaction Problem |
| **Slot** | A discrete period in the day (e.g., 9:30–11:00) |
| **Workload** | Number of teaching hours assigned to a teacher |
| **Gap-day** | Mandatory days off between exams for a batch |
| **Routine** | The complete generated timetable |
| **Conflict** | A scheduling rule violation |
| **Overload** | Teacher assigned more than max-allowed credits |

---

## 📌 How to Add to GitHub

```bash
# 1. Save this file as DOCUMENTATION.md in your project root
# 2. Commit & push
git add DOCUMENTATION.md
git commit -m "Add comprehensive technical documentation"
git push origin main
```

Then add this badge to the top of your `README.md`:

```markdown
[
```

---

<div align="center">

**Documentation maintained by:**

**Md. Arif Hasan** • **Md. Musfique Anam Ananto**  
*Pundra University of Science & Technology, Bogura*

`v1.0.0` • `February 2026`

</div>