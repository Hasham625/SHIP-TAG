from datetime import timedelta
from django.db import models
import uuid
from django.utils import timezone

# -------------------------
# Super Admin Table
# -------------------------



# -------------------------
# End Users
# -------------------------
class EndUser(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    name = models.CharField(max_length=255)
    email = models.EmailField(unique=True)
    password = models.CharField(max_length=255)
    package_id = models.UUIDField(null=True)  # FK to packages
    organization_id = models.UUIDField(null=True)  # FK to organization
    active = models.CharField(max_length=10, default="active")
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = "end_users"
        managed = False



class PasswordResetOTP(models.Model):
    email = models.EmailField()
    otp = models.CharField(max_length=6)
    created_at = models.DateTimeField(auto_now_add=True)
    is_used = models.BooleanField(default=False)

    def is_valid(self):
        return not self.is_used and timezone.now() <= self.created_at + timedelta(minutes=10)
    
class AlertMessage(models.Model):
    alert_id = models.AutoField(primary_key=True)
    user_id = models.UUIDField()
    device_id = models.UUIDField()
    alert_message = models.TextField()
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = "alert_messages"
        ordering = ['-created_at'] 
        managed = False

class SupportMessage(models.Model):
    message_id = models.AutoField(primary_key=True)  # ← Changed from 'id'
    user_id = models.UUIDField()  # ← Changed from ForeignKey to UUID
    sender = models.CharField(max_length=10, choices=[('user','User'), ('support','Support')])
    message_text = models.TextField()
    created_at = models.DateTimeField(auto_now_add=True)
    is_read = models.BooleanField(default=False)

    class Meta:
        db_table = "support_messages"
        ordering = ['created_at']
        managed = False  # ← Important: don't let Django manage this table

    def __str__(self):
        return f"{self.sender}: {self.message_text[:20]}"