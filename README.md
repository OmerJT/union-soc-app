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

## Coursework 2 Implementation Details

### 3.1 Problem Specification

#### Changes Made to Initial Problem Specification

During the development of Coursework 2, several changes were made to the initial problem specification to improve feasibility, user experience, and technical implementation:

**Requirements Added:**
- **Password Reset Functionality**: Added forgot password and reset password features to improve user experience and security
- **Audit Logging**: Implemented comprehensive audit logs for all key actions to track system usage and troubleshooting
- **Notification Preferences**: Added granular notification controls (global + per-society) for better user customization
- **Chat Functionality**: Included society chat feature for member communication
- **Attendance Reporting**: Added CSV export functionality for admin attendance reports

**Requirements Modified:**
- **Event Capacity**: Changed from simple capacity tracking to include spaces remaining calculation and full event prevention
- **User Roles**: Expanded from basic user/admin to include UP number validation for students (admins exempt)
- **Society Management**: Enhanced with category filtering and search functionality for better discoverability

**Requirements Discarded:**
- **Email Notifications**: Replaced with in-app notifications for prototype demonstration (easier to implement and test)
- **Advanced Calendar Features**: Simplified to basic event listing with date filtering instead of full calendar integration

**Rationale for Changes:**
- **Technical Feasibility**: Some initial requirements were too complex for the timeframe; simplified versions maintained core functionality
- **User Experience**: Added features like password reset and chat based on user feedback and common app expectations
- **Testing Considerations**: Features were chosen/modified to ensure comprehensive test coverage was achievable

**Ripple Effects:**
- Added requirements increased database complexity (additional models for chat, audit logs)
- Modified authentication flow to include password reset endpoints
- Enhanced frontend with additional screens (chat, settings, notifications)
- Required additional API endpoints and testing scenarios

### 3.2 Design

#### Changes Made to System Architecture and Use Cases

**Architectural Changes:**

1. **Database Schema Evolution**:
   - **Initial Design**: Basic user-society-event relationships
   - **Final Design**: Added ChatMessage, AuditLog, PasswordResetRequest models
   - **Impact**: Improved data relationships and audit capabilities

2. **API Design Refinement**:
   - **Initial**: Basic CRUD operations
   - **Enhanced**: Added bulk operations, filtering, and complex validation
   - **Impact**: Better API usability and data consistency

3. **State Management Architecture**:
   - **Initial**: Simple Provider pattern
   - **Enhanced**: Centralized AuthService with comprehensive error handling
   - **Impact**: Improved app stability and user experience

**Use Case Modifications:**

1. **User Registration**:
   - **Added**: UP number validation for students, admin role exemption
   - **Rationale**: Better user role management and university-specific requirements

2. **Event Management**:
   - **Enhanced**: Capacity limits, RSVP tracking, attendance reporting
   - **Rationale**: More comprehensive event management for society admins

3. **Notification System**:
   - **Modified**: From email-based to in-app notifications with preferences
   - **Rationale**: Easier implementation and better user control

**Critical Analysis of Changes:**

The architectural changes improved system robustness and user experience while maintaining the core three-tier architecture. The decision to use in-app notifications over email simplified deployment and testing while still demonstrating notification functionality. The addition of audit logging provides valuable insights for system administration and troubleshooting.

**Evidence of New Architecture:**
- Updated Django models with additional relationships
- Enhanced API endpoints with validation and error handling
- Improved Flutter state management with comprehensive error handling
- Comprehensive test suite covering all new functionality

### 3.3 Implementation

#### A. Demo Video
A 3-5 minute demo video showcasing the complete UniSoc system functionality should be recorded and uploaded to a shareable platform (YouTube, Vimeo, or university platform).

