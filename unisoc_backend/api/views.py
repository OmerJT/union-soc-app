from django.contrib.auth.models import User
from django.db.models import Q
from django.http import HttpResponse
from django.utils import timezone
from rest_framework import generics, status, permissions
from rest_framework.response import Response
from rest_framework.views import APIView
from rest_framework_simplejwt.tokens import RefreshToken
import csv

from .models import (
    UserProfile, Society, Membership, Event, RSVP,
    Notification, ChatMessage, AuditLog, PasswordResetRequest
)
from .serializers import (
    RegisterSerializer, UserProfileSerializer, SocietySerializer,
    MembershipSerializer, MembershipPreferenceSerializer,
    EventSerializer, EventCreateSerializer, NotificationSerializer,
    ChatMessageSerializer, AuditLogSerializer
)


def get_profile(user):
    """Safely get the UserProfile for an authenticated user."""
    try:
        return user.profile
    except UserProfile.DoesNotExist:
        return None


class IsAdmin(permissions.BasePermission):
    """Only allows users with role='admin'."""
    def has_permission(self, request, view):
        profile = get_profile(request.user)
        return profile is not None and profile.role == 'admin'


def create_audit(actor, action, success=True, details=''):
    """Centralised audit helper used by membership, event and profile actions."""
    AuditLog.objects.create(actor=actor, action=action, success=success, details=details)


def create_event_notifications(event, title, message):
    """
    Creates in-app notifications for members who have opted in globally and for
    this specific society membership. This demonstrates the notification logic
    without requiring a third-party email provider in the coursework prototype.
    """
    memberships = Membership.objects.filter(
        society=event.society,
        notifications_enabled=True,
        user__notifications_enabled=True,
    ).select_related('user')
    for membership in memberships:
        Notification.objects.create(
            recipient=membership.user,
            society=event.society,
            event=event,
            title=title,
            message=message,
        )


