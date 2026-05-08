#!/bin/bash
# UniSoc Demo Setup Script
# This script sets up the UniSoc system with sample data for demonstration

echo "Setting up UniSoc Demo Environment..."

# Backend setup
echo "Setting up backend..."
cd unisoc_backend
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
pip install -r requirements.txt
python manage.py migrate

# Create sample users
echo "Creating sample users..."
python manage.py shell << EOF
from django.contrib.auth.models import User
from api.models import UserProfile, Society, Membership, Event

# Create admin user
admin_user = User.objects.create_user(username='admin', email='admin@university.edu', password='admin123', first_name='Admin', last_name='User')
admin_profile = UserProfile.objects.create(user=admin_user, role='admin')

# Create regular users
users_data = [
    ('student1', 'student1@university.edu', 'Student One', 'UP123456'),
    ('student2', 'student2@university.edu', 'Student Two', 'UP234567'),
    ('student3', 'student3@university.edu', 'Student Three', 'UP345678'),
]

for username, email, full_name, up_number in users_data:
    first_name, last_name = full_name.split()
    user = User.objects.create_user(username=username, email=email, password='password123', first_name=first_name, last_name=last_name)
    UserProfile.objects.create(user=user, up_number=up_number, role='user')

print("Sample users created successfully")
EOF

# Create sample societies and data
python manage.py shell << EOF
from django.contrib.auth.models import User
from api.models import UserProfile, Society, Membership, Event, RSVP
from django.utils import timezone

admin_profile = UserProfile.objects.get(user__username='admin')

# Create societies
societies_data = [
    ('Computer Science Society', 'academic', 'Tech enthusiasts and programming club'),
    ('Football Society', 'sports', 'University football team and fans'),
    ('Drama Society', 'cultural', 'Theatre and performing arts'),
    ('Chess Club', 'extracurricular', 'Strategic minds welcome'),
]

societies = []
for name, category, description in societies_data:
    society = Society.objects.create(
        name=name,
        category=category,
        description=description,
        admin=admin_profile
    )
    societies.append(society)

# Create memberships
students = UserProfile.objects.filter(role='user')
for society in societies:
    # Add some students to each society
    for student in students[:2]:  # First 2 students join each society
        Membership.objects.create(user=student, society=society)

# Create events
from datetime import timedelta
base_time = timezone.now()

events_data = [
    (societies[0], 'Python Workshop', 'Learn Python basics', base_time + timedelta(days=7), 20),
    (societies[0], 'AI Seminar', 'Introduction to Artificial Intelligence', base_time + timedelta(days=14), 30),
    (societies[1], 'Football Match', 'Inter-university friendly match', base_time + timedelta(days=10), 50),
    (societies[2], 'Drama Auditions', 'Join our theatre production', base_time + timedelta(days=5), 15),
    (societies[3], 'Chess Tournament', 'Annual chess championship', base_time + timedelta(days=21), 32),
]

for society, title, description, start_time, capacity in events_data:
    Event.objects.create(
        society=society,
        created_by=admin_profile,
        title=title,
        description=description,
        location='Campus Venue',
        start_time=start_time,
        end_time=start_time + timedelta(hours=2),
        capacity_limit=capacity,
        is_public=True
    )

# Create some RSVPs
events = Event.objects.all()
for event in events:
    members = event.society.memberships.all()[:3]  # First 3 members RSVP
    for membership in members:
        RSVP.objects.create(
            event=event,
            user=membership.user,
            is_attending=True
        )

print("Sample data created successfully!")
print(f"Created {len(societies)} societies, {Event.objects.count()} events, {RSVP.objects.count()} RSVPs")
EOF

echo "Backend setup complete!"

# Start backend server
echo "Starting Django server..."
python manage.py runserver &
BACKEND_PID=$!

cd ..

# Frontend setup
echo "Setting up frontend..."
cd unisoc_app
flutter pub get

echo "Demo setup complete!"
echo ""
echo "Demo Accounts:"
echo "Admin: username='admin', password='admin123'"
echo "Students: username='student1/2/3', password='password123'"
echo ""
echo "To run the demo:"
echo "1. Backend is running at http://127.0.0.1:8000"
echo "2. Run Flutter app: flutter run -d chrome"
echo ""
echo "Press Ctrl+C to stop the backend server"

# Wait for user interrupt
trap "kill $BACKEND_PID; exit" INT
wait