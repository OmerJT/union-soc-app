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

    def test_user_can_join_leave_and_duplicate_join_is_blocked(self):
        join_url = reverse('society-join', args=[self.society.id])
        response = self.client.post(join_url)
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        duplicate = self.client.post(join_url)
        self.assertEqual(duplicate.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertTrue(AuditLog.objects.filter(action='join_society', success=False).exists())
        leave = self.client.post(reverse('society-leave', args=[self.society.id]))
        self.assertEqual(leave.status_code, status.HTTP_200_OK)
        self.assertFalse(Membership.objects.filter(user=self.profile, society=self.society).exists())

    def test_search_and_category_filter_societies(self):
        Society.objects.create(name='Football Society', category='sports')
        response = self.client.get(reverse('society-list-create'), {'search': 'Computing', 'category': 'academic'})
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.data), 1)
        self.assertEqual(response.data[0]['name'], 'Computing Society')

    def test_rsvp_requires_membership_and_tracks_capacity(self):
        response = self.client.post(reverse('event-rsvp', args=[self.event.id]), {'is_attending': True}, format='json')
        self.assertEqual(response.status_code, status.HTTP_403_FORBIDDEN)
        Membership.objects.create(user=self.profile, society=self.society)
        response = self.client.post(reverse('event-rsvp', args=[self.event.id]), {'is_attending': True}, format='json')
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(RSVP.objects.get(user=self.profile, event=self.event).is_attending, True)
        self.assertEqual(response.data['rsvp_count'], 1)

    def test_notification_preferences_and_event_notifications(self):
        Membership.objects.create(user=self.profile, society=self.society, notifications_enabled=True)
        self.client.credentials(HTTP_AUTHORIZATION=f'Bearer {RefreshToken.for_user(self.admin_user).access_token}')
        response = self.client.post(reverse('event-create'), {
            'society': self.society.id,
            'title': 'New Social',
            'description': 'Games night',
            'location': 'Union',
            'start_time': (timezone.now() + timezone.timedelta(days=3)).isoformat(),
            'end_time': (timezone.now() + timezone.timedelta(days=3, hours=2)).isoformat(),
            'capacity_limit': 30,
            'is_public': True,
        }, format='json')
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertTrue(Notification.objects.filter(recipient=self.profile, title__icontains='New event').exists())

    def test_chat_message_can_be_sent_by_member(self):
        Membership.objects.create(user=self.profile, society=self.society)
        response = self.client.post(reverse('society-chat', args=[self.society.id]), {'message': 'Hi admin'}, format='json')
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertEqual(ChatMessage.objects.filter(society=self.society).count(), 1)

    def test_admin_can_export_attendance_report(self):
        Membership.objects.create(user=self.profile, society=self.society)
        RSVP.objects.create(user=self.profile, event=self.event, is_attending=True)
        self.client.credentials(HTTP_AUTHORIZATION=f'Bearer {RefreshToken.for_user(self.admin_user).access_token}')
        response = self.client.get(reverse('attendance-report'))
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertIn('text/csv', response['Content-Type'])
        self.assertIn(b'Python Workshop', response.content)
