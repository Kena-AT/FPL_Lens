import os
import psycopg2
import pytest
from dotenv import load_dotenv


def test_connection():
    load_dotenv()

    db_url = os.getenv("DATABASE_URL")
    db_pooled_url = os.getenv("DATABASE_URL_POOLED")

    urls = []
    if db_url:
        urls.append(("direct", db_url))
    if db_pooled_url:
        urls.append(("pooled", db_pooled_url))

    if not urls:
        pytest.skip("Neither DATABASE_URL nor DATABASE_URL_POOLED is set")

    for name, url in urls:
        conn = psycopg2.connect(url, connect_timeout=10)
        cur = conn.cursor()
        cur.execute("SELECT version();")
        version = cur.fetchone()[0]
        cur.execute("SELECT current_database();")
        db_name = cur.fetchone()[0]
        cur.close()
        conn.close()
        assert db_name and version, f"Neon {name} check failed"


if __name__ == "__main__":
    test_connection()
