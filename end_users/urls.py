from django.urls import path
from .views import login_user, user_dashboard, logout_user, forgot_password, verify_otp, reset_password, send_support_message, get_support_messages

urlpatterns = [
   # Authentication URLs
    path('login/', login_user, name='login_user'),
    path('logout_user/', logout_user, name='logout_user'),
    path('user_dashboard/',user_dashboard, name='user_dashboard'),
    
    # Password Reset URLs
    path('forgot-password/', forgot_password, name='forgot_password'),
    path('verify-otp/',verify_otp, name='verify_otp'),
    path('reset-password/', reset_password, name='reset_password'),
    
    # Support Chat URLs
    path('send_support_message/',send_support_message, name='send_support_message'),
    path('get_support_messages/',get_support_messages, name='get_support_messages'),
]


