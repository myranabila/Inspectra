import sqlite3
import sys

conn = sqlite3.connect('inspectra.db')
c = conn.cursor()

try:
    c.execute("SELECT id, title, status, pdf_report_path FROM inspections WHERE title LIKE '%SEP-638-C%'")
    row = c.fetchone()

    if row:
        print(f"FOUND: ID={row[0]}")
        path = row[3]
        if path is None:
            print("PDF_PATH_IS_NONE")
        elif path == "":
             print("PDF_PATH_IS_EMPTY_STRING")
        else:
            print(f"PDF_PATH_VALUE: {path}")
    else:
        print("NOT_FOUND")
except Exception as e:
    print(e)
finally:
    conn.close()
