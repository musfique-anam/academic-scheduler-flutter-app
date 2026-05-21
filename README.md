# 📚 Academic Scheduler

<div align="center">

![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)
![SQLite](https://img.shields.io/badge/SQLite-07405E?style=for-the-badge&logo=sqlite&logoColor=white)
![Material 3](https://img.shields.io/badge/Material_Design_3-757575?style=for-the-badge&logo=materialdesign&logoColor=white)
![Android](https://img.shields.io/badge/Android-3DDC84?style=for-the-badge&logo=android&logoColor=white)

### *An Intelligent Mobile Application for Automated Course Coordination & Exam Scheduling*

**A Production-Grade Solution for Academic Routine Management**

[![License](https://img.shields.io/badge/License-Academic-blue.svg?style=flat-square)](LICENSE)
[![Version](https://img.shields.io/badge/Version-1.0.0-brightgreen.svg?style=flat-square)](#)
[![Status](https://img.shields.io/badge/Status-Active-success.svg?style=flat-square)](#)
[![Platform](https://img.shields.io/badge/Platform-Android-blueviolet.svg?style=flat-square)](#)

---

</div>

## 🎓 Academic Information

> **Course:** CSE 3102 — Mobile Application Development Sessional  
> **Institution:** Pundra University of Science & Technology, Bogura  
> **Department:** Computer Science and Engineering  
> **Program:** B.Sc. in CSE (HSC) — Batch 23  
> **Submission Date:** 06 February 2026

### 👨‍🏫 Course Instructor

**Md. Forhan Shahriar Fahim**  
*Lecturer, Department of Computer Science and Engineering*  
Pundra University of Science & Technology, Bogura

### 👥 Development Team

| Student ID | Name | Role |
|:----------:|:-----|:-----|
| `0322320105101029` | **Md. Arif Hasan** | Lead Developer & UI/UX Architect |
| `0322320105101039` | **Md. Musfique Anam Ananto** | Backend Logic & Algorithm Developer |

---

## 📖 Table of Contents

1. [Overview](#-overview)
2. [Problem Statement](#-problem-statement)
3. [Proposed Solution](#-proposed-solution)
4. [Key Features](#-key-features)
5. [System Architecture](#-system-architecture)
6. [Technology Stack](#-technology-stack)
7. [Screenshots](#-screenshots)
8. [Installation Guide](#-installation-guide)
9. [Project Structure](#-project-structure)
10. [Scheduling Algorithm](#-scheduling-algorithm)
11. [Database Schema](#-database-schema)
12. [Future Enhancements](#-future-enhancements)
13. [Contributors](#-contributors)
14. [License & Acknowledgements](#-license--acknowledgements)

---

## 🌟 Overview

**Academic Scheduler** is a feature-rich, native Android application engineered with **Flutter** that fundamentally transforms how universities orchestrate their academic schedules. The platform delivers a unified ecosystem where administrators automate complex routine generation, teachers manage their teaching loads, and students access conflict-free schedules — all from a single, elegant mobile interface.

The application embodies modern software engineering principles including **Provider-based state management**, **clean architecture**, **constraint-satisfaction algorithms**, and **Material Design 3 aesthetics** to deliver a production-quality experience worthy of real-world deployment.

---

## ❗ Problem Statement

Academic institutions worldwide grapple with the time-intensive complexity of manual schedule generation:

- ⏰ **Time-Consuming:** Coordinators spend 40+ hours per semester crafting routines
- ❌ **Error-Prone:** Human oversight frequently produces overlapping slots and double-bookings
- 👥 **Resource Conflicts:** Teachers assigned to simultaneous classes; rooms double-booked
- 📅 **Exam Spacing:** Difficulty maintaining required gap-days between examinations for students
- 📊 **Workload Imbalance:** Some teachers overloaded while others underutilized
- 🔄 **Rigid Updates:** Manual systems make mid-semester adjustments painful

---

## 💡 Proposed Solution

Academic Scheduler delivers an **intelligent, automated, conflict-aware scheduling engine** that ingests institutional data — courses, credit hours, teacher availability, room capacities, batch information — and produces optimized routines in seconds, not days.

### 🎯 Target Audience

| Tier | Users | Privileges |
|:----:|:------|:-----------|
| **Primary** | Course Coordinators, Department Heads, Administrators | Full CRUD, generation, conflict resolution |
| **Secondary** | Teachers | View routines, mark availability, manage interested courses |
| **Tertiary** | Students *(future)* | View-only schedule access with filtering |

---

## ✨ Key Features

### 🔐 Authentication & Role-Based Access
- 🔑 Multi-role login system (Admin / Teacher) with secure session persistence
- 👤 Profile management with editable details, profile pictures, and credentials
- 🚪 Confirmation dialogs for critical actions (logout, exit, deletion)
- 🛡️ Smart back-navigation with exit-app confirmation

### 🏛️ Master Data Management (Admin)
- 🏢 **Departments:** Full CRUD with department codes and metadata
- 👨‍🏫 **Teachers:** Comprehensive teacher profiles with workload tracking
- 📚 **Courses:** Course catalog with codes, titles, credit hours, batch mapping
- 👥 **Batches:** Batch management for HSC and Diploma programs
- 🚪 **Rooms:** Room inventory with floor numbers and capacity constraints
- 📦 **Bulk Data Insertion:** CSV/structured import for rapid setup

### 🤖 Intelligent Routine Generation
- ⚡ **Auto-Generate Class Routines** with one click using constraint-satisfaction algorithm
- 📝 **Auto-Generate Exam Routines** with configurable gap-days between exams
- ✋ **Manual Entry Mode** for fine-grained custom scheduling
- 🎯 **Generation Modes:** Central (cross-departmental) and Batch-wise
- 📈 **Real-Time Progress Tracking** with percentage indicator during generation
- 🎓 **Program Support:** HSC and Diploma routine variants

### 🔍 Conflict Detection & Resolution
- ⚠️ **Automatic Conflict Detection** for time, teacher, and room overlaps
- 🎨 **Visual Alerts** with color-coded severity indicators
- 🛠️ **Conflict Resolution Screen** with drag-and-drop manual adjustment
- 📊 **Workload Summary** to identify overloaded/underutilized teachers
- ✅ **Validation Engine** ensures rule compliance before commit

### 🔀 Advanced Scheduling Operations
- 🔗 **Section Merging:** Combine multiple sections for shared classes
- 🏠 **Smart Room Assignment:** Automatic room allocation based on capacity
- 📅 **Date Range Selection** for exam routines with calendar picker
- 🔄 **Re-generation** without losing previous configurations

### 📱 Dashboard & Analytics
- 📊 **Live Statistics:** Total departments, teachers, batches, courses, rooms
- 📈 **Weekly Overview** with bar-chart visualization
- 🕐 **Recent Activity Feed** with status badges
- 🔔 **Notification Center** with unread badges
- ⚡ **Quick Actions Bar** for high-frequency operations
- 🎯 **Type-Aware Success Dialogs** (separate stats for class vs. exam routines)

### 👁️ Schedule Viewing
- 📅 **Interactive Calendar Grid** showing complete routines
- 🔎 **Multi-Dimensional Filtering:** by Batch, Teacher, Day, Room, Type
- 🎨 **Color-Coded Cells** for visual hierarchy
- 📑 **Tab-Based Views** for Class and Exam routines
- 🎯 **Auto-Open Correct Tab** based on context

### 👨‍🏫 Teacher Module
- 📋 **Personal Teaching Dashboard** with statistics
- 📅 **Teacher Availability Manager** for declaring free slots
- 💼 **Interested Courses** declaration
- 📊 **Personal Workload Visualization**
- 👁️ **Routine View** filtered to own classes

### 📤 Export & Sharing
- 📄 **PDF Export** for offline distribution
- 🖼️ **Image Export** for sharing on messaging platforms
- 🖨️ **Direct Print Support** via OS print services

### 🎨 User Experience Excellence
- 🌗 **Light/Dark Theme** support with system-aware switching
- 🎬 **Smooth Animations** including elastic, fade, and slide transitions
- ⚡ **60 FPS Performance** with optimized rendering
- 📱 **Responsive Design** adapting to phone and tablet form factors
- ♿ **Accessibility-First** with proper contrast and tap targets
- 🌐 **Material Design 3** compliance throughout

---

## 🏗️ System Architecture
┌─────────────────────────────────────────────────────────────┐
│ PRESENTATION LAYER │
│ Screens - Widgets - Animations - Material Design 3 UI │
└────────────────────────┬────────────────────────────────────┘
│
┌────────────────────────▼────────────────────────────────────┐
│ STATE MANAGEMENT LAYER │
│ Provider Pattern - ChangeNotifier - Reactive Updates │
│ AuthProvider - RoutineProvider - TeacherProvider - etc. │
└────────────────────────┬────────────────────────────────────┘
│
┌────────────────────────▼────────────────────────────────────┐
│ BUSINESS LOGIC LAYER │
│ Scheduling Algorithm - Conflict Detection - Validation │
└────────────────────────┬────────────────────────────────────┘
│
┌────────────────────────▼────────────────────────────────────┐
│ DATA LAYER │
│ Models - Repositories - SQLite Database │
└─────────────────────────────────────────────────────────────┘

---

## 🛠️ Technology Stack

### Frontend & Framework
| Technology | Purpose |
|:-----------|:--------|
| **Flutter 3.x** | Cross-platform UI toolkit |
| **Dart 3.x** | Primary programming language |
| **Material Design 3** | Design system |
| **Provider** | State management |

### Data & Persistence
| Technology | Purpose |
|:-----------|:--------|
| **SQLite (sqflite)** | Local relational database |
| **Path Provider** | Filesystem path resolution |
| **Shared Preferences** | Lightweight key-value storage |

### Utilities & Plugins
| Technology | Purpose |
|:-----------|:--------|
| **Image Picker** | Profile picture selection |
| **Printing & PDF** | Document generation and export |
| **Flutter Native Splash** | Branded splash experience |
| **Intl** | Date and locale formatting |

---

## 📸 Screenshots

> **Note:** Drop your captured screenshots inside `assets/screenshots/` and the table below will render them automatically.

### 🌟 Splash & Authentication

| Splash Screen | Login Screen |
|:-------------:|:------------:|
| ![Splash](assets/screenshots/splash.png) | ![Login](assets/screenshots/login.png) |

### 🛠️ Admin Module

| Admin Dashboard | Drawer Menu | Notifications |
|:---------------:|:-----------:|:-------------:|
| ![Dashboard](assets/screenshots/admin_dashboard.png) | ![Drawer](assets/screenshots/admin_drawer.png) | ![Notifications](assets/screenshots/notifications.png) |

| Department Management | Teacher Management | Course Management |
|:---------------------:|:------------------:|:-----------------:|
| ![Departments](assets/screenshots/departments.png) | ![Teachers](assets/screenshots/teachers.png) | ![Courses](assets/screenshots/courses.png) |

| Batch Management | Room Management | Data Insertion |
|:----------------:|:---------------:|:--------------:|
| ![Batches](assets/screenshots/batches.png) | ![Rooms](assets/screenshots/rooms.png) | ![Insert Data](assets/screenshots/insert_data.png) |

### 🤖 Routine Generation

| Generation Form | Auto Mode | Manual Mode |
|:---------------:|:---------:|:-----------:|
| ![Generation](assets/screenshots/generation.png) | ![Auto](assets/screenshots/auto_mode.png) | ![Manual](assets/screenshots/manual_mode.png) |

| Generating Progress | Class Success Dialog | Exam Success Dialog |
|:-------------------:|:--------------------:|:-------------------:|
| ![Progress](assets/screenshots/progress.png) | ![Class Success](assets/screenshots/class_success.png) | ![Exam Success](assets/screenshots/exam_success.png) |

### 👁️ Routine Viewing & Conflicts

| View Routine (Class) | View Routine (Exam) | Conflict Resolution |
|:--------------------:|:-------------------:|:-------------------:|
| ![View Class](assets/screenshots/view_class.png) | ![View Exam](assets/screenshots/view_exam.png) | ![Conflicts](assets/screenshots/conflicts.png) |

| Workload Summary | Section Merging | Room Assignment |
|:----------------:|:---------------:|:---------------:|
| ![Workload](assets/screenshots/workload.png) | ![Merge](assets/screenshots/merge.png) | ![Assign Rooms](assets/screenshots/assign.png) |

### 👨‍🏫 Teacher Module

| Teacher Dashboard | Teacher Profile | Availability |
|:-----------------:|:---------------:|:------------:|
| ![Teacher Dashboard](assets/screenshots/teacher_dashboard.png) | ![Teacher Profile](assets/screenshots/teacher_profile.png) | ![Availability](assets/screenshots/availability.png) |

| Interested Courses | Personal Routine | Teacher Settings |
|:------------------:|:----------------:|:----------------:|
| ![Interested](assets/screenshots/interested.png) | ![Routine](assets/screenshots/teacher_routine.png) | ![Settings](assets/screenshots/teacher_settings.png) |

### ⚙️ Profile & Settings

| Profile | Edit Profile | Settings |
|:-------:|:------------:|:--------:|
| ![Profile](assets/screenshots/profile.png) | ![Edit](assets/screenshots/edit_profile.png) | ![Settings](assets/screenshots/settings.png) |

---

## 🚀 Installation Guide

### Prerequisites
- ✅ Flutter SDK ≥ 3.10.0
- ✅ Dart SDK ≥ 3.0.0
- ✅ Android Studio / VS Code with Flutter extension
- ✅ Android SDK 35 (compileSdk)
- ✅ Android NDK 27.0.12077973
- ✅ A physical device or emulator (Android 6.0+)

### Setup Instructions

```bash
# 1️⃣ Clone the repository
git clone https://github.com/your-username/academic-scheduler-flutter-app.git
cd academic-scheduler-flutter-app

# 2️⃣ Install dependencies
flutter pub get

# 3️⃣ Verify environment
flutter doctor

# 4️⃣ Run the application
flutter run

# 5️⃣ Build a release APK
flutter build apk --release
```

### 🔑 Default Credentials

| Role | Email | Password |
|:----:|:------|:---------|
| **Admin** | `admin@university.edu` | `admin123` |
| **Teacher** | `teacher@university.edu` | `teacher123` |

---

## 📂 Project Structure
academic-scheduler-flutter-app/
├── 📁 android/ # Android-specific configuration
├── 📁 assets/
│ ├── 📁 images/ # Logos and graphics
│ └── 📁 screenshots/ # Application screenshots
├── 📁 lib/
│ ├── 📁 data/
│ │ └── 📁 models/ # Data models
│ │ ├── batch_model.dart
│ │ ├── course_model.dart
│ │ ├── department_model.dart
│ │ ├── room_model.dart
│ │ ├── routine_model.dart
│ │ └── teacher_model.dart
│ ├── 📁 providers/ # State management
│ │ ├── auth_provider.dart
│ │ ├── batch_provider.dart
│ │ ├── course_provider.dart
│ │ ├── dashboard_provider.dart
│ │ ├── department_provider.dart
│ │ ├── merge_provider.dart
│ │ ├── profile_provider.dart
│ │ ├── room_provider.dart
│ │ ├── routine_provider.dart
│ │ ├── settings_provider.dart
│ │ ├── teacher_provider.dart
│ │ └── theme_provider.dart
│ ├── 📁 presentation/
│ │ ├── 📁 screens/
│ │ │ ├── 📁 admin/ # Admin module
│ │ │ ├── 📁 teacher/ # Teacher module
│ │ │ ├── login_screen.dart
│ │ │ └── splash_screen.dart
│ │ └── 📁 widgets/ # Reusable widgets
│ ├── 📁 utils/ # Helpers and utilities
│ └── main.dart # Entry point
├── 📁 test/ # Unit & widget tests
├── pubspec.yaml # Dependencies manifest
└── README.md # This document

---

## 🧠 Scheduling Algorithm

The core scheduling engine implements a **Constraint Satisfaction Problem (CSP)** approach combined with **greedy heuristics**:

### Algorithm Overview
INPUT
├── Courses with credit hours
├── Teachers with availability
├── Rooms with capacity
├── Batches and program types
└── Time slots and working days

PREPROCESSING
├── Validate inputs
├── Compute teacher workload limits
└── Build constraint matrix

ASSIGNMENT (per course)
├── Filter qualified teachers
├── Find compatible time slots
├── Check room availability
├── Verify no double-booking
└── Commit assignment

VALIDATION
├── Detect time conflicts
├── Detect resource conflicts
└── Calculate workload distribution

OUTPUT
├── Generated routine
├── Conflict report
└── Workload summary

### Core Constraints

- ✅ **No teacher double-booking** within same time slot
- ✅ **No room double-booking** within same time slot
- ✅ **No batch double-booking** within same time slot
- ✅ **Credit-hour respect** for course time allocation
- ✅ **Teacher workload limits** to prevent overload
- ✅ **Configurable gap-days** between exams (exam routine)

---

## 🗄️ Database Schema
┌─────────────────┐ ┌─────────────────┐
│ departments │ │ teachers │
├─────────────────┤ ├─────────────────┤
│ id (PK) │ │ id (PK) │
│ name │◄────────┤ department_id │
│ code │ │ name │
└─────────────────┘ │ email │
▲ │ phone │
│ │ designation │
│ └─────────────────┘
│ ▲
┌────────┴────────┐ │
│ batches │ ┌────────┴────────┐
├─────────────────┤ │ courses │
│ id (PK) │◄────────┤ id (PK) │
│ batch_no │ │ batch_id (FK) │
│ program_type │ │ teacher_id (FK) │
│ department_id │ │ code │
└─────────────────┘ │ title │
▲ │ credit │
│ └─────────────────┘
│ ▲
┌────────┴────────┐ │
│ routines │ │
├─────────────────┤ │
│ id (PK) │──────────────────┘
│ batch_id (FK) │ ┌─────────────────┐
│ course_id (FK) │ │ rooms │
│ teacher_id (FK) │ ├─────────────────┤
│ room_id (FK) │◄────────┤ id (PK) │
│ day │ │ room_no │
│ slot │ │ floor │
│ type │ │ capacity │
│ date │ └─────────────────┘
└─────────────────┘


---

## 🔮 Future Enhancements

- ☁️ **Cloud Sync** with Firebase Firestore for multi-device access
- 🔔 **Push Notifications** when new routines are published
- 🎓 **Student Portal** with personalized schedule and reminders
- 🌍 **Multi-Language Support** (Bangla, English, Arabic)
- 📊 **Advanced Analytics Dashboard** with utilization heatmaps
- 🤖 **AI-Powered Suggestions** for optimal teacher-course matching
- 📲 **iOS Release** for cross-platform parity
- 🌐 **Web Dashboard** for desktop coordinators
- 📧 **Email/SMS Notifications** for schedule changes
- 🔄 **Real-Time Collaboration** for multi-admin environments
- 📈 **Historical Data Analytics** across semesters
- 🎯 **Genetic Algorithm** for global schedule optimization

---

## 👥 Contributors

<table align="center">
  <tr>
    <td align="center">
      <strong>Md. Arif Hasan</strong><br/>
      <sub>ID: 0322320105101029</sub><br/>
      <sub>Lead Developer & UI/UX</sub>
    </td>
    <td align="center">
      <strong>Md. Musfique Anam Ananto</strong><br/>
      <sub>ID: 0322320105101039</sub><br/>
      <sub>Backend & Algorithm Engineer</sub>
    </td>
  </tr>
</table>

### 🤝 Contribution Guidelines

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

---

## 📜 License & Acknowledgements

### License
This project is developed for academic purposes as part of **CSE 3102 — Mobile Application Development Sessional** at Pundra University of Science & Technology, Bogura.

### 🙏 Acknowledgements

- **Md. Forhan Shahriar Fahim** — Course Instructor, for guidance and mentorship
- **Department of Computer Science and Engineering, PUB** — For institutional support
- **Flutter & Dart Communities** — For the exceptional framework and ecosystem
- **Material Design Team at Google** — For design system inspiration
- **Open-Source Contributors** — Whose packages power this project

---

## 📞 Contact & Support

For questions, suggestions, or collaboration inquiries:

- 📧 **Arif Hasan:** `arif.hasan@students.pub.ac.bd`
- 📧 **Musfique Anam Ananto:** `musfique.ananto@students.pub.ac.bd`
- 🏛️ **Department:** Computer Science and Engineering
- 🏛️ **University:** Pundra University of Science & Technology, Bogura

---

<div align="center">

### ⭐ If this project helped you, please consider giving it a star! ⭐

**Built with ❤️ and ☕ in Bogura, Bangladesh**

*— Pundra University of Science & Technology, CSE Batch 23 —*

`Version 1.0.0` • `May 2026`

</div>