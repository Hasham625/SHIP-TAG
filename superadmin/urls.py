from django.urls import path
from .views import login, dashboard, logout_admin, forgot_password, verify_otp, reset_password, admin_profile, update_profile, change_password, upload_profile_image

urlpatterns = [
   # Authentication URLs
    path('login/', login, name='login'),
    path('logout-admin/', logout_admin, name='logout_admin'),
    path('dashboard/',dashboard, name='dashboard'),

    # Password Reset URLs
    path('forgot-password/', forgot_password, name='forgot_password'),
    path('verify-otp/',verify_otp, name='verify_otp'),
    path('reset-password/', reset_password, name='reset_password'),

    # Admin Profile URL
    path('admin-profile/', admin_profile, name='admin_profile'),


    path('api/profile/update', update_profile, name='update_profile'),
    path('api/profile/change-password', change_password, name='change_password'),
    path('api/profile/upload-image', upload_profile_image, name='upload_profile_image'),
]