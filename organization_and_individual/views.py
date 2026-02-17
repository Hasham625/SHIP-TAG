import base64
import os
import uuid
from django.shortcuts import render

# Create your views here.
from django.shortcuts import render, redirect
from django.contrib import messages
from django.contrib.auth.hashers import make_password, check_password
from end_users.models import PasswordResetOTP
from sql_repository import sql_repository
from .repositories.org_and_ind import ORGANDINDRepository
from django.contrib.auth import logout
from django.core.mail import send_mail
from django.contrib.auth.models import User
from django.http import HttpResponse, JsonResponse
from django.views.decorators.csrf import csrf_exempt
from django.views.decorators.http import require_http_methods
import json

# Login View
def login(request):
    adminuser_repo = ORGANDINDRepository()

    # 🔹 Get company list (create this function in repo)
    flag, message, companies = adminuser_repo.get_all_companies()  # Should return list of dicts
    print("Companies Retrieved:", flag, message, companies)  # Debugging statement

    if request.method == "POST":
        company_name = request.POST.get("company")
        email = request.POST.get("email")
        password = request.POST.get("password")
        print("Login Attempt:", company_name, email)  # Debugging statement
        if not company_name or not email or not password:
            messages.error(request, "All fields are required")
            return render(request, "organization_and_individual/login.html", {
                "companies": companies
            })

        flag, message, result = adminuser_repo.login_user(company_name, email, password)

        if flag:
            request.session['user_id'] = str(result.get("id"))
            request.session['user_name'] = result.get("name")
            request.session['user_email'] = result.get("email")
            request.session['company_name'] = company_name
            request.session['is_logged_in'] = True
            
            return redirect('dashboard')
        else:
            messages.error(request, "Invalid credentials")

    return render(request, "organization_and_individual/login.html", {
    "companies": companies,
    "selected_company": request.POST.get("company")
})


# Step 1: Request OTP
def forgot_password(request):
    repo = ORGANDINDRepository()

    # Fetch allowed companies dynamically
    flag, message, companies = repo.get_all_companies()

    if request.method == "POST":
        company_name = request.POST.get("company")
        email = request.POST.get("email")

        flag_user, message_user, result = repo.admin_exists(company_name, email)

        if flag_user:
            otp = repo.generate_otp()
            PasswordResetOTP.objects.create(email=email, otp=otp)

            send_mail(
                "Your OTP for Password Reset",
                f"Your OTP is: {otp}. It is valid for 10 minutes.",
                "no-reply@shiptag.com",
                [email],
                fail_silently=False,
            )

            request.session['reset_email'] = email
            request.session['reset_company'] = company_name

            return redirect('verify_otp')
        else:
            messages.error(request, "Email not found.")

    return render(request, "organization_and_individual/forget_password/forget_password.html", {
        "companies": companies
    })



# Step 2: Verify OTP
def verify_otp(request):
    if request.method == "POST":
        email = request.session.get('reset_email')
        if not email:
            return redirect('forgot_password')

        input_otp = (
            request.POST.get("otp1", "") +
            request.POST.get("otp2", "") +
            request.POST.get("otp3", "") +
            request.POST.get("otp4", "") +
            request.POST.get("otp5", "") +
            request.POST.get("otp6", "")
        )

        otp_record = PasswordResetOTP.objects.filter(email=email, otp=input_otp, is_used=False).last()
        print("OTP Verification Attempt:", email, input_otp, otp_record)  # Debugging statement

        if otp_record and otp_record.is_valid():
            print("OTP is valid, proceeding to reset password")  # Debugging statement
            # Mark OTP as used
            otp_record.is_used = True
            otp_record.save()

            # Mark OTP verification in session
            request.session['otp_verified'] = True
            return redirect('reset_password')
        else:
            messages.error(request, "Invalid or expired OTP.")

    return render(request, "organization_and_individual/forget_password/forget_password_otp.html")


# Step 3: Reset Password
def reset_password(request):

    if not request.session.get('otp_verified'):
        return redirect('forgot_password')

    if request.method == "POST":

        email = request.session.get('reset_email')
        company_id = request.session.get('reset_company')

        password = request.POST.get("password")
        confirm_password = request.POST.get("confirm_password")

        if password != confirm_password:
            messages.error(request, "Passwords do not match.")
            return render(request, "organization_and_individual/forget_password/forget_password_reset.html")

        repo = ORGANDINDRepository()
        success, message = repo.update_password(company_id, email, password)

        if success:
            request.session.pop('reset_email', None)
            request.session.pop('reset_company', None)
            request.session.pop('otp_verified', None)

            messages.success(request, "Password reset successfully.")
            return redirect('login')
        else:
            messages.error(request, f"Failed to reset password: {message}")

    return render(request, "organization_and_individual/forget_password/forget_password_reset.html")



