from django.urls import path
from .views import login_admin

urlpatterns = [
   # Authentication URLs
    path('login/', login_admin, name='login_admin'),

]