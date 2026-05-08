# UniSoc Test Plan

Hey, this is how we tested our UniSoc app. It's a Flutter frontend with Django backend, and we wanted to make sure everything works properly.

## Goals

- Check all features are implemented right
- Test security like login and permissions
- Make sure data is validated correctly
- Ensure it works on different platforms
- Get good test coverage

## What We Tested

Basically everything: user auth, society stuff, events, notifications, chat, admin features, API, UI.

Not doing performance under load, security hacking, or testing on real devices.

## Testing Approach

**Backend (Django):**
- Unit tests for functions and models
- Integration tests for API with database
- Auth tests for JWT and permissions
- Validation tests for inputs

**Frontend (Flutter):**
- Widget tests for UI parts
- Integration for full flows
- State management tests

**Manual:**
- End-to-end scenarios
- UI checks
- Cross-platform

## How We Designed Tests

**Equivalence Partitioning:** Split inputs into good and bad groups.

For example, user registration: valid UP numbers like UP123456, invalid like too short or non-numeric. Admins skip UP.

Passwords: valid with uppercase/numbers, invalid weak ones.

Event capacity: 1-1000 good, 0 or negative bad.

**Boundary Values:** Test edges.

Usernames: 1 char min, 150 max.

Capacities: 0 bad, 1 min, 1000 max.

**State Changes:** Test transitions.

User: unregistered -> registered -> logged in -> member -> attendee.

Event: created -> open -> full -> done.

Auth: logged out -> in -> expired -> refresh.

## Test Setup

- Backend: Python 3.8+, Django, SQLite
- Frontend: Flutter, Dart
- Frameworks: Django tests, Flutter test
- Run locally with coverage

## Test Cases

### Auth

- Register with good data: should work
- Register duplicate: error
- Login correct: get token
- Login wrong: error
- Forgot password: send reset
- Reset with good token: update password
- Reset expired: error
- Protected endpoint no token: error
- Invalid token: error
- Admin endpoint as user: forbidden

### Societies

- List all: get list
- Filter by category: filtered
- Search by name: matches
- Create as admin: works
- Create as user: forbidden
- Update as admin: works
- Update as user: forbidden
- Join: membership created
- Join twice: error
- Leave: removed
- Leave not member: error

### Events

- List: get events
- Create as admin: works
- Create as user: forbidden
- Update as admin: works
- Delete as admin: works
- RSVP as member: works
- RSVP as non-member: forbidden
- RSVP full: error
- Cancel RSVP: works
- Capacity calc: correct

### Notifications

- List mine: get them
- Mark read: update
- Create event: notify members
- Preferences: respect settings

### Chat

- Send as member: works
- Send as non-member: forbidden
- List messages: get them
- Ordered by time: yes

### Admin

- Export attendance: CSV
- View logs: get them
- Logs created: yes

### Frontend

- Login screen: renders
- Register validation: errors
- Navigation: works
- Society list: shows
- RSVP: updates
- Admin access: only admins

## Test Data

- Users: student1 (UP123456), admin1
- Societies: Computing (academic), Football (sports)
- Events: past, future, full

## Running Tests

Backend:
cd unisoc_backend
python manage.py test

Frontend:
cd unisoc_app
flutter test

Coverage:
pip install coverage
coverage run manage.py test
coverage report

## Success

- All tests pass
- Backend >80% coverage
- Frontend >70%
- No big bugs manually
- All flows work
- API as spec

## Risks

- High: auth bypass
- Medium: data issues concurrent
- Low: UI looks

## Schedule

- Unit: always
- Integration: after features
- E2E: before release
- Regression: after fixes

## Tools

- Django TestCase, Coverage
- Flutter test
- GitHub Actions (maybe)
- This doc
