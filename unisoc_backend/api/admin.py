from django.contrib import admin
from .models import UserProfile, Society, Membership, Event, RSVP, Notification, ChatMessage, AuditLog, PasswordResetRequest

admin.site.register(UserProfile)
admin.site.register(Society)
admin.site.register(Membership)
admin.site.register(Event)
admin.site.register(RSVP)
admin.site.register(Notification)
admin.site.register(ChatMessage)
admin.site.register(AuditLog)
admin.site.register(PasswordResetRequest)