def logout_admin(request):
    # Properly log out the user
    logout(request)
    # Redirect to your login page (make sure the URL name matches your urls.py)
    return redirect('login')


# Dashboard View (requires login)
def dashboard(request):
    if not request.session.get('is_logged_in'):
        return redirect('login_user')
    
    user_name = request.session.get('user_name')
    return render(request, "organization_and_individual/dashboard/dashboard.html", {"user_name": user_name})


# ========================================
# Profile View (Display Profile Page)
# ========================================
def admin_profile(request):
    """Display the admin profile page"""
    if not request.session.get('is_logged_in'):
        return redirect('login')
    
    user_id = request.session.get('user_id')
    company_name = request.session.get('company_name')

    print(f"Fetching profile for user_id: {user_id}, company_name: {company_name}")

    repo = ORGANDINDRepository()
    
    # Use the repository method to fetch profile safely
    success, message, profile_data = repo.admin_profile(user_id, company_name)
    print(f"Profile Data Retrieved: success={success}, message={message}, profile_data={profile_data}")  # Debugging statement
    print(f"Profile Data Retrieved: success={success}, message={message}, has_data={profile_data is not None}")

    if not success or profile_data is None:
        messages.error(request, message or "Unable to fetch profile")
        return redirect('dashboard')

    # Profile data is already formatted in the repository
    return render(request, "organization_and_individual/admin_profile/profile.html", {
        "admin_details": profile_data,
        "profile_base64": profile_data.get('profile_base64')
    })


# ========================================
# Update Profile API
# ========================================
@csrf_exempt
@require_http_methods(["PUT", "POST"])
def update_profile(request):
    """
    API endpoint to update user profile
    Accepts: PUT/POST request with JSON body
    Returns: JSON response with success status
    """
    try:
        # Check if user is logged in
        if not request.session.get('is_logged_in'):
            return JsonResponse({
                'success': False,
                'message': 'Authentication required'
            }, status=401)

        # Parse JSON data
        if request.method == 'PUT':
            data = json.loads(request.body)
        else:
            data = json.loads(request.body) if request.body else request.POST.dict()

        # Get user_id from session or request
        user_id = data.get('user_id') or request.session.get('user_id')
        company_name = request.session.get('company_name')

        if not user_id:
            return JsonResponse({
                'success': False,
                'message': 'User ID is required'
            }, status=400)

        # Extract profile data
        profile_data = {
            'name': data.get('name'),
            'email': data.get('email'),
            'phone_number': data.get('phone_number'),
            'gender': data.get('gender'),
            'address': data.get('address'),
            'city': data.get('city'),
            'postal_code': data.get('postal_code'),
            'country': data.get('country'),
        }

        # Validate required fields
        if not all([profile_data['name'], profile_data['email'], profile_data['phone_number']]):
            return JsonResponse({
                'success': False,
                'message': 'Name, email, and phone number are required'
            }, status=400)

        # Update profile in database
        repo = ORGANDINDRepository()
        success, message = repo.update_profile(user_id, company_name, profile_data)

        if success:
            # Update session with new data
            request.session['user_name'] = profile_data['name']
            request.session['user_email'] = profile_data['email']

            return JsonResponse({
                'success': True,
                'message': 'Profile updated successfully',
                'data': profile_data
            })
        else:
            return JsonResponse({
                'success': False,
                'message': message or 'Failed to update profile'
            }, status=400)

    except json.JSONDecodeError:
        return JsonResponse({
            'success': False,
            'message': 'Invalid JSON data'
        }, status=400)
    except Exception as e:
        print(f"Error updating profile: {str(e)}")
        return JsonResponse({
            'success': False,
            'message': f'An error occurred: {str(e)}'
        }, status=500)