class RegisterView(APIView):
    permission_classes = [permissions.AllowAny]

    def post(self, request):
        serializer = RegisterSerializer(data=request.data)
        if serializer.is_valid():
            user = serializer.save()
            refresh = RefreshToken.for_user(user)
            return Response({
                'message': 'Account created successfully.',
                'access': str(refresh.access_token),
                'refresh': str(refresh),
                'role': user.profile.role,
                'username': user.username,
            }, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


class LoginView(APIView):
    permission_classes = [permissions.AllowAny]

    def post(self, request):
        from django.contrib.auth import authenticate
        username = request.data.get('username')
        password = request.data.get('password')
        user = authenticate(username=username, password=password)
        if user:
            refresh = RefreshToken.for_user(user)
            profile = get_profile(user)
            return Response({
                'access': str(refresh.access_token),
                'refresh': str(refresh),
                'role': profile.role if profile else 'user',
                'username': user.username,
            })
        return Response({'error': 'Invalid credentials.'}, status=status.HTTP_401_UNAUTHORIZED)


class ForgotPasswordView(APIView):
    """
    Prototype forgotten-password request. A production version would email the
    token. The coursework prototype returns it so it can be demonstrated/tested.
    """
    permission_classes = [permissions.AllowAny]

    def post(self, request):
        username_or_email = request.data.get('username_or_email', '')
        user = User.objects.filter(Q(username=username_or_email) | Q(email=username_or_email)).first()
        if not user:
            return Response({'message': 'If the account exists, a reset token has been created.'})
        reset = PasswordResetRequest.objects.create(user=user)
        profile = get_profile(user)
        create_audit(profile, 'password_reset', True, 'Password reset token requested.')
        return Response({
            'message': 'Password reset token created for prototype demonstration.',
            'reset_token': reset.token,
        })


class ResetPasswordView(APIView):
    permission_classes = [permissions.AllowAny]

    def post(self, request):
        token = request.data.get('token')
        new_password = request.data.get('new_password')
        if not token or not new_password or len(new_password) < 8:
            return Response({'error': 'Token and a password of at least 8 characters are required.'}, status=400)
        reset = PasswordResetRequest.objects.filter(token=token, used=False).first()
        if not reset or reset.is_expired:
            return Response({'error': 'Invalid or expired reset token.'}, status=400)
        reset.user.set_password(new_password)
        reset.user.save()
        reset.used = True
        reset.save()
        create_audit(get_profile(reset.user), 'password_reset', True, 'Password reset completed.')
        return Response({'message': 'Password updated successfully.'})


class MeView(APIView):
    """Returns and updates the current authenticated user's profile."""
    def get(self, request):
        profile = get_profile(request.user)
        if not profile:
            return Response({'error': 'Profile not found.'}, status=404)
        return Response(UserProfileSerializer(profile).data)

    def patch(self, request):
        profile = get_profile(request.user)
        if not profile:
            return Response({'error': 'Profile not found.'}, status=404)
        serializer = UserProfileSerializer(profile, data=request.data, partial=True)
        if serializer.is_valid():
            serializer.save()
            create_audit(profile, 'notification_pref', True, 'Profile/account settings updated.')
            return Response({'message': 'Profile updated.', 'profile': serializer.data})
        return Response(serializer.errors, status=400)


class SocietyListCreateView(generics.ListCreateAPIView):
    """Lists societies for all users and allows admins to create societies."""
    serializer_class = SocietySerializer

    def get_queryset(self):
        queryset = Society.objects.all()
        search = self.request.query_params.get('search')
        category = self.request.query_params.get('category')
        if search:
            queryset = queryset.filter(Q(name__icontains=search) | Q(description__icontains=search))
        if category:
            queryset = queryset.filter(category=category)
        return queryset

    def get_permissions(self):
        if self.request.method == 'POST':
            return [permissions.IsAuthenticated(), IsAdmin()]
        return [permissions.IsAuthenticated()]

    def get_serializer_context(self):
        return {'request': self.request}

    def perform_create(self, serializer):
        profile = get_profile(self.request.user)
        society = serializer.save(admin=profile)
        create_audit(profile, 'society_updated', True, f'Created society {society.name}.')


class SocietyDetailView(generics.RetrieveUpdateDestroyAPIView):
    """Allows users to view a society and admins to update/manage it."""
    queryset = Society.objects.all()
    serializer_class = SocietySerializer

    def get_permissions(self):
        if self.request.method in ['PUT', 'PATCH', 'DELETE']:
            return [permissions.IsAuthenticated(), IsAdmin()]
        return [permissions.IsAuthenticated()]

    def get_serializer_context(self):
        return {'request': self.request}

    def perform_update(self, serializer):
        society = serializer.save()
        create_audit(get_profile(self.request.user), 'society_updated', True, f'Updated society {society.name}.')


class JoinSocietyView(APIView):
    """POST /api/societies/<id>/join/"""
    def post(self, request, pk):
        profile = get_profile(request.user)
        try:
            society = Society.objects.get(pk=pk)
        except Society.DoesNotExist:
            create_audit(profile, 'join_society', False, f'Society {pk} not found.')
            return Response({'error': 'Society not found.'}, status=404)
        if Membership.objects.filter(user=profile, society=society).exists():
            create_audit(profile, 'join_society', False, f'Duplicate join attempted for {society.name}.')
            return Response({'error': 'You are already a member of this society.'}, status=400)
        Membership.objects.create(user=profile, society=society)
        society.member_count = society.memberships.count()
        society.save()
        create_audit(profile, 'join_society', True, f'Joined {society.name}.')
        return Response({'message': f'Successfully joined {society.name}.'}, status=201)


class LeaveSocietyView(APIView):
    """POST /api/societies/<id>/leave/"""
    def post(self, request, pk):
        profile = get_profile(request.user)
        try:
            society = Society.objects.get(pk=pk)
            membership = Membership.objects.get(user=profile, society=society)
        except Society.DoesNotExist:
            create_audit(profile, 'leave_society', False, f'Society {pk} not found.')
            return Response({'error': 'Society not found.'}, status=404)
        except Membership.DoesNotExist:
            create_audit(profile, 'leave_society', False, f'User was not a member of society {pk}.')
            return Response({'error': 'You are not a member of this society.'}, status=400)
        membership.delete()
        society.member_count = society.memberships.count()
        society.save()
        create_audit(profile, 'leave_society', True, f'Left {society.name}; notifications stopped by removing membership.')
        return Response({'message': f'Successfully left {society.name}.'})


class MyMembershipsView(generics.ListAPIView):
    serializer_class = MembershipSerializer

    def get_queryset(self):
        profile = get_profile(self.request.user)
        return Membership.objects.filter(user=profile).select_related('society')


class MembershipPreferenceView(APIView):
    """Allows users to opt in/out of notifications for a specific joined society."""
    def patch(self, request, pk):
        profile = get_profile(request.user)
        try:
            membership = Membership.objects.get(user=profile, society_id=pk)
        except Membership.DoesNotExist:
            return Response({'error': 'Membership not found.'}, status=404)
        serializer = MembershipPreferenceSerializer(membership, data=request.data, partial=True)
        if serializer.is_valid():
            serializer.save()
            create_audit(profile, 'notification_pref', True, f'Updated notification preference for society {pk}.')
            return Response(MembershipSerializer(membership).data)
        return Response(serializer.errors, status=400)


class EventListView(generics.ListAPIView):
    serializer_class = EventSerializer

    def get_queryset(self):
        profile = get_profile(self.request.user)
        society_id = self.request.query_params.get('society')
        all_events = self.request.query_params.get('all') == 'true'
        if profile and profile.role == 'admin' and all_events:
            return Event.objects.all()
        if society_id:
            return Event.objects.filter(society_id=society_id)
        joined = Membership.objects.filter(user=profile).values_list('society_id', flat=True)
        return Event.objects.filter(society_id__in=joined)

    def get_serializer_context(self):
        return {'request': self.request}


class EventDetailView(generics.RetrieveAPIView):
    queryset = Event.objects.all()
    serializer_class = EventSerializer

    def get_serializer_context(self):
        return {'request': self.request}


class EventCreateView(generics.CreateAPIView):
    serializer_class = EventCreateSerializer
    permission_classes = [permissions.IsAuthenticated, IsAdmin]

    def perform_create(self, serializer):
        profile = get_profile(self.request.user)
        event = serializer.save(created_by=profile)
        create_audit(profile, 'event_created', True, f'Created event {event.title}.')
        create_event_notifications(event, f'New event: {event.title}', f'{event.society.name} created a new event at {event.location}.')


class EventUpdateView(generics.UpdateAPIView):
    queryset = Event.objects.all()
    serializer_class = EventCreateSerializer
    permission_classes = [permissions.IsAuthenticated, IsAdmin]

    def perform_update(self, serializer):
        event = serializer.save()
        create_audit(get_profile(self.request.user), 'event_updated', True, f'Updated event {event.title}.')
        create_event_notifications(event, f'Event updated: {event.title}', f'{event.society.name} updated event details.')


class EventDeleteView(generics.DestroyAPIView):
    queryset = Event.objects.all()
    permission_classes = [permissions.IsAuthenticated, IsAdmin]

    def perform_destroy(self, instance):
        profile = get_profile(self.request.user)
        create_event_notifications(instance, f'Event removed: {instance.title}', f'{instance.society.name} removed this event.')
        create_audit(profile, 'event_deleted', True, f'Deleted event {instance.title}.')
        instance.delete()


class RSVPView(APIView):
    def post(self, request, pk):
        profile = get_profile(request.user)
        try:
            event = Event.objects.get(pk=pk)
        except Event.DoesNotExist:
            create_audit(profile, 'rsvp', False, f'Event {pk} not found.')
            return Response({'error': 'Event not found.'}, status=404)
        is_attending = request.data.get('is_attending', True)
        if not Membership.objects.filter(user=profile, society=event.society).exists():
            create_audit(profile, 'rsvp', False, f'RSVP denied for non-member on event {event.title}.')
            return Response({'error': 'You must join this society to RSVP.'}, status=403)
        if is_attending and event.is_full:
            existing = RSVP.objects.filter(event=event, user=profile, is_attending=True).exists()
            if not existing:
                create_audit(profile, 'rsvp', False, f'RSVP denied because event {event.title} is full.')
                return Response({'error': 'This event is full.'}, status=400)
        rsvp, created = RSVP.objects.update_or_create(event=event, user=profile, defaults={'is_attending': is_attending})
        create_audit(profile, 'rsvp', True, f'RSVP for {event.title}: {is_attending}.')
        return Response({'message': 'RSVP created' if created else 'RSVP updated', 'is_attending': rsvp.is_attending, 'rsvp_count': event.rsvp_count, 'spaces_remaining': event.spaces_remaining})


class NotificationListView(generics.ListAPIView):
    serializer_class = NotificationSerializer

    def get_queryset(self):
        return Notification.objects.filter(recipient=get_profile(self.request.user))


class NotificationMarkReadView(APIView):
    def post(self, request, pk):
        try:
            notification = Notification.objects.get(pk=pk, recipient=get_profile(request.user))
        except Notification.DoesNotExist:
            return Response({'error': 'Notification not found.'}, status=404)
        notification.read = True
        notification.save()
        return Response({'message': 'Notification marked as read.'})


class ChatMessageListCreateView(APIView):
    """Society chat box for users and admins."""
    def get(self, request, pk):
        profile = get_profile(request.user)
        if profile.role != 'admin' and not Membership.objects.filter(user=profile, society_id=pk).exists():
            return Response({'error': 'Join this society to view its chat.'}, status=403)
        messages = ChatMessage.objects.filter(society_id=pk).select_related('sender__user')
        return Response(ChatMessageSerializer(messages, many=True).data)

    def post(self, request, pk):
        profile = get_profile(request.user)
        try:
            society = Society.objects.get(pk=pk)
        except Society.DoesNotExist:
            return Response({'error': 'Society not found.'}, status=404)
        if profile.role != 'admin' and not Membership.objects.filter(user=profile, society=society).exists():
            return Response({'error': 'Join this society before sending messages.'}, status=403)
        message = ChatMessage.objects.create(society=society, sender=profile, message=request.data.get('message', ''))
        return Response(ChatMessageSerializer(message).data, status=201)


class AttendanceReportView(APIView):
    """Admin endpoint that exports attendance data as CSV."""
    permission_classes = [permissions.IsAuthenticated, IsAdmin]

    def get(self, request):
        response = HttpResponse(content_type='text/csv')
        response['Content-Disposition'] = 'attachment; filename="attendance_report.csv"'
        writer = csv.writer(response)
        writer.writerow(['Event', 'Society', 'Username', 'UP Number', 'Email', 'Attending', 'Timestamp'])
        rsvps = RSVP.objects.select_related('event__society', 'user__user').all()
        for rsvp in rsvps:
            writer.writerow([
                rsvp.event.title, rsvp.event.society.name, rsvp.user.user.username,
                rsvp.user.up_number or '', rsvp.user.user.email, rsvp.is_attending, rsvp.timestamp
            ])
        return response


class AuditLogListView(generics.ListAPIView):
    """Admin-only list of successful/failed membership, RSVP and event actions."""
    serializer_class = AuditLogSerializer
    permission_classes = [permissions.IsAuthenticated, IsAdmin]
    queryset = AuditLog.objects.all()
