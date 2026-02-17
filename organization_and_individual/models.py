from django.db import models
from datetime import timedelta
import uuid
from django.utils import timezone
# Create your models here.
# -------------------------
# Organization / Individual Users
# -------------------------
class OrganizationAndIndividualUser(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    name = models.CharField(max_length=255)
    email = models.EmailField(unique=True)
    password = models.CharField(max_length=255)
    address = models.TextField(null=True, blank=True)
    postal_code = models.CharField(max_length=20, null=True, blank=True)
    phone_number = models.CharField(max_length=20, null=True, blank=True)
    city = models.CharField(max_length=100, null=True, blank=True)
    country = models.CharField(max_length=100, null=True, blank=True)
    gender = models.CharField(max_length=20, null=True, blank=True)
    user_type = models.CharField(max_length=20)  # organization / individual
    active = models.CharField(max_length=10, default="active")
    no_of_devices = models.IntegerField(default=0)
    devices = models.JSONField(null=True, blank=True)  # store device IDs
    org_users = models.JSONField(null=True, blank=True)  # store UUIDs of organization users
    created_at = models.DateTimeField(auto_now_add=True)
    profile = models.BinaryField(null=True, blank=True)  # Store profile image as binary data

    class Meta:
        db_table = "organization_and_individual_user"
        managed = False

# -------------------------
# Organization Users (linked to Organization)
# -------------------------
class OrganizationUser(models.Model):
    id = models.UUIDField(primary_key=True, editable=True)  # UUID generated in Python
    organization_id = models.UUIDField()  # FK to organization
    name = models.CharField(max_length=255)
    email = models.EmailField(unique=True)
    password = models.CharField(max_length=255)
    address = models.TextField(null=True, blank=True)
    postal_code = models.CharField(max_length=20, null=True, blank=True)
    phone_number = models.CharField(max_length=20, null=True, blank=True)
    city = models.CharField(max_length=100, null=True, blank=True)
    country = models.CharField(max_length=100, null=True, blank=True)
    gender = models.CharField(max_length=20, null=True, blank=True)
    active = models.CharField(max_length=10, default="active")
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = "organization_user"
        managed = False


class PasswordResetOTP(models.Model):
    email = models.EmailField()
    otp = models.CharField(max_length=6)
    created_at = models.DateTimeField(auto_now_add=True)
    is_used = models.BooleanField(default=False)

    def is_valid(self):
        return not self.is_used and timezone.now() <= self.created_at + timedelta(minutes=10)