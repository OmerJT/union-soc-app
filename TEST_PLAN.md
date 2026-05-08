# UniSoc Test Plan

## 1. Introduction

This document outlines the comprehensive test plan for the UniSoc university society management system. The system consists of a Flutter mobile application frontend and a Django REST API backend with SQLite database.

## 2. Test Objectives

- Ensure all functional requirements are implemented and working correctly
- Validate security features (authentication, authorization)
- Test data integrity and validation
- Verify cross-platform compatibility
- Achieve high test coverage for both backend and frontend

## 3. Test Scope

### 3.1 In Scope
- User authentication (registration, login, password reset)
- Society management (CRUD operations, membership)
- Event management (creation, RSVP, capacity tracking)
- Notification system
- Chat functionality
- Admin features
- API endpoints
- UI components and user flows

### 3.2 Out of Scope
- Performance testing under high load
- Security penetration testing
- Browser compatibility testing (limited to Flutter web)
- Mobile device testing (limited to emulator/simulation)

## 4. Test Strategy

### 4.1 Backend Testing (Django REST Framework)
- **Unit Tests**: Test individual functions, methods, and model behaviors
- **Integration Tests**: Test API endpoints with database interactions
- **Authentication Tests**: Verify JWT token handling and permissions
- **Data Validation Tests**: Ensure proper input validation and error handling

### 4.2 Frontend Testing (Flutter)
- **Widget Tests**: Test UI components and their interactions
- **Integration Tests**: Test complete user flows
- **State Management Tests**: Verify Provider pattern implementation

### 4.3 Manual Testing
- End-to-end user scenarios
- UI/UX validation
- Cross-platform functionality

## 4.4 Test Case Design Methodology

### Equivalence Partitioning
Input data is divided into valid and invalid partitions to ensure comprehensive coverage:

**User Registration Partitions:**
- **Valid UP Numbers**: UP123456, UP999999 (format: UP followed by 6 digits)
- **Invalid UP Numbers**: UP12345 (too short), UP1234567 (too long), UPABC123 (non-numeric)
- **Admin Exemption**: Empty UP number field for admin role

**Password Complexity Partitions:**
- **Valid Passwords**: Password123 (meets complexity requirements)
- **Invalid Passwords**: password (no uppercase/capital), Password (no numbers), Pass1 (too short)

**Event Capacity Partitions:**
- **Valid Capacities**: 1-1000 (reasonable range for university events)
- **Invalid Capacities**: 0 (no capacity), -1 (negative), 10000 (excessive)

### Boundary Value Analysis
Testing at the edges of input ranges:

**String Length Boundaries:**
- **Username**: 1 character (minimum), 150 characters (Django default max), 151+ characters (overflow)
- **Society Description**: Empty string, 1000 characters (reasonable limit), 10000+ characters (excessive)

**Numeric Boundaries:**
- **Event Capacity**: 0 (invalid), 1 (minimum valid), 1000 (maximum reasonable), 1001 (overflow)
- **RSVP Count**: 0 (no attendees), capacity-1 (almost full), capacity (exactly full), capacity+1 (overbooked)

### State Transition Testing
Testing system state changes and transitions:

**User State Transitions:**
- Unregistered → Registered (successful registration)
- Registered → Authenticated (successful login)
- Authenticated → Society Member (join society)
- Society Member → Event Attendee (successful RSVP)

**Event State Transitions:**
- Created → RSVP Open (default state)
- RSVP Open → At Capacity (when capacity reached)
- At Capacity → Completed (event end time passed)

**Authentication State Transitions:**
- Logged Out → Logged In (successful authentication)
- Logged In → Token Expired (JWT expiry)
- Token Expired → Re-authenticated (token refresh or re-login)

## 5. Test Environment

- **Backend**: Python 3.8+, Django 4.2+, SQLite
- **Frontend**: Flutter 3.6+, Dart SDK
- **Testing Frameworks**: Django TestCase, Flutter test package
- **CI/CD**: Local execution with coverage reporting

## 6. Test Cases

### 6.1 Authentication Module

| Test Case ID | Description | Type | Expected Result |
|-------------|-------------|------|-----------------|
| AUTH-001 | User registration with valid data | Integration | 201 Created, user created |
| AUTH-002 | User registration with duplicate username | Integration | 400 Bad Request |
| AUTH-003 | User login with correct credentials | Integration | 200 OK, JWT token returned |
| AUTH-004 | User login with incorrect credentials | Integration | 401 Unauthorized |
| AUTH-005 | Password reset request | Integration | 200 OK, reset token generated |
| AUTH-006 | Password reset with valid token | Integration | 200 OK, password updated |
| AUTH-007 | Password reset with expired token | Integration | 400 Bad Request |
| AUTH-008 | Access protected endpoint without token | Integration | 401 Unauthorized |
| AUTH-009 | Access protected endpoint with invalid token | Integration | 401 Unauthorized |
| AUTH-010 | Access admin endpoint as regular user | Integration | 403 Forbidden |

### 6.2 Society Management Module

