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

    def test_forgot_password_request(self):
        """Test password reset request generates token."""
        response = self.client.post(reverse('forgot-password'), {
            'username_or_email': 'student1'
        }, format='json')
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        # In production, this would send email, but for testing we return the token
        self.assertIn('reset_token', response.data)

    def test_password_reset_with_valid_token(self):
        """Test password reset with valid token."""
        # First request reset
        reset_response = self.client.post(reverse('forgot-password'), {
            'username_or_email': 'student1'
        }, format='json')
        token = reset_response.data['reset_token']

        # Then reset password
        response = self.client.post(reverse('reset-password'), {
            'token': token,
            'new_password': 'NewPassword123'
        }, format='json')
        self.assertEqual(response.status_code, status.HTTP_200_OK)

        # Verify password changed
        self.user.refresh_from_db()
        self.assertTrue(self.user.check_password('NewPassword123'))

    def test_user_can_join_leave_and_duplicate_join_is_blocked(self):
        """Test society membership operations."""
        join_url = reverse('society-join', args=[self.society.id])
        response = self.client.post(join_url)
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertTrue(Membership.objects.filter(user=self.profile, society=self.society).exists())
        self.assertTrue(AuditLog.objects.filter(action='join_society', success=True).exists())

        # Duplicate join should fail
        duplicate = self.client.post(join_url)
        self.assertEqual(duplicate.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertTrue(AuditLog.objects.filter(action='join_society', success=False).exists())

        # Leave society
        leave = self.client.post(reverse('society-leave', args=[self.society.id]))
        self.assertEqual(leave.status_code, status.HTTP_200_OK)
        self.assertFalse(Membership.objects.filter(user=self.profile, society=self.society).exists())

    def test_search_and_category_filter_societies(self):
        """Test society search and filtering functionality."""
        Society.objects.create(name='Football Society', category='sports')
        Society.objects.create(name='Computer Science Society', category='academic')

        # Test search
        response = self.client.get(reverse('society-list-create'), {'search': 'Computing'})
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.data), 1)
        self.assertEqual(response.data[0]['name'], 'Computing Society')

        # Test category filter
        response = self.client.get(reverse('society-list-create'), {'category': 'academic'})
        self.assertEqual(len(response.data), 2)  # Computing and Computer Science

        # Test combined search and filter
        response = self.client.get(reverse('society-list-create'), {'search': 'Soc', 'category': 'academic'})
        self.assertEqual(len(response.data), 2)

    def test_rsvp_requires_membership_and_tracks_capacity(self):
        """Test RSVP functionality with membership and capacity constraints."""
        # Try RSVP without membership
        response = self.client.post(reverse('event-rsvp', args=[self.event.id]), {'is_attending': True}, format='json')
        self.assertEqual(response.status_code, status.HTTP_403_FORBIDDEN)

        # Join society first
        Membership.objects.create(user=self.profile, society=self.society)

        # Now RSVP should work
        response = self.client.post(reverse('event-rsvp', args=[self.event.id]), {'is_attending': True}, format='json')
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(RSVP.objects.get(user=self.profile, event=self.event).is_attending, True)
        self.assertEqual(response.data['rsvp_count'], 1)
        self.assertEqual(response.data['spaces_remaining'], 1)

    def test_event_capacity_limits(self):
        """Test event capacity limits and full event handling."""
        Membership.objects.create(user=self.profile, society=self.society)
        user2 = User.objects.create_user(username='student2', email='student2@example.com', password='Password123')
        profile2 = UserProfile.objects.create(user=user2, up_number='UP654321', role='user')
        Membership.objects.create(user=profile2, society=self.society)

        # Fill the event
        self.client.post(reverse('event-rsvp', args=[self.event.id]), {'is_attending': True}, format='json')
        self.client.credentials(HTTP_AUTHORIZATION=f'Bearer {RefreshToken.for_user(user2).access_token}')
        self.client.post(reverse('event-rsvp', args=[self.event.id]), {'is_attending': True}, format='json')

        # Event should now be full
        self.event.refresh_from_db()
        self.assertTrue(self.event.is_full)
        self.assertEqual(self.event.spaces_remaining, 0)
