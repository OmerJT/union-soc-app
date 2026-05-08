from django.contrib.auth.models import User
from rest_framework import serializers
from .models import (
    UserProfile, Society, Membership, Event, RSVP,
    Notification, ChatMessage, AuditLog, PasswordResetRequest
)


class RegisterSerializer(serializers.ModelSerializer):
    """Handles new student/admin registration with secure Django password hashing."""
    password = serializers.CharField(write_only=True, min_length=8)
    up_number = serializers.CharField(required=False, allow_blank=True, allow_null=True)
    role = serializers.ChoiceField(choices=['user', 'admin'], default='user')

    class Meta:
        model = User
        fields = ['username', 'email', 'password', 'first_name', 'last_name', 'up_number', 'role']

    def validate(self, data):
        if data.get('role') == 'user' and not data.get('up_number'):
            raise serializers.ValidationError({'up_number': 'UP number is required for student accounts.'})
        if data.get('role') == 'admin':
            data['up_number'] = None
        return data

    def create(self, validated_data):
        up_number = validated_data.pop('up_number', None)
        role = validated_data.pop('role', 'user')
        password = validated_data.pop('password')
        user = User.objects.create_user(password=password, **validated_data)
        UserProfile.objects.create(user=user, up_number=up_number or None, role=role)
        AuditLog.objects.create(actor=user.profile, action='account_created', details='Account created through registration endpoint.')
        return user


class UserProfileSerializer(serializers.ModelSerializer):
    username = serializers.CharField(source='user.username', read_only=True)
    email = serializers.CharField(source='user.email')
    first_name = serializers.CharField(source='user.first_name', required=False, allow_blank=True)
    last_name = serializers.CharField(source='user.last_name', required=False, allow_blank=True)
    password = serializers.CharField(write_only=True, required=False, min_length=8)

    class Meta:
        model = UserProfile
        fields = [
            'id', 'username', 'email', 'first_name', 'last_name',
            'up_number', 'role', 'notifications_enabled', 'password'
        ]
        read_only_fields = ['id', 'username', 'role']

    def update(self, instance, validated_data):
        user_data = validated_data.pop('user', {})
        password = validated_data.pop('password', None)
        for attr, value in validated_data.items():
            setattr(instance, attr, value)
        instance.save()
        user = instance.user
        for attr, value in user_data.items():
            setattr(user, attr, value)
        if password:
            user.set_password(password)
        user.save()
        return instance


class SocietySerializer(serializers.ModelSerializer):
    is_member = serializers.SerializerMethodField()
    admin_username = serializers.CharField(source='admin.user.username', read_only=True)

    class Meta:
        model = Society
        fields = [
            'id', 'name', 'description', 'category', 'contact_email', 'meeting_location',
            'admin', 'admin_username', 'member_count', 'is_member', 'created_at', 'updated_at'
        ]
        read_only_fields = ['member_count', 'created_at', 'updated_at', 'admin_username']

    def get_is_member(self, obj):
        request = self.context.get('request')
        if request and request.user.is_authenticated and hasattr(request.user, 'profile'):
            return Membership.objects.filter(user=request.user.profile, society=obj).exists()
        return False


class MembershipSerializer(serializers.ModelSerializer):
    society = SocietySerializer(read_only=True)

    class Meta:
        model = Membership
        fields = ['id', 'society', 'joined_at', 'notifications_enabled']


class MembershipPreferenceSerializer(serializers.ModelSerializer):
    class Meta:
        model = Membership
        fields = ['notifications_enabled']


class EventSerializer(serializers.ModelSerializer):
    society_name = serializers.CharField(source='society.name', read_only=True)
    rsvp_count = serializers.ReadOnlyField()
    spaces_remaining = serializers.ReadOnlyField()
    is_full = serializers.ReadOnlyField()
    user_rsvp = serializers.SerializerMethodField()

    class Meta:
        model = Event
        fields = [
            'id', 'society', 'society_name', 'title', 'description',
            'location', 'start_time', 'end_time', 'capacity_limit',
            'is_public', 'rsvp_count', 'spaces_remaining', 'is_full',
            'user_rsvp', 'created_at', 'updated_at'
        ]
        read_only_fields = ['created_at', 'updated_at']

    def get_user_rsvp(self, obj):
        request = self.context.get('request')
        if request and request.user.is_authenticated and hasattr(request.user, 'profile'):
            try:
                return RSVP.objects.get(event=obj, user=request.user.profile).is_attending
            except RSVP.DoesNotExist:
                return None
        return None


class EventCreateSerializer(serializers.ModelSerializer):
    """Used by admins to create/edit events, including capacity limits."""
    class Meta:
        model = Event
        fields = [
            'society', 'title', 'description', 'location',
            'start_time', 'end_time', 'capacity_limit', 'is_public'
        ]

    def validate(self, data):
        start = data.get('start_time', getattr(self.instance, 'start_time', None))
        end = data.get('end_time', getattr(self.instance, 'end_time', None))
        if start and end and start >= end:
            raise serializers.ValidationError('End time must be after start time.')
        return data


class RSVPSerializer(serializers.ModelSerializer):
    class Meta:
        model = RSVP
        fields = ['id', 'event', 'is_attending', 'timestamp']
        read_only_fields = ['timestamp']


class NotificationSerializer(serializers.ModelSerializer):
    society_name = serializers.CharField(source='society.name', read_only=True)
    event_title = serializers.CharField(source='event.title', read_only=True)

    class Meta:
        model = Notification
        fields = ['id', 'society', 'society_name', 'event', 'event_title', 'title', 'message', 'read', 'created_at']
        read_only_fields = ['created_at']


class ChatMessageSerializer(serializers.ModelSerializer):
    sender_username = serializers.CharField(source='sender.user.username', read_only=True)
    sender_role = serializers.CharField(source='sender.role', read_only=True)

    class Meta:
        model = ChatMessage
        fields = ['id', 'society', 'sender_username', 'sender_role', 'message', 'created_at']
        read_only_fields = ['id', 'society', 'sender_username', 'sender_role', 'created_at']


class AuditLogSerializer(serializers.ModelSerializer):
    actor_username = serializers.CharField(source='actor.user.username', read_only=True)

    class Meta:
        model = AuditLog
        fields = ['id', 'actor_username', 'action', 'success', 'details', 'created_at']


class PasswordResetRequestSerializer(serializers.ModelSerializer):
    class Meta:
        model = PasswordResetRequest
        fields = ['id', 'token', 'used', 'created_at']
