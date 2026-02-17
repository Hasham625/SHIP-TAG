import random
from sql_repository import sql_repository
from django.contrib.auth.hashers import make_password, check_password


class ORGANDINDRepository(sql_repository):

    def login_user(self, company_name, email, password):
        sql_repo = sql_repository()

        # 🔹 CASE 1: Individual
        if company_name == "individual":

            query = """
                SELECT *
                FROM organization_and_individual_user
                WHERE email = %s
                AND status = 'active'
            """

            success, message, result = sql_repo.return_one_row(query, (email,))
            print("Login Query Result:", success, message, result)  # Debugging statement

        # 🔹 CASE 2: Organization
        else:
            # company_id = "tcs" or "dhl"
            table_name = f"{company_name.lower()}_users"

            query = f"""
                SELECT *
                FROM {table_name}
                WHERE email = %s
                AND is_active = TRUE
            """

            success, message, result = sql_repo.return_one_row(query, (email,))

        # 🔐 Password check
        if success and result:
            stored_password = result.get("password")

            if stored_password and check_password(password, stored_password):
                return True, "Login successful", result

        return False, "Invalid email or password", None

        

    def get_all_companies(self):
        sql_repo = sql_repository()
        query = "SELECT id, company_name FROM organization_and_individual_user ORDER BY company_name"

        flag, message, result = sql_repo.return_all_rows(query)
        print(result)
        return flag, message, result


    def get_user_by_email(self, email):
        sql_repo = sql_repository()

        query = "SELECT * FROM end_users WHERE email = %s"
        success, message, result = sql_repo.return_one_row(query, (email,))
        if success and result:
            return result
        return None

    # --- CREATE USER ---
    def create_user(self, name, email, password):
        sql_repo = sql_repository()

        hashed_password = make_password(password)
        query = "INSERT INTO end_users (name, email, password) VALUES (%s, %s, %s) RETURNING id"
        success, message, result = sql_repo.return_one_row(query, (name, email, hashed_password))
        return success, message, result.get("id") if result else None



    # --- DELETE USER ---
    def delete_user(self, email):
        sql_repo = sql_repository()

        query = "DELETE FROM end_users WHERE email = %s"
        success, message, _ = sql_repo.run_one_query(query, (email,))
        return success, message

    # --- LIST ALL USERS ---
    def list_users(self):
        sql_repo = sql_repository()
        query = "SELECT id, name, email FROM end_users ORDER BY id DESC"
        return sql_repo.return_all_rows(query)

    # --- GENERATE OTP ---
    def generate_otp(self):
        return str(random.randint(100000, 999999))

    # --- CHECK IF USER EXISTS ---
    def admin_exists(self, company_name, email):
        sql_repo = sql_repository()

        if company_name == "individual":

            query = """
                SELECT id
                FROM organization_and_individual_user
                WHERE email = %s
                AND status = 'active'
            """
            flag, message, result = sql_repo.return_one_row(query, (email,))
            print("Admin Exists Check:", flag, message, result)  # Debugging statement

        else:
            table_name = f"{company_name.lower()}_users"

            query = f"""
                SELECT id
                FROM {table_name}
                WHERE email = %s
                AND status = 'active'
            """
            flag, message, result = sql_repo.return_one_row(query, (email,))

        if result:
            return True, "User exists", result
        else:
            return False, "User does not exist", None
        

    # --- UPDATE PASSWORD ---
    def update_password(self, company_id, email, new_password):

        sql_repo = sql_repository()
        hashed_password = make_password(new_password)

        if company_id == "individual":

            query = """
                UPDATE organization_and_individual_user
                SET password = %s
                WHERE email = %s
            """
            success, message, _ = sql_repo.run_one_query(query, (hashed_password, email))

        else:
            table_name = f"{company_id.lower()}_users"

            query = f"""
                UPDATE {table_name}
                SET password = %s
                WHERE email = %s
            """
            success, message, _ = sql_repo.run_one_query(query, (hashed_password, email))

        return success, message
    
    def update_profile(self, user_id, company_name, profile_data):
        """
        Update user profile information based on company type.
        
        Args:
            user_id (str): User UUID
            company_name (str): Company/table name (e.g., 'individual', 'xyz')
            profile_data (dict): Dictionary containing profile fields to update
        
        Returns:
            tuple: (success: bool, message: str)
        """
        try:
            sql_repo = sql_repository()
            update_fields = []
            update_values = []

            # Map frontend field names to database column names
            field_mapping = {
                'name': 'name',
                'email': 'email',
                'phone_number': 'phone_number',
                'gender': 'gender',
                'address': 'address',
                'city': 'city',
                'postal_code': 'postal_code',
                'country': 'country',
                'profile': 'profile'  # Added for bytea field if needed
            }

            # Build the SET part of the update query dynamically
            for frontend_field, db_field in field_mapping.items():
                if frontend_field in profile_data and profile_data[frontend_field] is not None:
                    update_fields.append(f"{db_field} = %s")
                    update_values.append(profile_data[frontend_field])

            if not update_fields:
                return False, "No fields to update"

            # Determine the correct table
            if company_name.lower() == "individual":
                table_name = "organization_and_individual_user"
            else:
                table_name = f"{company_name.lower()}_users"

            # Add user_id for WHERE clause
            update_values.append(user_id)

            # Construct the SQL query
            update_query = f"""
                UPDATE {table_name}
                SET {', '.join(update_fields)}
                WHERE id = %s
            """

            print(f"Executing update query: {update_query}")
            print(f"With values: {update_values}")

            # Execute query
            success, message, _ = sql_repo.run_one_query(update_query, tuple(update_values))

            if success:
                return True, "Profile updated successfully"
            else:
                return False, f"Failed to update profile: {message}"

        except Exception as e:
            print(f"Error in update_profile: {str(e)}")
            return False, f"An error occurred: {str(e)}"


    # ========================================
    # Verify Password Method
    # ========================================
    # ========================================
    # Verify Password
    # ========================================
    def verify_password(self, user_id, company_name, password):
        """
        Verify user's current password
        """
        try:
            sql_repo = sql_repository()
            table_name = "organization_and_individual_user"
            if company_name.lower() == "individual":
                table_name = "organization_and_individual_user"
            else:
                table_name = f"{company_name.lower()}_users"

            query = f"SELECT password FROM {table_name} WHERE id = %s"
            flag, message, result = sql_repo.return_one_row(query, (user_id,))

            if not flag or not result:
                return False, "User not found"

            stored_password = result[0]['password']
            if check_password(password, stored_password):
                return True, "Password verified"
            else:
                return False, "Password is incorrect"

        except Exception as e:
            print(f"Error in verify_password: {str(e)}")
            return False, f"An error occurred: {str(e)}"


    # ========================================
    # Update Profile Image
    # ========================================
    def update_profile_image(self, user_id, company_name, image_data, content_type='image/jpeg'):
        """
        Save profile image as BYTEA in PostgreSQL
        """
        try:
            sql_repo = sql_repository()
            from psycopg2 import Binary
            table_name = "organization_and_individual_user" if company_name.lower() == "individual" else f"{company_name.lower()}_users"

            update_query = f"""
                UPDATE {table_name}
                SET profile_image = %s, image_content_type = %s
                WHERE id = %s
            """
            flag, message, _ = sql_repo.run_one_query(update_query, (Binary(image_data), content_type, user_id))

            if flag:
                return True, "Profile image updated successfully"
            else:
                return False, f"Failed to update profile image: {message}"

        except Exception as e:
            print(f"Error in update_profile_image: {str(e)}")
            return False, f"An error occurred: {str(e)}"


    # ========================================
    # Get Profile Image
    # ========================================
    def get_profile_image(self, user_id, company_name):
        """
        Retrieve profile image from database
        """
        try:
            sql_repo = sql_repository()
            table_name = "organization_and_individual_user" if company_name.lower() == "individual" else f"{company_name.lower()}_users"

            query = f"SELECT profile_image, image_content_type FROM {table_name} WHERE id = %s"
            flag, message, result = sql_repo.return_one_row(query, (user_id,))

            if flag and result and result[0].get('profile_image'):
                image_data = result[0]['profile_image']
                content_type = result[0].get('image_content_type', 'image/jpeg')
                if isinstance(image_data, memoryview):
                    image_data = bytes(image_data)
                return True, "Image found", image_data, content_type
            else:
                return False, "No profile image found", None, None

        except Exception as e:
            print(f"Error in get_profile_image: {str(e)}")
            return False, f"An error occurred: {str(e)}", None, None


    # ========================================
    # Admin Profile Fetch
    # ========================================
    def admin_profile(self, user_id, company_name):
        """
        Fetch admin profile information
        
        Args:
            user_id: UUID of the user
            company_name: Company name or 'individual'
        
        Returns:
            tuple: (success: bool, message: str, profile_data: dict or None)
        """
        try:
            sql_repo = sql_repository()
            
            # Query to fetch user profile with explicit column names
            query = """
                SELECT 
                    id,
                    user_type,
                    name,
                    email,
                    phone_number,
                    address,
                    city,
                    country,
                    postal_code,
                    profile_image,
                    no_of_devices,
                    gender,
                    date_of_birth,
                    company_registration_number,
                    company_name,
                    website,
                    created_at,
                    status
                FROM organization_and_individual_user
                WHERE id = %s AND company_name = %s
            """
            
            flag, message, result = sql_repo.return_one_row(query, (user_id, company_name))
            
            print(f"Admin Profile Query Result: flag={flag}, message={message}, result={result is not None}")
            
            if not flag or not result:
                return False, message or "Profile not found", None
            
            # Define column names in the same order as the SELECT query
            columns = [
                'id', 'user_type', 'name', 'email', 'phone_number', 
                'address', 'city', 'country', 'postal_code', 'profile_image',
                'no_of_devices', 'gender', 'date_of_birth', 'company_registration_number',
                'company_name', 'website', 'created_at', 'status'
            ]
            
            # Create dictionary from result
            profile_data = dict(zip(columns, result))
            
            print(f"Profile data created with {len(profile_data)} fields")
            
            # Handle profile image - convert bytes to base64 if present
            profile_base64 = None
            if profile_data.get('profile_image'):
                import base64
                try:
                    # If profile_image is bytes
                    if isinstance(profile_data['profile_image'], bytes):
                        profile_base64 = f"data:image/jpeg;base64,{base64.b64encode(profile_data['profile_image']).decode('utf-8')}"
                    # If it's already a string (base64 or path)
                    elif isinstance(profile_data['profile_image'], str):
                        if not profile_data['profile_image'].startswith('data:'):
                            profile_base64 = f"data:image/jpeg;base64,{profile_data['profile_image']}"
                        else:
                            profile_base64 = profile_data['profile_image']
                    print(f"Profile image processed successfully")
                except Exception as img_error:
                    print(f"Error processing profile image: {img_error}")
                    profile_base64 = None
            
            # Add processed profile image to data
            profile_data['profile_base64'] = profile_base64
            
            # Format created_at for display
            # Format created_at for display
            if profile_data.get('created_at'):
                try:
                    # Convert string to datetime if needed
                    from datetime import datetime

                    created_at_value = profile_data['created_at']
                    if isinstance(created_at_value, str):
                        # Try parsing common datetime format returned by PostgreSQL
                        try:
                            created_at_dt = datetime.fromisoformat(created_at_value)
                        except ValueError:
                            # Fallback: if format is unknown, just use the string
                            created_at_dt = None
                    elif isinstance(created_at_value, datetime):
                        created_at_dt = created_at_value
                    else:
                        created_at_dt = None

                    if created_at_dt:
                        profile_data['created_at_formatted'] = created_at_dt.strftime("%B %d, %Y")
                    else:
                        profile_data['created_at_formatted'] = str(created_at_value)

                except Exception as date_error:
                    print(f"Error formatting date: {date_error}")
                    profile_data['created_at_formatted'] = str(profile_data['created_at'])

            
            # Convert UUID to string for JSON serialization
            if profile_data.get('id'):
                profile_data['id'] = str(profile_data['id'])
            
            print(f"Profile data successfully prepared with ID: {profile_data.get('id')}")
            
            return True, "Profile fetched successfully", profile_data
            
        except Exception as e:
            print(f"Error in admin_profile: {e}")
            import traceback
            traceback.print_exc()
            return False, f"An error occurred: {str(e)}", None

    # ========================================
    # Get Profile Image Base64
    # ========================================
    def get_profile_image_base64(self, user_id, company_name):
        """
        Return profile image as Base64
        """
        try:
            success, message, image_data, content_type = self.get_profile_image(user_id, company_name)
            if success and image_data:
                import base64
                image_base64 = base64.b64encode(image_data).decode('utf-8')
                data_url = f"data:{content_type};base64,{image_base64}"
                return True, "Image retrieved", data_url
            else:
                return False, message or "No image found", None
        except Exception as e:
            print(f"Error in get_profile_image_base64: {str(e)}")
            return False, f"An error occurred: {str(e)}", None


    # ========================================
    # Check Email Uniqueness
    # ========================================
    def is_email_unique(self, email, company_name, exclude_user_id=None):
        """
        Check if email is unique
        """
        try:
            sql_repo = sql_repository()
            table_name = "organization_and_individual_user" if company_name.lower() == "individual" else f"{company_name.lower()}_users"

            if exclude_user_id:
                query = f"SELECT COUNT(*) as count FROM {table_name} WHERE email = %s AND id != %s"
                params = (email, exclude_user_id)
            else:
                query = f"SELECT COUNT(*) as count FROM {table_name} WHERE email = %s"
                params = (email,)

            flag, message, result = sql_repo.return_one_row(query, params)
            if flag and result:
                count = result[0]['count']
                return (count == 0, "Email is unique" if count == 0 else "Email already exists")
            else:
                return False, "Error checking email uniqueness"

        except Exception as e:
            print(f"Error in is_email_unique: {str(e)}")
            return False, f"An error occurred: {str(e)}"


    # ========================================
    # Delete Profile Image
    # ========================================
    def delete_profile_image(self, user_id, company_name):
        """
        Delete user's profile image
        """
        try:
            sql_repo = sql_repository()
            table_name = "organization_and_individual_user" if company_name.lower() == "individual" else f"{company_name.lower()}_users"

            update_query = f"""
                UPDATE {table_name}
                SET profile_image = NULL,
                    image_content_type = NULL
                WHERE id = %s
            """
            flag, message, _ = sql_repo.run_one_query(update_query, (user_id,))

            if flag:
                return True, "Profile image deleted successfully"
            else:
                return False, f"Failed to delete profile image: {message}"

        except Exception as e:
            print(f"Error in delete_profile_image: {str(e)}")
            return False, f"An error occurred: {str(e)}"



