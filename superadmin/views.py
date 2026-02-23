from django.shortcuts import render, redirect
from django.contrib import messages
from django.contrib.auth.hashers import make_password, check_password
from end_users.models import PasswordResetOTP
from sql_repository import sql_repository
from .repositories.manage_admin import SuperAdminRepository
from django.contrib.auth import logout
from django.core.mail import send_mail
from django.contrib.auth.models import User
from django.http import JsonResponse
from django.views.decorators.csrf import csrf_exempt
from django.views.decorators.http import require_http_methods
import json

# Login View
def login_admin(request):
    if request.method == "POST":
        email = request.POST.get("email")
        password = request.POST.get("password")
        print("Login Attempt with Email:", email)  # Debugging statement

        if not email or not password:
            messages.error(request, "All fields are required")
            return render(request, "superadmin/login_user.html")

        superadmin_repo = SuperAdminRepository()
        flag, message, result = superadmin_repo.login_user(email, password)
        print("Login Result:", flag, message, result)  # Debugging statement

        if flag:
            # ✅ Set session
            print("Login successful, setting session for user:", result)  # Debugging statement
            request.session['user_id'] = str(result.get("id"))  # This is the UUID from super_admin table
            request.session['user_name'] = result.get("name")
            request.session['user_email'] = result.get("email")
            request.session['is_logged_in'] = True
            
            return redirect('admin_dashboard')
        else:
            messages.error(request, "Invalid email or password")

    return render(request, "superadmin/login_user.html")




def admin_dashboard(request):
    return render(request, "superadmin/dashboard/admin_dashboard.html")




def logout_user(request):
    # Properly log out the user
    logout(request)
    # Redirect to your login page (make sure the URL name matches your urls.py)
    return redirect('login_admin')

# def user_profile(request):
#     return render(request, "superadmin/profile/profile.html")

def manage_packages(request):
    return render(request, "superadmin/manage_package/manage_packages.html")

def add_package(request):
    print("Accessing add_package view")  # Debugging statement
    return render(request, "superadmin/manage_package/add_package.html")