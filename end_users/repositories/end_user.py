import random
from sql_repository import sql_repository
from django.contrib.auth.hashers import make_password, check_password


class EndUserRepository(sql_repository):



    def login_user(self, email, password):
        sql_repo = sql_repository()

        query = "SELECT * FROM end_users WHERE email = %s"

        success, message, result = sql_repo.return_one_row(query, (email,))
        print("Login Query Result:", success, message, result)  # Debugging statement
        if success and result:
            stored_password = result.get("password")  # hashed password in DB
            print("Stored Hashed Password:", stored_password)  # Debugging statement
            if check_password(password, stored_password):
                return True, "Login successful", result
            else:
                return False, "Invalid email or password", None
        else:
            return False, "Invalid email or password", None
        

    import random

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

    # --- UPDATE PASSWORD ---
    def update_password(self, email, new_password):
        sql_repo = sql_repository()

        hashed_password = make_password(new_password)
        query = "UPDATE end_users SET password = %s WHERE email = %s"
        success, message, _ = sql_repo.run_one_query(query, (hashed_password, email))
        return success, message

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
    def user_exists(self, email):
        sql_repo = sql_repository()

        query = "SELECT id FROM end_users WHERE email = %s"
        
        flag, message, result = sql_repo.return_one_row(query, (email,))
        print("User Exists Query Result:", flag, message, result)  # Debugging statement
        if result:
            return True, "User exists", result
        else:           
            print("User does not exist for email:", email)  # Debugging statement
            return False, "User does not exist", None
