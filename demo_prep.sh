#!/bin/bash
# UniSoc Demo Preparation Script
# Run this before recording the demo video to populate the database with sample data

echo "Setting up UniSoc demo data..."

cd unisoc_backend

# Activate virtual environment
source venv/bin/activate  # Windows: .\venv\Scripts\activate

# Run migrations
python manage.py migrate

# Create demo data
python manage.py shell << 'EOF'
from django.contrib.auth.models import User
from api.models import UserProfile, Society, Membership, Event, RSVP, Notification
from django.utils import timezone
import random

print("Creating demo users...")

# Create admin user
admin_user = User.objects.create_user(
    username='demo_admin',
    email='admin@university.edu',
    password='admin123',
    first_name='Demo',
    last_name='Admin'
)
admin_profile = UserProfile.objects.create(user=admin_user, role='admin')

# Create student users
students_data = [
    ('alice_smith', 'alice@university.edu', 'Alice', 'Smith', 'UP2024001'),
    ('bob_jones', 'bob@university.edu', 'Bob', 'Jones', 'UP2024002'),
    ('carol_brown', 'carol@university.edu', 'Carol', 'Brown', 'UP2024003'),
    ('david_wilson', 'david@university.edu', 'David', 'Wilson', 'UP2024004'),
]

student_profiles = []
for username, email, first, last, up_num in students_data:
    user = User.objects.create_user(
        username=username,
        email=email,
        password='student123',
        first_name=first,
        last_name=last
    )
    profile = UserProfile.objects.create(user=user, up_number=up_num, role='user')
    student_profiles.append(profile)

print("Creating demo societies...")

# Create societies with different categories
societies_data = [
    ('Computer Science Society', 'academic', 'Programming workshops and tech talks'),
    ('Football Club', 'sports', 'University football team and training'),
    ('Drama Society', 'cultural', 'Theatre productions and performances'),
    ('Chess Club', 'extracurricular', 'Competitive chess tournaments'),
    ('Photography Club', 'extracurricular', 'Learn photography and editing'),
]

societies = []
for name, category, desc in societies_data:
    society = Society.objects.create(
        name=name,
        category=category,
        description=desc,
        admin=admin_profile,
        contact_email=f'{name.lower().replace(" ", "")}@university.edu',
        meeting_location='Campus Union Building'
    )
    societies.append(society)

print("Creating memberships...")

# Randomly assign students to societies
for society in societies:
    # Each society gets 2-3 random members
    members = random.sample(student_profiles, random.randint(2, 3))
    for profile in members:
        Membership.objects.create(
            user=profile,
            society=society,
            notifications_enabled=random.choice([True, False])
        )

print("Creating demo events...")

# Create events for the next few weeks
base_time = timezone.now()
events_data = [
    (societies[0], 'Python Workshop', 'Learn Python basics with hands-on exercises', base_time + timezone.timedelta(days=3), 15),
    (societies[0], 'AI & Machine Learning Seminar', 'Introduction to ML concepts', base_time + timezone.timedelta(days=10), 25),
    (societies[1], 'Football Training Session', 'Weekly training for all skill levels', base_time + timezone.timedelta(days=2), 30),
    (societies[1], 'Inter-University Match', 'Friendly match vs neighboring university', base_time + timezone.timedelta(days=14), 50),
    (societies[2], 'Drama Auditions', 'Join our upcoming production - no experience needed', base_time + timezone.timedelta(days=5), 20),
    (societies[3], 'Chess Tournament', 'Annual championship - all welcome', base_time + timezone.timedelta(days=21), 32),
    (societies[4], 'Photography Workshop', 'Learn composition and lighting techniques', base_time + timezone.timedelta(days=7), 12),
]

events = []
for society, title, desc, start_time, capacity in events_data:
    event = Event.objects.create(
        society=society,
        created_by=admin_profile,
        title=title,
        description=desc,
        location='Campus Venue Hall',
        start_time=start_time,
        end_time=start_time + timezone.timedelta(hours=2),
        capacity_limit=capacity,
        is_public=True
    )
    events.append(event)

print("Creating RSVPs...")

# Create RSVPs for events
for event in events:
    # Get society members
    society_members = [m.user for m in event.society.memberships.all()]
    if society_members:
        # 60-80% of members RSVP
        rsvp_count = int(len(society_members) * random.uniform(0.6, 0.8))
        rsvp_members = random.sample(society_members, rsvp_count)

        for member in rsvp_members:
            RSVP.objects.create(
                event=event,
                user=member,
                is_attending=True
            )

print("Demo data setup complete!")
print("")
print("Demo Accounts:")
print("Admin: demo_admin / admin123")
print("Students: alice_smith, bob_jones, carol_brown, david_wilson / student123")
print(f"Created {len(societies)} societies, {len(events)} events")
EOF

echo "Demo data created successfully!"
echo ""
echo "To start the demo:"
echo "1. Start backend: cd unisoc_backend && python manage.py runserver"
echo "2. Start frontend: cd unisoc_app && flutter run -d chrome"
echo ""
echo "Demo accounts:"
echo "- Admin: demo_admin / admin123"
echo "- Students: alice_smith, bob_jones, carol_brown, david_wilson / student123"