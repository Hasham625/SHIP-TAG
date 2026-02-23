from django.urls import path
from .views import login_admin, admin_dashboard

urlpatterns = [
   # Authentication URLs
    path('login/', login_admin, name='login_admin'),
    path('dashboard/', admin_dashboard, name='admin_dashboard'),  # Placeholder for dashboard view

]