**Demo Script Outline:**
1. **Introduction (30 seconds)**: Overview of UniSoc system and features
2. **User Registration & Login (45 seconds)**: Show student registration with UP number, admin registration, login process
3. **Society Discovery (60 seconds)**: Browse societies, search/filter by category, view society details
4. **Society Membership (45 seconds)**: Join societies, manage memberships, notification preferences
5. **Event Management (60 seconds)**: View events, RSVP functionality, capacity tracking
6. **Admin Features (60 seconds)**: Create/edit societies, manage events, view audit logs, export reports
7. **Communication Features (45 seconds)**: In-app notifications, society chat functionality
8. **Settings & Profile (30 seconds)**: Account settings, password reset, notification preferences

**Demo Requirements:**
- Clear audio narration explaining each feature
- Show both student and admin user flows
- Demonstrate error handling and validation
- Include actual app running (not just screenshots)
- Total length: 3-5 minutes
- High quality video with system clearly visible

**Video Link**: [To be updated with actual demo video URL after recording]

#### B. Version Control and Code Documentation
- **Git Repository**: Full version control with meaningful commit messages
- **Branching Strategy**: Feature branches for development (development, demo-feature)
- **Code Comments**: Comprehensive documentation in both backend and frontend code
- **Test Coverage**: 19 backend tests and 2 frontend widget tests, all passing

#### C. Implementation Issues Encountered

1. **Cross-Platform Compatibility**: 
   - Issue: Flutter web deployment had rendering inconsistencies
   - Solution: Used Material Design 3 components and tested across platforms
   - Impact: Ensured consistent UI across mobile and web

2. **State Management Complexity**:
   - Issue: Provider state management became complex with multiple nested screens
   - Solution: Refactored AuthService to handle all authentication state centrally
   - Impact: Improved code maintainability and reduced state-related bugs

3. **API Error Handling**:
   - Issue: Network failures weren't handled gracefully in the Flutter app
   - Solution: Added comprehensive error handling with user-friendly messages
   - Impact: Better user experience during network issues

4. **Database Relationships**:
   - Issue: Complex many-to-many relationships in Django models
   - Solution: Used Django's built-in relationship management and added proper validation
   - Impact: Data integrity maintained with proper cascading deletes

5. **Testing Async Operations**:
   - Issue: Flutter widget tests for async operations were flaky
   - Solution: Used proper test mocking and await patterns
   - Impact: Reliable test suite for UI components

### 3.4 Testing

#### Test Plan Coverage
See `TEST_PLAN.md` for comprehensive test plan covering all system units.

#### Automated Test Results
- **Backend Tests**: 19/19 passing (100% pass rate)
- **Frontend Tests**: 2/2 passing (100% pass rate)
- **Coverage**: Backend test coverage includes all models, views, and key business logic

#### Test Execution
```bash
# Backend tests
cd unisoc_backend && python manage.py test

# Frontend tests  
cd unisoc_app && flutter test
```

### 3.5 Critical Analysis

#### Leadership
As the project lead, I established the overall architecture and divided work into manageable tasks. I set up the development environment, initialized version control, and created the initial project structure. Leadership involved making technical decisions about the tech stack (Flutter + Django) and ensuring code quality standards were maintained throughout development.

#### Progress Monitoring
Progress was monitored through:
- Daily code commits with descriptive messages
- Regular testing to ensure functionality worked as expected
- Incremental development approach (backend first, then frontend integration)
- Git branching strategy to manage features separately

#### Conflict Resolution
The main conflicts encountered were technical challenges rather than team conflicts (solo project). These were resolved through:
- Research and documentation review (Django REST framework, Flutter state management)
- Incremental testing and debugging
- Refactoring code when initial approaches proved problematic
- Seeking solutions through official documentation and community resources

#### Lessons Learned
1. **Start with comprehensive testing**: Early test implementation prevented regression issues
2. **Document as you code**: Inline comments and README updates made the project more maintainable
3. **Version control best practices**: Meaningful commits and branching improved project organization
4. **API design first**: Designing the backend API before frontend implementation ensured consistency
5. **User experience focus**: Regular testing of user flows improved the overall application usability