# ========================================
# Change Password API
# ========================================
@csrf_exempt
@require_http_methods(["POST"])
def change_password(request):
    """
    API endpoint to change user password
    Accepts: POST request with JSON body containing current and new password
    Returns: JSON response with success status
    """
    try:
        # Check if user is logged in
        if not request.session.get('is_logged_in'):
            return JsonResponse({
                'success': False,
                'message': 'Authentication required'
            }, status=401)

        # Parse JSON data
        data = json.loads(request.body) if request.body else request.POST.dict()

        # Get user_id from session or request
        user_id = data.get('user_id') or request.session.get('user_id')
        company_name = request.session.get('company_name')
        current_password = data.get('current_password')
        new_password = data.get('new_password')

        # Validate inputs
        if not all([user_id, current_password, new_password]):
            return JsonResponse({
                'success': False,
                'message': 'User ID, current password, and new password are required'
            }, status=400)

        if len(new_password) < 8:
            return JsonResponse({
                'success': False,
                'message': 'New password must be at least 8 characters long'
            }, status=400)

        # Verify current password and update
        repo = ORGANDINDRepository()
        
        # First, verify the current password
        verify_success, verify_message = repo.verify_password(user_id, company_name, current_password)
        
        if not verify_success:
            return JsonResponse({
                'success': False,
                'message': 'Current password is incorrect'
            }, status=400)

        # Update to new password
        success, message = repo.update_password(company_name, request.session.get('user_email'), new_password)

        if success:
            return JsonResponse({
                'success': True,
                'message': 'Password changed successfully'
            })
        else:
            return JsonResponse({
                'success': False,
                'message': message or 'Failed to change password'
            }, status=400)

    except json.JSONDecodeError:
        return JsonResponse({
            'success': False,
            'message': 'Invalid JSON data'
        }, status=400)
    except Exception as e:
        print(f"Error changing password: {str(e)}")
        return JsonResponse({
            'success': False,
            'message': f'An error occurred: {str(e)}'
        }, status=500)


# ========================================
# Upload Profile Image API (Save to PostgreSQL)
# ========================================
@csrf_exempt
@require_http_methods(["POST"])
def upload_profile_image(request):
    """
    API endpoint to upload user profile image and save to PostgreSQL
    Accepts: POST request with multipart/form-data containing image file
    Returns: JSON response with success status and base64 image data
    """
    try:
        # Check if user is logged in
        if not request.session.get('is_logged_in'):
            return JsonResponse({
                'success': False,
                'message': 'Authentication required'
            }, status=401)

        # Get user_id
        user_id = request.POST.get('user_id') or request.session.get('user_id')
        company_name = request.session.get('company_name')

        if not user_id:
            return JsonResponse({
                'success': False,
                'message': 'User ID is required'
            }, status=400)

        # Check if image file is present
        if 'profile_image' not in request.FILES:
            return JsonResponse({
                'success': False,
                'message': 'No image file provided'
            }, status=400)

        image_file = request.FILES['profile_image']

        # Validate file size (5MB limit)
        if image_file.size > 5 * 1024 * 1024:
            return JsonResponse({
                'success': False,
                'message': 'Image size should be less than 5MB'
            }, status=400)

        # Validate file type
        allowed_types = ['image/jpeg', 'image/jpg', 'image/png', 'image/gif', 'image/webp']
        if image_file.content_type not in allowed_types:
            return JsonResponse({
                'success': False,
                'message': 'Invalid file type. Allowed types: JPG, PNG, GIF, WEBP'
            }, status=400)

        # Read image binary data
        image_data = image_file.read()
        
        # Convert to base64 for storage and transmission
        image_base64 = base64.b64encode(image_data).decode('utf-8')

        # Update database with image binary data
        repo = ORGANDINDRepository()
        success, message = repo.update_profile_image(
            user_id, 
            company_name, 
            image_data,  # Store as binary
            image_file.content_type  # Store MIME type
        )

        if success:
            # Return base64 encoded image for immediate display
            data_url = f"data:{image_file.content_type};base64,{image_base64}"
            
            return JsonResponse({
                'success': True,
                'message': 'Profile image uploaded successfully',
                'image_url': data_url,
                'image_type': image_file.content_type
            })
        else:
            return JsonResponse({
                'success': False,
                'message': message or 'Failed to update profile image'
            }, status=400)

    except Exception as e:
        print(f"Error uploading profile image: {str(e)}")
        return JsonResponse({
            'success': False,
            'message': f'An error occurred: {str(e)}'
        }, status=500)


