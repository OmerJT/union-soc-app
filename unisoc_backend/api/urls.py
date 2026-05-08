from django.urls import path
from rest_framework_simplejwt.views import TokenRefreshView
from . import views

urlpatterns = [
    path('auth/register/', views.RegisterView.as_view(), name='register'),
    path('auth/login/', views.LoginView.as_view(), name='login'),
    path('auth/refresh/', TokenRefreshView.as_view(), name='token_refresh'),
    path('auth/me/', views.MeView.as_view(), name='me'),
    path('auth/forgot-password/', views.ForgotPasswordView.as_view(), name='forgot-password'),
    path('auth/reset-password/', views.ResetPasswordView.as_view(), name='reset-password'),

    path('societies/', views.SocietyListCreateView.as_view(), name='society-list-create'),
    path('societies/<int:pk>/', views.SocietyDetailView.as_view(), name='society-detail'),
    path('societies/<int:pk>/join/', views.JoinSocietyView.as_view(), name='society-join'),
    path('societies/<int:pk>/leave/', views.LeaveSocietyView.as_view(), name='society-leave'),
    path('societies/<int:pk>/notification-preference/', views.MembershipPreferenceView.as_view(), name='society-notification-preference'),
    path('societies/<int:pk>/chat/', views.ChatMessageListCreateView.as_view(), name='society-chat'),
    path('my-societies/', views.MyMembershipsView.as_view(), name='my-societies'),

    path('events/', views.EventListView.as_view(), name='event-list'),
    path('events/<int:pk>/', views.EventDetailView.as_view(), name='event-detail'),
    path('events/create/', views.EventCreateView.as_view(), name='event-create'),
    path('events/<int:pk>/edit/', views.EventUpdateView.as_view(), name='event-edit'),
    path('events/<int:pk>/delete/', views.EventDeleteView.as_view(), name='event-delete'),
    path('events/<int:pk>/rsvp/', views.RSVPView.as_view(), name='event-rsvp'),

    path('notifications/', views.NotificationListView.as_view(), name='notifications'),
    path('notifications/<int:pk>/read/', views.NotificationMarkReadView.as_view(), name='notification-read'),
    path('admin/attendance-report/', views.AttendanceReportView.as_view(), name='attendance-report'),
    path('admin/audit-logs/', views.AuditLogListView.as_view(), name='audit-logs'),
]
