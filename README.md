# 📅 Employee Shift Management System

A modern Flutter and Firebase-based Employee Shift Management application designed for organisations to manage employee availability, shift scheduling, attendance tracking, breaks, leave requests, notifications, and analytics through an intuitive calendar-driven interface.

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
Log in using phone number and password
Upload profile photo
Submit shift availability using the calendar
View approved and rejected shifts
Check in to shift
Start and end breaks
Check out of the shift
Apply for leave
View leave status
Receive notifications from the admin
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
<img width="853" height="1844" alt="ChatGPT Image Jun 19, 2026, 08_19_53 PM" src="https://github.com/user-attachments/assets/6459ecac-d352-47d5-ade1-b80b958678a4" />

Admin Home Page
<img width="1024" height="1536" alt="ChatGPT Image Jun 19, 2026, 08_22_18 PM" src="https://github.com/user-attachments/assets/d3d753f4-8149-4115-a800-ef1865d26247" />

Admin Dashboard
<img width="853" height="1844" alt="ChatGPT Image Jun 19, 2026, 08_30_09 PM" src="https://github.com/user-attachments/assets/539bfbdb-c74c-4d9e-815d-1cacbb2a34e9" />


Admin Shift Calendar
<img width="1024" height="1536" alt="ChatGPT Image Jun 19, 2026, 08_48_05 PM" src="https://github.com/user-attachments/assets/202261ea-d95c-4630-9641-4fa3bbd48c5b" />


Employee Home Page
<img width="853" height="1844" alt="ChatGPT Image Jun 19, 2026, 08_31_26 PM" src="https://github.com/user-attachments/assets/5bbaf54f-6aa4-494d-b456-4062234a5444" />


Employee Shift Calendar
<img width="1024" height="1536" alt="ChatGPT Image Jun 19, 2026, 08_44_30 PM" src="https://github.com/user-attachments/assets/5738076b-8996-4214-a85d-96ee67213ee6" />


App screenshots:

<img width="853" height="1844" alt="ChatGPT Image Jun 19, 2026, 09_10_48 PM" src="https://github.com/user-attachments/assets/1bcf1efb-3219-41ec-9356-7b4034d202ee" />

<img width="837" height="1880" alt="ChatGPT Image Jun 19, 2026, 08_24_00 PM" src="https://github.com/user-attachments/assets/edd1eda8-42ff-498d-8922-65fde311c6b9" />

<img width="852" height="1846" alt="ChatGPT Image Jun 19, 2026, 08_33_57 PM" src="https://github.com/user-attachments/assets/cc211523-5e0f-47b6-9849-5c32e464ffa7" />




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
