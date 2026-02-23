from django.urls import path
from .views import login_admin, admin_dashboard, manage_packages, add_package

urlpatterns = [
   # Authentication URLs
    path('login/', login_admin, name='login_admin'),
    path('dashboard/', admin_dashboard, name='admin_dashboard'),  # Placeholder for dashboard view



    #packages
    path('manage-packages/', manage_packages, name='manage_packages'),
    path('manage-packages/add_package/', add_package, name='add_package'),

]