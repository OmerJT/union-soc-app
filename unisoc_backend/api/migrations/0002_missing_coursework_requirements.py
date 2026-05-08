# Generated manually for Coursework 2 feature completion.
from django.db import migrations, models
import django.db.models.deletion
import secrets
import django.utils.timezone


class Migration(migrations.Migration):

    dependencies = [
        ('auth', '0012_alter_user_first_name_max_length'),
        ('api', '0001_initial'),
    ]

    operations = [
        migrations.AddField(
            model_name='society',
            name='contact_email',
            field=models.EmailField(blank=True, max_length=254),
        ),
        migrations.AddField(
            model_name='society',
            name='meeting_location',
            field=models.CharField(blank=True, max_length=250),
        ),
        migrations.AddField(
            model_name='society',
            name='updated_at',
            field=models.DateTimeField(auto_now=True, default=django.utils.timezone.now),
            preserve_default=False,
        ),
        migrations.CreateModel(
            name='AuditLog',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('action', models.CharField(choices=[('account_created', 'Account created'), ('join_society', 'Join society'), ('leave_society', 'Leave society'), ('notification_pref', 'Notification preference changed'), ('rsvp', 'RSVP changed'), ('event_created', 'Event created'), ('event_updated', 'Event updated'), ('event_deleted', 'Event deleted'), ('society_updated', 'Society updated'), ('password_reset', 'Password reset requested')], max_length=40)),
                ('success', models.BooleanField(default=True)),
                ('details', models.TextField(blank=True)),
                ('created_at', models.DateTimeField(auto_now_add=True)),
                ('actor', models.ForeignKey(blank=True, null=True, on_delete=django.db.models.deletion.SET_NULL, related_name='audit_logs', to='api.userprofile')),
            ],
            options={'ordering': ['-created_at']},
        ),
        migrations.CreateModel(
            name='ChatMessage',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('message', models.TextField()),
                ('created_at', models.DateTimeField(auto_now_add=True)),
                ('sender', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='sent_chat_messages', to='api.userprofile')),
                ('society', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='chat_messages', to='api.society')),
            ],
            options={'ordering': ['created_at']},
        ),
        migrations.CreateModel(
            name='Notification',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('title', models.CharField(max_length=200)),
                ('message', models.TextField()),
                ('read', models.BooleanField(default=False)),
                ('created_at', models.DateTimeField(auto_now_add=True)),
                ('event', models.ForeignKey(blank=True, null=True, on_delete=django.db.models.deletion.SET_NULL, related_name='notifications', to='api.event')),
                ('recipient', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='notifications', to='api.userprofile')),
                ('society', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='notifications', to='api.society')),
            ],
            options={'ordering': ['-created_at']},
        ),
        migrations.CreateModel(
            name='PasswordResetRequest',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('token', models.CharField(default=secrets.token_urlsafe, max_length=64, unique=True)),
                ('used', models.BooleanField(default=False)),
                ('created_at', models.DateTimeField(auto_now_add=True)),
                ('user', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='password_reset_requests', to='auth.user')),
            ],
        ),
    ]
