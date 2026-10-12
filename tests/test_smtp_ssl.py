import os
import smtplib
import ssl
import pytest
from dotenv import load_dotenv


def test_smtp_ssl():
    load_dotenv()

    host = os.getenv("SMTP_HOST")
    user = os.getenv("SMTP_USERNAME")
    password = os.getenv("SMTP_PASSWORD")

    if not (host and user and password):
        pytest.skip("SMTP credentials not provided in environment")

    context = ssl.create_default_context()
    with smtplib.SMTP_SSL(host, 465, context=context, timeout=10) as server:
        code, _ = server.login(user, password)
        assert code == 235, f"Expected 235, got {code}"


if __name__ == "__main__":
    test_smtp_ssl()
