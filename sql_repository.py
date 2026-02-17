from django.db import connection, transaction
from collections import namedtuple

class sql_repository:
    def __init__(self):
        # We no longer need to manually manage self._conn
        pass

    def _dict_fetchall(self, cursor):
        """Returns all rows from a cursor as a dict (Replaces RealDictCursor)"""
        columns = [col[0] for col in cursor.description]
        return [dict(zip(columns, row)) for row in cursor.fetchall()]

    def _dict_fetchone(self, cursor):
        """Returns one row from a cursor as a dict"""
        columns = [col[0] for col in cursor.description]
        row = cursor.fetchone()
        return dict(zip(columns, row)) if row else None

    def run_one_query(self, query, values=None):
        with connection.cursor() as cursor:
            try:
                cursor.execute(query, values)
                return True, "Successfully executed", None
            except Exception as e:
                return False, f"An error occurred: {e}", None

    def run_many_query(self, query, values=None):
        with connection.cursor() as cursor:
            try:
                cursor.executemany(query, values)
                return True, "Successfully executed", None
            except Exception as e:
                return False, f"An error occurred: {e}", None

    def return_one_row(self, query, values=None):
        with connection.cursor() as cursor:
            try:
                cursor.execute(query, values)
                result = self._dict_fetchone(cursor)
                return True, "Successfully executed", result
            except Exception as e:
                return False, f"An error occurred: {e}", None

    def return_all_rows(self, query, values=None):
        with connection.cursor() as cursor:
            try:
                cursor.execute(query, values)
                result = self._dict_fetchall(cursor)
                return True, "Successfully executed", result
            except Exception as e:
                return False, f"An error occurred: {e}", None

    def run_and_return_peps(self, query, values=None):
        with connection.cursor() as cursor:
            try:
                cursor.execute(query, values)
                id_of_new_row = None
                last_id = None

                if cursor.description:
                    result = self._dict_fetchone(cursor)
                    if result:
                        id_of_new_row = result.get("pep_id")
                        last_id = result.get("position_occupancy_id")
                
                return True, None, id_of_new_row, last_id
            except Exception as e:
                return False, f"An unexpected error occurred: {str(e)}", None, None

    def run_and_return(self, query, values=None):
        return self.return_all_rows(query, values)

    def close(self):
        # Django handles closing connections automatically
        pass