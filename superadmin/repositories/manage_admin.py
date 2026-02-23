import random
from sql_repository import sql_repository
from django.contrib.auth.hashers import make_password, check_password


class SuperAdminRepository(sql_repository):

    def login_user(self, email, password):
        sql_repo = sql_repository()

        query = "SELECT * FROM super_admin WHERE email = %s"

        success, message, result = sql_repo.return_one_row(query, (email,))
        print("Login Query:", success, message, result)  # Debugging statement
        if success and result:
            stored_password = result.get("password")  # hashed password in DB
            
            print("Stored Hashed Password:", stored_password)  # Debugging statement
            if check_password(password, stored_password):
                return True, "Login successful", result
            else:
                return False, "Invalid email or password", None
        else:
            return False, "Invalid email or password", None