# ========================================
# Get Profile Image (Retrieve from PostgreSQL)
# ========================================
@require_http_methods(["GET"])
def get_profile_image(request):
    """
    API endpoint to retrieve user profile image from PostgreSQL
    Accepts: GET request with user_id parameter
    Returns: Image file response
    """
    try:
        # Check if user is logged in
        if not request.session.get('is_logged_in'):
            return JsonResponse({
                'success': False,
                'message': 'Authentication required'
            }, status=401)

        user_id = request.GET.get('user_id') or request.session.get('user_id')
        company_name = request.session.get('company_name')

        if not user_id:
            return JsonResponse({
                'success': False,
                'message': 'User ID is required'
            }, status=400)

        # Get image from database
        repo = ORGANDINDRepository()
        success, message, image_data, content_type = repo.get_profile_image(user_id, company_name)

        if success and image_data:
            # Return image as HTTP response
            response = HttpResponse(image_data, content_type=content_type or 'image/jpeg')
            response['Content-Disposition'] = f'inline; filename="profile_{user_id}.jpg"'
            return response
        else:
            # Return default placeholder image or 404
            return JsonResponse({
                'success': False,
                'message': 'No profile image found'
            }, status=404)

    except Exception as e:
        print(f"Error retrieving profile image: {str(e)}")
        return JsonResponse({
            'success': False,
            'message': f'An error occurred: {str(e)}'
        }, status=500)


# ========================================
# Get Profile Data API (with Base64 Image)
# ========================================
@require_http_methods(["GET"])
def get_profile_data(request):
    """
    API endpoint to get user profile data in JSON format with base64 image
    Accepts: GET request
    Returns: JSON response with profile data including base64 image
    """
    try:
        # Check if user is logged in
        if not request.session.get('is_logged_in'):
            return JsonResponse({
                'success': False,
                'message': 'Authentication required'
            }, status=401)

        user_id = request.session.get('user_id')
        company_name = request.session.get('company_name')

        repo = ORGANDINDRepository()
        success, message, profile_data = repo.admin_profile(user_id, company_name)

        if success:
            # Convert binary image to base64 if exists
            if profile_data.get('profile_image'):
                image_data = profile_data['profile_image']
                content_type = profile_data.get('image_content_type', 'image/jpeg')
                
                # Convert bytes to base64
                if isinstance(image_data, (bytes, memoryview)):
                    image_base64 = base64.b64encode(bytes(image_data)).decode('utf-8')
                    profile_data['profile_image_url'] = f"data:{content_type};base64,{image_base64}"
                    # Remove binary data from response
                    del profile_data['profile_image']
                else:
                    profile_data['profile_image_url'] = None
            else:
                profile_data['profile_image_url'] = None

            return JsonResponse({
                'success': True,
                'data': profile_data
            })
        else:
            return JsonResponse({
                'success': False,
                'message': message or 'Failed to fetch profile data'
            }, status=400)

    except Exception as e:
        print(f"Error fetching profile data: {str(e)}")
        return JsonResponse({
            'success': False,
            'message': f'An error occurred: {str(e)}'
        }, status=500)


 ##
from django.shortcuts import render, redirect
from django.contrib import messages

def device_details(request, device_id):
    """Display device details page"""

    if not request.session.get('is_logged_in'):
        return redirect('login')

    try:
        # 🔹 Replace this with your repository/database call
        device_data = {
            "device_id": device_id,
            "min_temp": -10,
            "max_temp": 25,
            "min_humidity": 20,
            "max_humidity": 80,
        }

        package_history = [
            {
                "package_id": "PKG-8812",
                "assigned_date": "2025-01-10",
                "status": "Completed"
            },
            {
                "package_id": "PKG-7740",
                "assigned_date": "2024-12-05",
                "status": "Completed"
            }
        ]

        return render(request, "organization/device_details.html", {
            "device": device_data,
            "package_history": package_history
        })

    except Exception as e:
        print("Error in device_details:", e)
        messages.error(request, "Unable to load device details.")
        return redirect('dashboard')


from django.shortcuts import render, redirect
from django.contrib import messages

def manage_devices(request):
    if not request.session.get('is_logged_in'):
        return redirect('login')

    try:
        # 🔹 Replace this with your repository/database call
        devices = [
            {
                "id": "DEV-4421",
                "type": "GPS Tracker",
                "status": "Online"
            },
            {
                "id": "DEV-8833",
                "type": "Temp Sensor",
                "status": "Offline"
            }
        ]

        # Handle Add Device POST
        if request.method == "POST" and request.POST.get("register_device"):
            device_type = request.POST.get("device_type")
            serial_number = request.POST.get("serial_number")
            min_temp = request.POST.get("min_temp")
            max_temp = request.POST.get("max_temp")
            min_humid = request.POST.get("min_humid")
            max_humid = request.POST.get("max_humid")

            # 🔹 Save to database here
            print("New Device:", device_type, serial_number)

            messages.success(request, "Device registered successfully.")
            return redirect("manage_devices")

        return render(request, "organization/manage_devices.html", {
            "devices": devices
        })

    except Exception as e:
        print("Error in manage_devices:", e)
        messages.error(request, "Unable to load devices.")
        return redirect("dashboard")
