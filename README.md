# 📅 Employee Shift Management System

A modern Flutter and Firebase based Employee Shift Management application designed for organizations to manage employee availability, shift scheduling, attendance tracking, breaks, leave requests, notifications, and analytics through an intuitive calendar-driven interface.

🚀 Features
👨‍💼 Admin Module
Add, edit and delete employees
Employee profile management
Shift approval and rejection workflow
Assign break timings during shift approval
View employee attendance records
View check-in, break start/end and check-out timestamps
Manage employee leave requests
Real-time notifications
Dashboard and analytics screen
Calendar-based shift management
👷 Employee Module
Login using phone number and password
Upload profile photo
Submit shift availability using calendar
View approved and rejected shifts
Check in to shift
Start and end breaks
Check out from shift
Apply for leave
View leave status
Receive notifications from admin
Calendar-based shift tracking
📊 Dashboard Analytics

Admin dashboard provides:

Total Employees
Pending Shift Requests
Approved Shifts
Rejected Shifts
Employees Checked In
Employees On Break
Employees Checked Out
Pending Leave Requests

Each dashboard card is clickable and displays detailed employee information.

🔔 Notification System

Real-time notification support for:

Employee Notifications
Shift Approved
Shift Rejected
Break Assigned
Leave Approved
Leave Rejected
Admin Notifications
Employee Checked In
Employee Started Break
Employee Ended Break
Employee Checked Out
New Availability Submitted
New Leave Request
📅 Calendar Based Scheduling

Instead of traditional list views, the application uses a calendar-first approach.

Employee Calendar
Select availability dates
Submit availability
View shift details
View attendance status
View break timings
Admin Calendar
View all employee shifts
Approve or reject requests
Assign break timings
Monitor attendance records
🛠 Tech Stack
Frontend
Flutter
Dart
Backend
Firebase Firestore
Firebase Authentication
State Management
Stateful Widgets
StreamBuilder
Database
Cloud Firestore
UI Components
Material Design
Table Calendar
Custom Dialogs
Responsive Layouts
🏗 Architecture

The application follows a service-based architecture:

UI Layer
    ↓
Firestore Service Layer
    ↓
Firebase Firestore

Main components:

lib/
│
├── pages/
│   ├── admin_page.dart
│   ├── employee_page.dart
│   ├── admin_shift_calendar.dart
│   ├── employee_shift_calendar.dart
│   ├── dashboard_page.dart
│   ├── notifications_page.dart
│
├── services/
│   ├── firestore_service.dart
│
├── widgets/
│
└── main.dart
📂 Firestore Structure
employees
│
├── employeeDocID
│   │
│   ├── name
│   ├── phone
│   ├── email
│   ├── role
│   │
│   ├── availability
│   │     └── shift documents
│   │
│   ├── leave_requests
│   │     └── leave documents
│   │
│   └── notifications
│         └── notification documents
📱 Screenshots
Login Screen

Add screenshot here

![Login](screenshots/login.png)
Admin Dashboard

Add screenshot here

![Dashboard](screenshots/dashboard.png)
Admin Shift Calendar

Add screenshot here

![Admin Calendar](screenshots/admin_calendar.png)
Employee Shift Calendar

Add screenshot here

![Employee Calendar](screenshots/employee_calendar.png)
Leave Management

Add screenshot here

![Leave Management](screenshots/leave.png)
Notifications

Add screenshot here

![Notifications](screenshots/notifications.png)
🎯 Real World Use Cases
Restaurants
Hotels
Retail Stores
Warehouses
Hospitals
Security Agencies
Event Management Companies
Small and Medium Businesses
🔮 Future Enhancements
Push Notifications using Firebase Cloud Messaging
Biometric Login
QR Code Check-In
GPS Based Attendance
Shift Swapping
Payroll Integration
PDF Attendance Reports
Dark Mode
Multi-Admin Support
Employee Performance Tracking
👨‍💻 Developed By

Gaurav Chandra

Senior Android / Flutter Developer

Skills Used
Flutter
Dart
Firebase
Firestore
Mobile UI/UX
Android Development
Calendar Scheduling Systems
Attendance Management Systems
