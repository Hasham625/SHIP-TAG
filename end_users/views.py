from django.shortcuts import render, redirect
from django.contrib import messages
from django.contrib.auth.hashers import make_password, check_password
from end_users.models import PasswordResetOTP
from sql_repository import sql_repository
from .repositories.end_user import EndUserRepository
from django.contrib.auth import logout
from django.core.mail import send_mail
from django.contrib.auth.models import User
from django.http import JsonResponse
from .models import SupportMessage
from django.views.decorators.csrf import csrf_exempt
from django.views.decorators.http import require_http_methods
import json

# Login View
def login_user(request):
    if request.method == "POST":
        email = request.POST.get("email")
        password = request.POST.get("password")

        if not email or not password:
            messages.error(request, "All fields are required")
            return render(request, "end_users/login_user.html")

        enduser_repo = EndUserRepository()
        flag, message, result = enduser_repo.login_user(email, password)
        print("Login Result:", flag, message, result)  # Debugging statement

        if flag:
            # ✅ Set session
            print("Login successful, setting session for user:", result)  # Debugging statement
            request.session['user_id'] = str(result.get("id"))  # This is the UUID from end_users table
            request.session['user_name'] = result.get("name")
            request.session['user_email'] = result.get("email")
            request.session['is_logged_in'] = True
            
            return redirect('user_dashboard')
        else:
            messages.error(request, "Invalid email or password")

    return render(request, "end_users/login_user.html")


# Dashboard View (requires login)
def user_dashboard(request):
    if not request.session.get('is_logged_in'):
        return redirect('login_user')
    
    user_name = request.session.get('user_name')
    return render(request, "end_users/dashboard/dashboard.html", {"user_name": user_name})


# Step 1: Request OTP
def forgot_password(request):
    if request.method == "POST":
        email = request.POST.get("email")
        repo = EndUserRepository()

        # Check if user exists in end_users table
        flag, message, result = repo.user_exists(email)

        if flag:
            print(flag, message, result)  # Debugging statement
            otp = repo.generate_otp()

            # Save OTP in DB
            PasswordResetOTP.objects.create(email=email, otp=otp)

            # Send OTP email
            send_mail(
                "Your OTP for Password Reset",
                f"Your OTP is: {otp}. It is valid for 10 minutes.",
                "no-reply@shiptag.com",
                [email],
                fail_silently=False,
            )

            # Store email in session for verification
            request.session['reset_email'] = email
            return redirect('verify_otp')
        else:
            messages.error(request, "Email not found.")

    return render(request, "end_users/forget_password/forget_password.html")


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

    return render(request, "end_users/forget_password/forget_password_otp.html")


# Step 3: Reset Password
def reset_password(request):
    if not request.session.get('otp_verified'):
        # OTP not verified → redirect to forgot password
        return redirect('forgot_password')

    if request.method == "POST":
        email = request.session.get('reset_email')
        password = request.POST.get("password")
        confirm_password = request.POST.get("confirm_password")

        if password != confirm_password:
            messages.error(request, "Passwords do not match.")
            return render(request, "end_users/forget_password/forget_password_reset.html")

        repo = EndUserRepository()
        success, message = repo.update_password(email, password)

        if success:
            # Clear session after reset
            request.session.pop('reset_email', None)
            request.session.pop('otp_verified', None)
            messages.success(request, "Password reset successfully. Please log in.")
            return redirect('login_user')
        else:
            messages.error(request, f"Failed to reset password: {message}")

    return render(request, "end_users/forget_password/forget_password_reset.html")


def logout_user(request):
    # Properly log out the user
    logout(request)
    # Redirect to your login page (make sure the URL name matches your urls.py)
    return redirect('login_user')


# ==================== SUPPORT CHAT ENDPOINTS ====================

@csrf_exempt
@require_http_methods(["POST"])
def send_support_message(request):
    """Send a message from user to support"""
    if not request.session.get('is_logged_in'):
        return JsonResponse({'status': 'error', 'message': 'Not authenticated'}, status=401)
    
    try:
        # Get the UUID from session (this is from end_users table)
        user_uuid = request.session.get('user_id')
        
        if not user_uuid:
            return JsonResponse({'status': 'error', 'message': 'User ID not found in session'}, status=400)
        
        # Get message from POST data
        message_text = request.POST.get('message', '').strip()
        
        if not message_text:
            return JsonResponse({'status': 'error', 'message': 'Message cannot be empty'}, status=400)
        
        # Save message with UUID directly
        support_msg = SupportMessage.objects.create(
            user_id=user_uuid,  # Use UUID directly
            sender='user',
            message_text=message_text
        )
        
        return JsonResponse({
            'status': 'success',
            'message': message_text,
            'timestamp': support_msg.created_at.strftime('%Y-%m-%d %H:%M:%S')
        })
        
    except Exception as e:
        print(f"Error in send_support_message: {str(e)}")
        import traceback
        traceback.print_exc()
        return JsonResponse({'status': 'error', 'message': str(e)}, status=500)


@require_http_methods(["GET"])
def get_support_messages(request):
    """Get all messages for the current user"""
    if not request.session.get('is_logged_in'):
        return JsonResponse({'status': 'error', 'message': 'Not authenticated'}, status=401)
    
    try:
        # Get the UUID from session
        user_uuid = request.session.get('user_id')
        
        if not user_uuid:
            return JsonResponse({'status': 'error', 'message': 'User ID not found in session'}, status=400)
        
        # Get all messages for this user UUID
        messages_list = SupportMessage.objects.filter(user_id=user_uuid).order_by('created_at')
        
        messages_data = [
            {
                'sender': msg.sender,
                'message': msg.message_text,
                'timestamp': msg.created_at.strftime('%Y-%m-%d %H:%M:%S')
            }
            for msg in messages_list
        ]
        
        return JsonResponse({'status': 'success', 'messages': messages_data})
        
    except Exception as e:
        print(f"Error in get_support_messages: {str(e)}")
        import traceback
        traceback.print_exc()
        return JsonResponse({'status': 'error', 'message': str(e)}, status=500)