| Test Case ID | Description | Type | Expected Result |
|-------------|-------------|------|-----------------|
| SOC-001 | List all societies | Integration | 200 OK, societies returned |
| SOC-002 | Filter societies by category | Integration | 200 OK, filtered results |
| SOC-003 | Search societies by name | Integration | 200 OK, matching societies |
| SOC-004 | Create society as admin | Integration | 201 Created, society created |
| SOC-005 | Create society as regular user | Integration | 403 Forbidden |
| SOC-006 | Update society as admin | Integration | 200 OK, society updated |
| SOC-007 | Update society as non-admin | Integration | 403 Forbidden |
| SOC-008 | Join society | Integration | 201 Created, membership created |
| SOC-009 | Join same society twice | Integration | 400 Bad Request |
| SOC-010 | Leave society | Integration | 200 OK, membership removed |
| SOC-011 | Leave society not member of | Integration | 404 Not Found |

### 6.3 Event Management Module

| Test Case ID | Description | Type | Expected Result |
|-------------|-------------|------|-----------------|
| EVT-001 | List events | Integration | 200 OK, events returned |
| EVT-002 | Create event as society admin | Integration | 201 Created, event created |
| EVT-003 | Create event as non-admin | Integration | 403 Forbidden |
| EVT-004 | Update event as admin | Integration | 200 OK, event updated |
| EVT-005 | Delete event as admin | Integration | 204 No Content |
| EVT-006 | RSVP to event as member | Integration | 200 OK, RSVP created |
| EVT-007 | RSVP to event as non-member | Integration | 403 Forbidden |
| EVT-008 | RSVP to full event | Integration | 400 Bad Request |
| EVT-009 | Cancel RSVP | Integration | 200 OK, RSVP removed |
| EVT-010 | Event capacity tracking | Unit | Correct spaces_remaining calculation |

### 6.4 Notification Module

| Test Case ID | Description | Type | Expected Result |
|-------------|-------------|------|-----------------|
| NOT-001 | List user notifications | Integration | 200 OK, notifications returned |
| NOT-002 | Mark notification as read | Integration | 200 OK, notification updated |
| NOT-003 | Event creation triggers notifications | Integration | Notifications created for members |
| NOT-004 | Notification preferences respected | Integration | Users with disabled notifications don't receive them |

### 6.5 Chat Module

| Test Case ID | Description | Type | Expected Result |
|-------------|-------------|------|-----------------|
| CHAT-001 | Send message as member | Integration | 201 Created, message saved |
| CHAT-002 | Send message as non-member | Integration | 403 Forbidden |
| CHAT-003 | List chat messages | Integration | 200 OK, messages returned |
| CHAT-004 | Messages ordered by timestamp | Unit | Correct ordering |

### 6.6 Admin Module

| Test Case ID | Description | Type | Expected Result |
|-------------|-------------|------|-----------------|
| ADM-001 | Export attendance report | Integration | 200 OK, CSV file returned |
| ADM-002 | View audit logs | Integration | 200 OK, logs returned |
| ADM-003 | Audit log creation on actions | Integration | Logs created for key actions |

### 6.7 Frontend Widget Tests

| Test Case ID | Description | Type | Expected Result |
|-------------|-------------|------|-----------------|
| UI-001 | Login screen renders correctly | Widget | All UI elements present |
| UI-002 | Registration form validation | Widget | Proper error messages |
| UI-003 | Navigation between screens | Widget | Correct screen transitions |
| UI-004 | Society list displays correctly | Widget | Societies shown with details |
| UI-005 | Event RSVP functionality | Widget | RSVP state updates |
| UI-006 | Admin panel access control | Widget | Admin features visible only to admins |

## 7. Test Data

### 7.1 Test Users
- Regular user: student1 (UP123456)
- Admin user: admin1
- Additional test users as needed

### 7.2 Test Societies
- Computing Society (academic)
- Football Society (sports)
- Various categories for filtering tests

### 7.3 Test Events
- Past events
- Future events
- Full capacity events
- Public and private events

## 8. Test Execution

### 8.1 Backend Tests
```bash
cd unisoc_backend
python manage.py test
```

### 8.2 Frontend Tests
```bash
cd unisoc_app
flutter test
```

### 8.3 Coverage Reporting
```bash
# Backend coverage
pip install coverage
coverage run manage.py test
coverage report

# Frontend coverage (if available)
flutter test --coverage
```

## 9. Success Criteria

- All automated tests pass
- Backend test coverage > 80%
- Frontend test coverage > 70%
- No critical bugs in manual testing
- All major user flows functional
- API responses conform to specifications

## 10. Risk Assessment

- **High Risk**: Authentication bypass
- **Medium Risk**: Data corruption in concurrent operations
- **Low Risk**: UI styling inconsistencies

## 11. Test Schedule

- Unit tests: Continuous during development
- Integration tests: After feature completion
- End-to-end tests: Before release
- Regression tests: After bug fixes

## 12. Tools and Technologies

- **Backend**: Django TestCase, Coverage.py
- **Frontend**: Flutter test package
- **CI/CD**: GitHub Actions (planned)
- **Documentation**: This test plan document</content>
<parameter name="filePath">c:\Users\omerr\Downloads\unisoc_fullstack_coursework2\TEST_PLAN.md