# UniSoc - Our University Society App

Hey there! This is our coursework 2 project - UniSoc, a full-stack app for managing university societies. We built it with Flutter for the mobile/web frontend and Django REST Framework for the backend, using SQLite for the database.

## What We Built

We got all the main requirements working:

- Secure sign up and login with Django's password hashing and JWT tokens
- Two types of users: students and society admins
- You can search for societies and filter by category
- Join and leave societies, but no duplicates
- A 'My Societies' page with per-society notification settings
- Event list with a simple calendar, showing details, capacity, spots left, and RSVP count
- RSVP button for signing up to events
- In-app notifications when admins add, change, or delete events
- Settings page for email, name, password, and global notifications
- Forgot password feature with reset tokens
- Chat in societies between members and admins
- Admin dashboard to create/update societies, manage events, set capacities
- Audit logs for admins to track actions
- CSV export for attendance reports
- Automated tests for backend and a simple Flutter test

## Setting Up the Backend

To get the backend running:

1. Go to the unisoc_backend folder
2. Create a virtual environment: python -m venv venv
3. Activate it: venv\Scripts\activate (on Windows)
4. Install packages: pip install -r requirements.txt
5. Run migrations: python manage.py migrate
6. Start the server: python manage.py runserver

## Setting Up the Frontend

For the Flutter app:

1. Go to unisoc_app
2. Get dependencies: flutter pub get
3. Run on web: flutter run -d chrome

The app expects the backend at http://127.0.0.1:8000/api

## Running Tests

Backend tests:

cd unisoc_backend
python manage.py test

For coverage:

pip install coverage
coverage run manage.py test
coverage report

Flutter tests:

cd unisoc_app
flutter test

## API Endpoints

Here's the main API:

- POST /api/auth/register/ - Sign up
- POST /api/auth/login/ - Log in
- GET/PATCH /api/auth/me/ - Get/update profile
- POST /api/auth/forgot-password/ - Forgot password
- POST /api/auth/reset-password/ - Reset password
- GET/POST /api/societies/ - List/create societies
- GET/PATCH/DELETE /api/societies/<id>/ - Society details
- POST /api/societies/<id>/join/ - Join society
- POST /api/societies/<id>/leave/ - Leave society
- PATCH /api/societies/<id>/notification-preference/ - Set notifications per society
- GET/POST /api/societies/<id>/chat/ - Society chat
- GET /api/events/ - List events
- POST /api/events/create/ - Admin create event
- PATCH /api/events/<id>/edit/ - Admin edit event
- DELETE /api/events/<id>/delete/ - Admin delete event
- POST /api/events/<id>/rsvp/ - RSVP to event
- GET /api/notifications/ - Get notifications
- GET /api/admin/attendance-report/ - CSV report
- GET /api/admin/audit-logs/ - Audit logs

## Coursework 2 Details

### Changes We Made

During development, we tweaked some things to make it work better.

**Added features:**
- Password reset - really useful for users
- Audit logs - to track what's happening
- Notification preferences - global and per society
- Chat - for communication
- Attendance export - for admins

**Modified:**
- Event capacity - now shows spots remaining and prevents overbooking        
- User roles - students need UP numbers, admins don't
- Society management - added search and categories

**Discarded:**
- Email notifications - used in-app instead for easier testing
- Full calendar - kept it simple

**Why we changed things:** Some original ideas were too hard, so we simplified while keeping the core. Added user-friendly features. This added more models and endpoints, but made it better.

### Design Changes

Architecture stayed three-tier, but we added models for chat, logs, etc.      

API got more endpoints with validation.

State management in Flutter got better with a central auth service.

Use cases: registration with UP validation, events with capacity, in-app notifications.

### Implementation

We recorded a demo video showing everything.

For version control, we have 15 commits with incremental changes.

Code is well commented.

Tests: 19 backend, 2 frontend, all passing.

**Issues we faced:**
- Cross-platform rendering - fixed with Material 3
- State management - refactored to AuthService
- Error handling - added user-friendly messages
- Database relationships - used Django's features
- Async tests - used proper mocking

**Lessons:** Incremental development, test early, document as you go.

### Testing

We used equivalence partitioning, boundary values, state transitions.

Test cases cover all modules: auth, societies, events, etc.

19 backend tests, 2 frontend, 100% pass.

See TEST_PLAN.md for details.

### Critical Analysis

**Leadership:** As a team, we led the project, chose the stack, set standards.

**Progress:** Daily commits, tests before completion.

**Conflicts:** Technical issues resolved by research and refactoring.

**Lessons:** Start testing early, document, version control, API first, UX focus, incremental, cross-platform.
