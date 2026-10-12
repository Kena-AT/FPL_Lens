import io
import json
import logging

from fpl_lens.logging import JsonFormatter, RedactionFilter, redact_text


def test_redact_text_primitives():
    # Email
    s1 = "Failed login for test.user@example.com from IP 1.2.3.4"
    r1 = redact_text(s1)
    assert "test.user@example.com" not in r1
    assert "[REDACTED_EMAIL]" in r1

    # 6-digit code
    s2 = "Verification code generated: 482910 for session"
    r2 = redact_text(s2)
    assert "482910" not in r2
    assert "[REDACTED_CODE]" in r2

    # JWT Token
    jwt = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIn0.SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c"
    s3 = f"Authorization header received: Bearer {jwt}"
    r3 = redact_text(s3)
    assert jwt not in r3
    assert "[REDACTED" in r3

    # Password
    s4 = 'Login payload: {"email": "user@test.com", "password": "SuperSecretPassword123!"}'
    r4 = redact_text(s4)
    assert "SuperSecretPassword123!" not in r4
    assert "[REDACTED]" in r4


def test_log_stream_redaction():
    stream = io.StringIO()
    handler = logging.StreamHandler(stream)
    handler.setFormatter(JsonFormatter())
    handler.addFilter(RedactionFilter())

    test_logger = logging.getLogger("test_redaction_logger")
    test_logger.setLevel(logging.INFO)
    test_logger.addHandler(handler)
    test_logger.propagate = False

    # Emit log message with sensitive details
    test_email = "sensitive_owner@premierleague.com"
    test_code = "772819"
    test_token = "O8Ps2PD6LuNmRpjnbBY_w3ht43C3yEJk4CJV7x6CwGrqJk"

    test_logger.warning("Authentication failed for email=%s with code=%s and token=%s", test_email, test_code, test_token)
    handler.flush()

    log_output = stream.getvalue()

    # Assert that sensitive data was stripped from the log line
    assert test_email not in log_output
    assert test_code not in log_output
    assert test_token not in log_output

    # Parse JSON structured output
    parsed = json.loads(log_output)
    assert "[REDACTED_EMAIL]" in parsed["message"]
    assert "[REDACTED" in parsed["message"]
