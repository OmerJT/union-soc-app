# UniSoc Full-Stack Coursework 2 Project

UniSoc is a three-tier university society management system built with a Flutter frontend, Django REST Framework backend and SQLite database.

## Implemented requirements

- Secure registration and login using Django password hashing and JWT tokens.
- Student and society-admin roles.
- Society search and category filtering.
- Join and leave society workflow with duplicate membership protection.
- My Societies page with per-society notification opt in/out.
- Event list with a simple calendar strip, description, location, capacity, spaces remaining and RSVP count.
- RSVP button for event attendance tracking.
- In-app notifications generated when admins create, update or remove events.
- Account settings screen for email, name, password and global notification preference.
- Forgot-password prototype using reset tokens.
- Society chat box between users and admins.
- Admin dashboard for creating/updating societies, creating/editing/deleting events and setting capacity limits.
- Admin audit logs for account, membership, notification, RSVP, event and society actions.
- Attendance report export endpoint in CSV format.
- Backend automated tests and a Flutter widget smoke test.

## Backend setup

```bash
cd unisoc_backend
python -m venv venv
source venv/bin/activate  # Windows: venv\Scripts\activate
pip install -r requirements.txt
python manage.py migrate
python manage.py runserver
```

## Frontend setup

```bash
cd unisoc_app
flutter pub get
flutter run -d chrome
```

The Flutter app expects the backend to run at:

```text
http://127.0.0.1:8000/api
```

## Running tests

Backend:

```bash
cd unisoc_backend
python manage.py test
```

Backend coverage:

```bash
pip install coverage
coverage run manage.py test
coverage report
```

Flutter:

```bash
cd unisoc_app
flutter test
```

## Main API endpoints

| Feature | Endpoint |
|---|---|
| Register | `POST /api/auth/register/` |
| Login | `POST /api/auth/login/` |
| Current profile | `GET/PATCH /api/auth/me/` |
| Forgot password | `POST /api/auth/forgot-password/` |
| Reset password | `POST /api/auth/reset-password/` |
| Societies | `GET/POST /api/societies/` |
| Society detail/update | `GET/PATCH/DELETE /api/societies/<id>/` |
| Join society | `POST /api/societies/<id>/join/` |
| Leave society | `POST /api/societies/<id>/leave/` |
| Per-society notification preference | `PATCH /api/societies/<id>/notification-preference/` |
| Society chat | `GET/POST /api/societies/<id>/chat/` |
| Events | `GET /api/events/` |
| Admin create event | `POST /api/events/create/` |
| Admin edit event | `PATCH /api/events/<id>/edit/` |
| Admin delete event | `DELETE /api/events/<id>/delete/` |
| RSVP | `POST /api/events/<id>/rsvp/` |
| Notifications | `GET /api/notifications/` |
| Attendance CSV | `GET /api/admin/attendance-report/` |
| Audit logs | `GET /api/admin/audit-logs/` |

## Coursework evidence to screenshot

- GitHub commit history and branches.
- Issue tracking and pull requests.
- README and code comments.
- Backend tests passing and coverage report.
- Flutter tests passing.
- Student demo flow: register/login, browse, filter, join, My Societies, chat, events, RSVP, notifications, settings.
- Admin demo flow: create society, create event, edit event, delete event, view logs, export attendance CSV.
