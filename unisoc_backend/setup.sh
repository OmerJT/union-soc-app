#!/bin/bash
# UniSoc Day 1 Setup Script
# Run this once after downloading the project: bash setup.sh

set -e  # exit on any error

echo "========================================"
echo " UniSoc Backend — Day 1 Setup"
echo "========================================"

# 1. Create and activate virtual environment
echo ""
echo "[1/5] Creating virtual environment..."
python3 -m venv venv
source venv/bin/activate

# 2. Install dependencies
echo ""
echo "[2/5] Installing dependencies..."
pip install -r requirements.txt

# 3. Run migrations
echo ""
echo "[3/5] Running database migrations..."
python manage.py makemigrations
python manage.py migrate

# 4. Create a superuser for the Django admin panel
echo ""
echo "[4/5] Creating superuser..."
echo "You'll use this to log into /admin and add test data."
python manage.py createsuperuser

# 5. Seed some sample societies
echo ""
echo "[5/5] Adding sample societies..."
python manage.py shell << 'EOF'
from api.models import Society

societies = [
    ("Greek Society", "cultural", "Connect with Greek culture, language and traditions."),
    ("American Football Club", "sports", "University American Football team open to all."),
    ("Climbing Society", "sports", "Bouldering and rope climbing for all abilities."),
    ("Asian Cultural Society", "cultural", "Celebrating Asian culture through events and food."),
    ("DJ Society", "extracurricular", "Learn to DJ and perform at university events."),
    ("Swimming Club", "sports", "Competitive and casual swimming for UoP students."),
    ("Computer Science Society", "academic", "Tech talks, hackathons and industry networking."),
    ("Islamic Society", "religious", "Faith, community and social events."),
]

for name, category, desc in societies:
    Society.objects.get_or_create(name=name, defaults={'category': category, 'description': desc})
    print(f"  ✓ {name}")

print(f"\nTotal societies: {Society.objects.count()}")
EOF

echo ""
echo "========================================"
echo " Setup complete!"
echo " Start the server with:"
echo "   source venv/bin/activate"
echo "   python manage.py runserver"
echo ""
echo " Admin panel: http://127.0.0.1:8000/admin"
echo " API base:    http://127.0.0.1:8000/api/"
echo "========================================"
