from sql_repository import sql_repository


class PackageRepository:


    def get_all_packages(self):
        try:
            sql_repo = sql_repository()
            query = "select * from packages"
            flag, message, packages = sql_repo.return_all_rows(query)
            return True, "Packages retrieved successfully", packages
        except Exception as e:
            return False, f"Error retrieving packages: {str(e)}", None

    def get_package_details(self, package_id):
        try:
            sql_repo = sql_repository()
            query = f"""SELECT 
                        p.package_id AS package_id,
                        p.device_id,
                        p.end_user_id,
                        eu.name AS end_user_name,
                        p.organization_user_id,
                        org.name AS organization_name,

                        p.from_country,
                        p.from_city,
                        p.from_address,
                        p.from_postal_code,

                        p.to_country,
                        p.to_city,
                        p.to_address,
                        p.to_postal_code,

                        p.weight,
                        p.shipment_details,
                        p.progress_status,
                        p.created_at,
                        p.created_by,

                        p.temperature_threshold,
                        p.humidity_threshold,
                        p.pressure_threshold

                    FROM packages p

                    LEFT JOIN end_users eu 
                        ON eu.end_user_id = p.end_user_id

                    LEFT JOIN organization_and_individual_user org 
                        ON org.organization_and_individual_user_id = p.organization_user_id

                    WHERE p.package_id = '{package_id}';"""
            flag, message, data = sql_repo.return_one_row(query, package_id)
            if data:
                return True, "Package details retrieved successfully", data
            else:
                return False, "Package not found", None
        except Exception as e:
            return False, f"Error retrieving package details: {str(e)}", None
        
    def get_threshold_details(self, package_id):
        try:
            sql_repo = sql_repository()
            query = f"select temperature_threshold, pressure_threshold, humidity_threshold from packages where package_id = '{package_id}'"
             # Debugging statement
            flag, message, data = sql_repo.return_one_row(query, package_id)
            print("Threshold Details Result:", flag, message, data)  # Debugging statement
            if data:
                return True, "Threshold details retrieved successfully", data
            else:
                return False, "Threshold details not found", None
        except Exception as e:
            return False, f"Error retrieving threshold details: {str(e)}", None
        
    def update_threshold_details(self, package_id, temperature, humidity, pressure):
        try:
            sql_repo = sql_repository()
            query = f"""
                UPDATE packages
                SET temperature_threshold = {temperature},
                    humidity_threshold = {humidity},
                    pressure_threshold = {pressure}
                WHERE package_id = '{package_id}'
            """
            flag, message, data = sql_repo.run_one_query(query)
            if flag:
                return True, "Threshold details updated successfully", None
            else:
                return False, "Failed to update threshold details", None
        except Exception as e:
            return False, f"Error updating threshold details: {str(e)}", None
        
    def update_package_log(self, change_by, change_of,  change):
        try:
            sql_repo = sql_repository()

            query = f"""
                INSERT INTO packages_log (change_by, change, change_of)
                VALUES ('{change_by}', '{change}', '{change_of}')
            """

            flag, message, data = sql_repo.run_one_query(query)

            if flag:
                return True, "Package log updated successfully", None
            else:
                return False, "Failed to update package log", None

        except Exception as e:
            return False, f"Error updating package log: {str(e)}", None
