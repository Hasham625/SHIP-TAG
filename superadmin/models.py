import uuid
from django.db import models

# Create your models here.
class SuperAdmin(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    name = models.CharField(max_length=255)
    email = models.EmailField(unique=True)
    password = models.CharField(max_length=255)
    address = models.TextField(null=True, blank=True)
    profile_image = models.TextField(null=True, blank=True)
    postal_code = models.CharField(max_length=20, null=True, blank=True)
    phone_number = models.CharField(max_length=20, null=True, blank=True)
    city = models.CharField(max_length=100, null=True, blank=True)
    country = models.CharField(max_length=100, null=True, blank=True)
    gender = models.CharField(max_length=20, null=True, blank=True)
    active = models.CharField(max_length=10, default="active")
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = "super_admin"
        managed = False

# -------------------------
# Devices Table
# -------------------------
class Device(models.Model):
    device_id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    serial = models.CharField(max_length=255, unique=True)
    device_type = models.CharField(max_length=100)
    assigned_to = models.UUIDField(null=True, blank=True)  # FK to OrganizationAndIndividualUser
    active = models.CharField(max_length=10, default="active")
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = "devices"
        managed = False

# -------------------------
# Packages / Shipments
# -------------------------
class Package(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    device_id = models.UUIDField()  # FK to Device
    end_user_id = models.UUIDField()  # FK to EndUser
    organization_user_id = models.UUIDField()  # FK to OrganizationUser
    from_country = models.CharField(max_length=100)
    from_city = models.CharField(max_length=100)
    from_address = models.TextField()
    from_postal_code = models.CharField(max_length=20)
    to_country = models.CharField(max_length=100)
    to_city = models.CharField(max_length=100)
    to_address = models.TextField()
    to_postal_code = models.CharField(max_length=20)
    weight = models.FloatField()
    progress_status = models.CharField(max_length=20)  # pending / completed
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = "packages"
        managed = False

# -------------------------
# User Logs
# -------------------------
class UserLog(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    change_by = models.UUIDField()  # FK to OrganizationAndIndividualUser
    change_of = models.UUIDField()  # FK to OrganizationAndIndividualUser
    action = models.TextField()  # any description of action
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = "user_logs"
        managed = False

