from django.db import models
from django.contrib.auth.models import User
from django.utils import timezone
import secrets


class UserProfile(models.Model):
    """
    Extends Django's built-in User model.
    Stores extra fields specific to UniSoc, including the UP number, role and
    the global notification preference used by the notification system.
    """
    ROLE_CHOICES = [
        ('user', 'User'),
        ('admin', 'Admin'),
    ]

    user = models.OneToOneField(User, on_delete=models.CASCADE, related_name='profile')
    up_number = models.CharField(max_length=20, unique=True, blank=True, null=True)
    role = models.CharField(max_length=10, choices=ROLE_CHOICES, default='user')
    notifications_enabled = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"{self.user.username} ({self.role})"


class Society(models.Model):
    """
    Represents a university society.
    A society can be managed by an admin profile and edited through protected
    admin-only API endpoints.
    """
    CATEGORY_CHOICES = [
        ('cultural', 'Cultural'),
        ('academic', 'Academic'),
        ('religious', 'Religious'),
        ('sports', 'Sports'),
        ('extracurricular', 'Extracurricular'),
    ]

    name = models.CharField(max_length=200, unique=True)
    description = models.TextField(blank=True)
    category = models.CharField(max_length=50, choices=CATEGORY_CHOICES, default='extracurricular')
    contact_email = models.EmailField(blank=True)
    meeting_location = models.CharField(max_length=250, blank=True)
    admin = models.ForeignKey(
        UserProfile,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='managed_societies'
    )
    member_count = models.PositiveIntegerField(default=0)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['name']
        verbose_name_plural = 'Societies'

    def __str__(self):
        return self.name


class Membership(models.Model):
    """
    Junction table that tracks which users have joined which societies.
    unique_together prevents a user from joining the same society twice.
    """
    user = models.ForeignKey(UserProfile, on_delete=models.CASCADE, related_name='memberships')
    society = models.ForeignKey(Society, on_delete=models.CASCADE, related_name='memberships')
    joined_at = models.DateTimeField(auto_now_add=True)
    notifications_enabled = models.BooleanField(default=True)

    class Meta:
        unique_together = ('user', 'society')
        ordering = ['-joined_at']

    def __str__(self):
        return f"{self.user.user.username} → {self.society.name}"


class Event(models.Model):
    """
    An event created by a society admin.
    Tracks description, location, start/end time, capacity and attendance.
    """
    society = models.ForeignKey(Society, on_delete=models.CASCADE, related_name='events')
    created_by = models.ForeignKey(
        UserProfile,
        on_delete=models.SET_NULL,
        null=True,
        related_name='created_events'
    )
    title = models.CharField(max_length=200)
    description = models.TextField(blank=True)
    location = models.CharField(max_length=300, blank=True)
    start_time = models.DateTimeField()
    end_time = models.DateTimeField()
    capacity_limit = models.PositiveIntegerField(null=True, blank=True)
    is_public = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['start_time']

    def __str__(self):
        return f"{self.title} ({self.society.name})"

    @property
    def rsvp_count(self):
        return self.rsvps.filter(is_attending=True).count()

    @property
    def spaces_remaining(self):
        if self.capacity_limit is None:
            return None
        return max(0, self.capacity_limit - self.rsvp_count)

    @property
    def is_full(self):
        if self.capacity_limit is None:
            return False
        return self.rsvp_count >= self.capacity_limit


class RSVP(models.Model):
    """Tracks a user's attendance intent for an event."""
    event = models.ForeignKey(Event, on_delete=models.CASCADE, related_name='rsvps')
    user = models.ForeignKey(UserProfile, on_delete=models.CASCADE, related_name='rsvps')
    is_attending = models.BooleanField(default=True)
    timestamp = models.DateTimeField(auto_now=True)

    class Meta:
        unique_together = ('event', 'user')

    def __str__(self):
        status = "attending" if self.is_attending else "not attending"
        return f"{self.user.user.username} is {status} → {self.event.title}"


class Notification(models.Model):
    """
    Stores in-app notifications created when society events are created,
    updated or removed. This provides demonstrable notification functionality
    without depending on a live email/push provider in the prototype.
    """
    recipient = models.ForeignKey(UserProfile, on_delete=models.CASCADE, related_name='notifications')
    society = models.ForeignKey(Society, on_delete=models.CASCADE, related_name='notifications')
    event = models.ForeignKey(Event, on_delete=models.SET_NULL, null=True, blank=True, related_name='notifications')
    title = models.CharField(max_length=200)
    message = models.TextField()
    read = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-created_at']

    def __str__(self):
        return f"Notification for {self.recipient.user.username}: {self.title}"


class ChatMessage(models.Model):
    """
    Simple society chat box between members and society administrators.
    Messages are stored per society and can be viewed by members and admins.
    """
    society = models.ForeignKey(Society, on_delete=models.CASCADE, related_name='chat_messages')
    sender = models.ForeignKey(UserProfile, on_delete=models.CASCADE, related_name='sent_chat_messages')
    message = models.TextField()
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['created_at']

    def __str__(self):
        return f"{self.sender.user.username}: {self.message[:30]}"


class AuditLog(models.Model):
    """Records key actions for troubleshooting and audit purposes."""
    ACTION_CHOICES = [
        ('account_created', 'Account created'),
        ('join_society', 'Join society'),
        ('leave_society', 'Leave society'),
        ('notification_pref', 'Notification preference changed'),
        ('rsvp', 'RSVP changed'),
        ('event_created', 'Event created'),
        ('event_updated', 'Event updated'),
        ('event_deleted', 'Event deleted'),
        ('society_updated', 'Society updated'),
        ('password_reset', 'Password reset requested'),
    ]
    actor = models.ForeignKey(UserProfile, on_delete=models.SET_NULL, null=True, blank=True, related_name='audit_logs')
    action = models.CharField(max_length=40, choices=ACTION_CHOICES)
    success = models.BooleanField(default=True)
    details = models.TextField(blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-created_at']

    def __str__(self):
        username = self.actor.user.username if self.actor else 'system'
        return f"{self.action} by {username}"


class PasswordResetRequest(models.Model):
    """
    Prototype password reset request. In production, this token would be sent
    by email. For coursework demonstration, the token is returned by the API.
    """
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='password_reset_requests')
    token = models.CharField(max_length=64, unique=True, default=secrets.token_urlsafe)
    used = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)

    @property
    def is_expired(self):
        return timezone.now() > self.created_at + timezone.timedelta(hours=2)

    def __str__(self):
        return f"Password reset for {self.user.username}"
