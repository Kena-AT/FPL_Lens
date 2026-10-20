import asyncio
import smtplib
import ssl
from email.message import EmailMessage

from fpl_lens.config import settings
from fpl_lens.logging import logger


def _send_smtp_message(msg: EmailMessage) -> None:
    """Synchronous SMTP delivery supporting both port 465 (SSL) and port 587 (STARTTLS)."""
    host = settings.SMTP_HOST
    port = settings.SMTP_PORT
    username = settings.SMTP_USERNAME
    password = settings.get_effective_smtp_password()

    if not username or not password:
        logger.warning("SMTP credentials not configured; skipping email dispatch.")
        return

    context = ssl.create_default_context()

    if port == 465:
        with smtplib.SMTP_SSL(host, port, context=context, timeout=10) as server:
            server.login(username, password)
            server.send_message(msg)
    else:
        with smtplib.SMTP(host, port, timeout=10) as server:
            server.starttls(context=context)
            server.login(username, password)
            server.send_message(msg)


async def send_verification_email(to_email: str, code: str, expiry_minutes: int = 10) -> None:
    """Sends a 6-digit email verification code."""
    if settings.is_dev:
        # Also print directly to stdout so developer can see it instantly without redaction
        print(
            f"\n{'=' * 60}\n>>> [DEV MODE] Verification code for {to_email}: {code} <<<\n{'=' * 60}\n",
            flush=True,
        )
        logger.info("=" * 60)
        logger.info(
            "[DEV MODE] Verification code for %s: %s (expires in %d min)",
            to_email,
            code,
            expiry_minutes,
        )
        logger.info("=" * 60)

    msg = EmailMessage()
    msg["Subject"] = "Your FPL Lens Verification Code"
    msg["From"] = settings.get_effective_email_from_address()
    msg["To"] = to_email

    # Spec §12.5: Email body contains only the code and expiry. No sensitive squad data.
    msg.set_content(
        f"Your FPL Lens verification code is: {code}\n\n"
        f"This code will expire in {expiry_minutes} minutes.\n"
        "If you did not request this, you can safely ignore this email."
    )

    try:
        await asyncio.to_thread(_send_smtp_message, msg)
        logger.info("Verification email sent successfully to %s", to_email)
    except (smtplib.SMTPException, OSError) as exc:
        logger.error("Failed to send verification email to %s: %s", to_email, type(exc).__name__)
        if settings.is_prod:
            raise


async def send_password_reset_email(to_email: str, code: str, expiry_minutes: int = 30) -> None:
    """Sends a password reset code."""
    if settings.is_dev:
        print(
            f"\n{'=' * 60}\n>>> [DEV MODE] Password reset code for {to_email}: {code} <<<\n{'=' * 60}\n",
            flush=True,
        )
        logger.info("=" * 60)
        logger.info(
            "[DEV MODE] Password reset code for %s: %s (expires in %d min)",
            to_email,
            code,
            expiry_minutes,
        )
        logger.info("=" * 60)

    msg = EmailMessage()
    msg["Subject"] = "FPL Lens Password Reset Code"
    msg["From"] = settings.get_effective_email_from_address()
    msg["To"] = to_email

    msg.set_content(
        f"Your FPL Lens password reset code is: {code}\n\n"
        f"This code will expire in {expiry_minutes} minutes.\n"
        "If you did not request this password reset, please secure your account."
    )

    try:
        await asyncio.to_thread(_send_smtp_message, msg)
        logger.info("Password reset email sent successfully to %s", to_email)
    except (smtplib.SMTPException, OSError) as exc:
        logger.error("Failed to send password reset email to %s: %s", to_email, type(exc).__name__)
        if settings.is_prod:
            raise


async def send_lockout_notification(to_email: str, lockout_minutes: int = 15) -> None:
    """Sends a security alert notification when account is locked after failed logins."""
    msg = EmailMessage()
    msg["Subject"] = "FPL Lens Security Alert: Account Temporarily Locked"
    msg["From"] = settings.EMAIL_FROM_ADDRESS
    msg["To"] = to_email

    msg.set_content(
        f"Your FPL Lens account has been temporarily locked for {lockout_minutes} minutes "
        "due to 10 consecutive failed login attempts.\n\n"
        "If this was not you, someone may be trying to access your account."
    )

    try:
        await asyncio.to_thread(_send_smtp_message, msg)
        logger.info("Lockout alert email sent successfully to %s", to_email)
    except (smtplib.SMTPException, OSError) as exc:
        logger.error("Failed to send lockout alert to %s: %s", to_email, type(exc).__name__)
