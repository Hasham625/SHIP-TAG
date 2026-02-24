from django.shortcuts import render, redirect
from django.contrib import messages
from django.contrib.auth.hashers import make_password, check_password
from end_users.models import PasswordResetOTP
from sql_repository import sql_repository
from .repositories.manage_admin import SuperAdminRepository
from django.contrib.auth import logout
from django.core.mail import send_mail
from django.contrib.auth.models import User
from django.http import HttpResponse, JsonResponse
from django.views.decorators.csrf import csrf_exempt
from django.views.decorators.http import require_http_methods
import json
from .repositories.manage_package import PackageRepository
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
            request.session['user_id'] = str(result.get("super_admin_id"))  # This is the UUID from super_admin table
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
    package_repo = PackageRepository()
    flag, message, result = package_repo.get_all_packages()
    context = {
        "flag": flag,
        "message": message,
        "packages": result
    }
    print("Manage Packages Result:", context)  # Debugging statement
    return render(request, "superadmin/manage_package/manage_packages.html", context)


def add_package(request):
    print("Accessing add_package view")  # Debugging statement
    return render(request, "superadmin/manage_package/add_package.html")


def view_package(request, id):
    package_repo = PackageRepository()

    flag, message, result = package_repo.get_package_details(id)
    print("View Package Result:", flag, message, result)  # Debugging statement
    context = {
        "flag": flag,
        "message": message,
        "package": result
    }

    return render(
        request,
        "superadmin/manage_package/view_package.html",
        context
    )

def change_package_threshold(request, id):

    package_repo = PackageRepository()

    print("Accessing change_package_threshold view for package ID:", id)

    flag, message, result = package_repo.get_threshold_details(id)

    print("Threshold Details Result:", flag, message, result)

    if request.method == "POST":

        temperature = request.POST.get("temperature_threshold")
        humidity = request.POST.get("humidity_threshold")
        pressure = request.POST.get("pressure_threshold")
        print("Received Thresholds - Temperature:", temperature, "Humidity:", humidity, "Pressure:", pressure)  # Debugging statement
        # # Update repository
        flag, message, result = package_repo.update_threshold_details(
            id,
            temperature,
            humidity,
            pressure
        )
        change_by  = request.session.get('user_id')
        change_of = id
        flag, message, log_result = package_repo.update_package_log(change_by, change_of, "Update Threshold")

        return HttpResponse("""
        <script>
        parent.location.reload();
        parent.jQuery.fancybox.close();
        </script>
        """)

    context = {
        "package_id": id,
        "threshold_details": result
    }
    print(context)
    return render(
        request,
        "superadmin/manage_package/change_package_threshold.html",
        context
    )