from django.contrib.auth.models import User
from django.urls import reverse
from django.utils import timezone
from rest_framework.test import APITestCase
from rest_framework import status
from rest_framework_simplejwt.tokens import RefreshToken
from .models import UserProfile, Society, Membership, Event, RSVP, Notification, AuditLog, ChatMessage


class UniSocAPITestCase(APITestCase):
    """Automated tests covering the main units required for Coursework 2."""

    def setUp(self):
        self.user = User.objects.create_user(username='student1', email='student1@example.com', password='Password123')
        self.profile = UserProfile.objects.create(user=self.user, up_number='UP123456', role='user')
        self.admin_user = User.objects.create_user(username='admin1', email='admin1@example.com', password='Password123')
        self.admin_profile = UserProfile.objects.create(user=self.admin_user, role='admin')
        self.society = Society.objects.create(name='Computing Society', category='academic', description='Tech events', admin=self.admin_profile)
        self.event = Event.objects.create(
            society=self.society,
            created_by=self.admin_profile,
            title='Python Workshop',
            description='Introductory workshop',
            location='Room 1',
            start_time=timezone.now() + timezone.timedelta(days=1),
            end_time=timezone.now() + timezone.timedelta(days=1, hours=2),
            capacity_limit=2,
        )
        self.client.credentials(HTTP_AUTHORIZATION=f'Bearer {RefreshToken.for_user(self.user).access_token}')

    def test_register_hashes_password_and_creates_profile(self):
        """Test user registration with password hashing and profile creation."""
        response = self.client.post(reverse('register'), {
            'username': 'student2',
            'email': 'student2@example.com',
            'password': 'Password123',
            'first_name': 'Student',
            'last_name': 'Two',
            'up_number': 'UP999999',
            'role': 'user',
        }, format='json')
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        user = User.objects.get(username='student2')
        self.assertTrue(user.check_password('Password123'))
        self.assertNotEqual(user.password, 'Password123')
        self.assertEqual(user.profile.up_number, 'UP999999')

    def test_register_admin_without_up_number(self):
        """Test admin registration doesn't require UP number."""
        response = self.client.post(reverse('register'), {
            'username': 'admin2',
            'email': 'admin2@example.com',
            'password': 'Password123',
            'first_name': 'Admin',
            'last_name': 'Two',
            'up_number': '',
            'role': 'admin',
        }, format='json')
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        user = User.objects.get(username='admin2')
        self.assertEqual(user.profile.role, 'admin')
        self.assertEqual(user.profile.up_number, None)  # Admins don't need UP numbers

    def test_login_success_and_token_return(self):
        """Test successful login returns JWT token."""
        response = self.client.post(reverse('login'), {
            'username': 'student1',
            'password': 'Password123'
        }, format='json')
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertIn('access', response.data)
        self.assertIn('role', response.data)
        self.assertEqual(response.data['role'], 'user')

    def test_login_failure_invalid_credentials(self):
        """Test login fails with invalid credentials."""
        response = self.client.post(reverse('login'), {
            'username': 'student1',
            'password': 'WrongPassword'
        }, format='json')
        self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED)
