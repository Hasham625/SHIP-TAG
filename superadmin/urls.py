from django.urls import path
from .views import login_admin, admin_dashboard, manage_packages, add_package, view_package, change_package_threshold, logout_user

urlpatterns = [
   # Authentication URLs
    path('login/', login_admin, name='login_admin'),
    path('dashboard/', admin_dashboard, name='admin_dashboard'),  # Placeholder for dashboard view
    path('logout_user/', logout_user, name='logout_user'),



    #packages
    path('manage-packages/', manage_packages, name='manage_packages'),
    path('manage-packages/add-package/', add_package, name='add_package'),
    path('manage-packages/view-package/<uuid:id>/', view_package, name='view_package'),
    path('manage-packages/change-package-threshold/<uuid:id>/', change_package_threshold, name='change_package_threshold'),
]