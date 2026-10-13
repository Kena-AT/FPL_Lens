import uuid
from datetime import UTC, datetime, timedelta

from fastapi import APIRouter, Depends, Request, Response, status
from sqlalchemy import func, select
from sqlalchemy.orm import Session

from fpl_lens.api.deps import get_client_ip, get_current_user
from fpl_lens.api.errors import AppError
from fpl_lens.api.schemas.auth import (
    ForgotPasswordRequest,
    GoogleAuthRequest,
    LoginRequest,
    RefreshRequest,
    RegisterRequest,
    ResetPasswordRequest,
    TokenResponse,
    VerifyEmailRequest,
)
from fpl_lens.db.models import AuthIdentity, EmailCode, User
from fpl_lens.db.session import get_db
from fpl_lens.logging import logger
from fpl_lens.services.audit import record_audit_event
from fpl_lens.services.fpl_stub import check_fpl_team_exists
from fpl_lens.services.google_auth import verify_google_id_token
from fpl_lens.services.hasher import hash_password, verify_password
from fpl_lens.services.mailer import (
    send_lockout_notification,
    send_password_reset_email,
    send_verification_email,
)
from fpl_lens.services.pwned import is_password_breached
from fpl_lens.services.token import (
    create_access_token,
    create_and_store_email_code,
    issue_refresh_token,
    revoke_all_user_tokens,
    rotate_refresh_token,
    verify_email_code,
)

router = APIRouter(prefix="/auth", tags=["Authentication"])


@router.post("/register", status_code=status.HTTP_201_CREATED)
async def register(
    payload: RegisterRequest,
    request: Request,
    response: Response,
    db: Session = Depends(get_db),
):
    """
    Registers a new user account with email, password, display name, and FPL team ID.
    Enforces password breach check, team ID validity, and one account per team ID.
    Returns the same response for existing emails to limit user enumeration.
    """
    response.headers["Cache-Control"] = "no-store"
    client_ip = get_client_ip(request)

    # 1. Breached password check
    if await is_password_breached(payload.password):
        raise AppError(
            code="PASSWORD_BREACHED",
            message="This password has appeared in a known data breach. Please choose a different password.",
            status_code=status.HTTP_400_BAD_REQUEST,
        )

    # 2. FPL proxy team ID check (Sprint 4 dependency stub)
    team_exists = await check_fpl_team_exists(payload.fpl_team_id)
    if not team_exists:
        raise AppError(
            code="FPL_TEAM_NOT_FOUND",
            message="FPL team ID not found or invalid",
            status_code=status.HTTP_404_NOT_FOUND,
        )

    # 3. One account per FPL team ID rule
    team_stmt = select(User).where(User.fpl_team_id == payload.fpl_team_id)
    if db.execute(team_stmt).scalar_one_or_none():
        raise AppError(
            code="FPL_TEAM_ALREADY_REGISTERED",
            message="This FPL team ID is already registered to an account",
            status_code=status.HTTP_409_CONFLICT,
        )

    # 4. Limit user enumeration: return identical response if email exists
    email_stmt = select(User).where(User.email == payload.email)
    existing_user = db.execute(email_stmt).scalar_one_or_none()
    if existing_user:
        logger.info("Registration attempt for already registered email.")
        return {"message": "Registration successful. Please check your email for the verification code."}

    # 5. Create unverified account
    user_id = uuid.uuid4()
    new_user = User(
        id=user_id,
        email=payload.email,
        email_verified_at=None,
        password_hash=hash_password(payload.password),
        display_name=payload.display_name,
        fpl_team_id=payload.fpl_team_id,
        status="unverified",
        failed_login_count=0,
    )
    db.add(new_user)
    db.flush()

    auth_id = AuthIdentity(
        user_id=user_id,
        provider="email",
        provider_subject=payload.email,
    )
    db.add(auth_id)
    db.commit()

    # 6. Generate 6-digit code and dispatch email
    code = create_and_store_email_code(db, user_id=user_id, purpose="verify_email", expiry_minutes=10)
    await send_verification_email(new_user.email, code, expiry_minutes=10)

    # 7. Record audit event
    record_audit_event(
        db=db,
        action="registration",
        actor_id=str(user_id),
        target_id=str(user_id),
        ip=client_ip,
    )

    return {"message": "Registration successful. Please check your email for the verification code."}


@router.post("/verify-email", response_model=TokenResponse)
async def verify_email(
    payload: VerifyEmailRequest,
    response: Response,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """
    Submits a 6-digit verification code.
    On success, marks email verified, activates user, and returns tokens.
    """
    response.headers["Cache-Control"] = "no-store"

    if current_user.status == "active" and current_user.email_verified_at:
        # Already verified, issue fresh tokens
        access_token = create_access_token(current_user)
        raw_refresh, _ = issue_refresh_token(db, current_user.id)
        return TokenResponse(
            access_token=access_token,
            refresh_token=raw_refresh,
            token_type="Bearer",
            expires_in=900,
        )

    # Verify 6-digit code (checks 10m expiry, max 5 attempts)
    valid = verify_email_code(db, current_user.id, payload.code, purpose="verify_email")
    if not valid:
        raise AppError(
            code="INVALID_VERIFICATION_CODE",
            message="Invalid or expired verification code",
            status_code=status.HTTP_400_BAD_REQUEST,
        )

    current_user.status = "active"
    current_user.email_verified_at = datetime.now(UTC)
    db.commit()

    # Issue tokens
    access_token = create_access_token(current_user)
    raw_refresh, _ = issue_refresh_token(db, current_user.id)

    record_audit_event(
        db=db,
        action="verify_email",
        actor_id=str(current_user.id),
        target_id=str(current_user.id),
    )

    return TokenResponse(
        access_token=access_token,
        refresh_token=raw_refresh,
        token_type="Bearer",
        expires_in=900,
    )


@router.post("/verify-email/resend")
async def resend_verification_email(
    response: Response,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """
    Resends a verification code. Rate limited to 1 per minute and 5 per hour.
    """
    response.headers["Cache-Control"] = "no-store"

    if current_user.status == "active" and current_user.email_verified_at:
        return {"message": "Email is already verified."}

    now = datetime.now(UTC)
    one_min_ago = now - timedelta(minutes=1)
    one_hour_ago = now - timedelta(hours=1)

    # Check 1 per minute
    recent_stmt = (
        select(EmailCode)
        .where(
            EmailCode.user_id == current_user.id,
            EmailCode.purpose == "verify_email",
            EmailCode.created_at >= one_min_ago,
        )
    )
    if db.execute(recent_stmt).first():
        raise AppError(
            code="RATE_LIMITED",
            message="Please wait at least 1 minute before requesting a new code",
            status_code=status.HTTP_429_TOO_MANY_REQUESTS,
        )

    # Check 5 per hour
    count_stmt = (
        select(func.count(EmailCode.id))
        .where(
            EmailCode.user_id == current_user.id,
            EmailCode.purpose == "verify_email",
            EmailCode.created_at >= one_hour_ago,
        )
    )
    hour_count = db.execute(count_stmt).scalar() or 0
    if hour_count >= 5:
        raise AppError(
            code="RATE_LIMITED",
            message="Maximum verification requests reached for this hour (5)",
            status_code=status.HTTP_429_TOO_MANY_REQUESTS,
        )

    code = create_and_store_email_code(db, current_user.id, "verify_email", expiry_minutes=10)
    await send_verification_email(current_user.email, code, expiry_minutes=10)

    return {"message": "A new verification code has been sent."}


@router.post("/login", response_model=TokenResponse)
async def login(
    payload: LoginRequest,
    request: Request,
    response: Response,
    db: Session = Depends(get_db),
):
    """
    Email and password login.
    Enforces 10-attempt failed login lockout for 15 minutes.
    """
    response.headers["Cache-Control"] = "no-store"
    client_ip = get_client_ip(request)

    stmt = select(User).where(User.email == payload.email)
    user = db.execute(stmt).scalar_one_or_none()

    if not user:
        record_audit_event(
            db=db,
            action="login_failure",
            actor_type="anonymous",
            ip=client_ip,
        )
        raise AppError(
            code="INVALID_CREDENTIALS",
            message="Invalid email or password",
            status_code=status.HTTP_401_UNAUTHORIZED,
        )

    # Check lockout
    now = datetime.now(UTC)
    if user.locked_until and user.locked_until > now:
        raise AppError(
            code="ACCOUNT_LOCKED",
            message="Account is locked due to too many failed attempts. Try again later.",
            status_code=status.HTTP_403_FORBIDDEN,
        )

    # Check password
    if not verify_password(payload.password, user.password_hash):
        user.failed_login_count += 1
        if user.failed_login_count >= 10:
            user.locked_until = now + timedelta(minutes=15)
            db.commit()
            record_audit_event(
                db=db,
                action="lockout",
                actor_id=str(user.id),
                target_id=str(user.id),
                ip=client_ip,
            )
            await send_lockout_notification(user.email, lockout_minutes=15)
            raise AppError(
                code="ACCOUNT_LOCKED",
                message="Account locked for 15 minutes due to 10 failed login attempts.",
                status_code=status.HTTP_403_FORBIDDEN,
            )
        db.commit()
        record_audit_event(
            db=db,
            action="login_failure",
            actor_id=str(user.id),
            target_id=str(user.id),
            ip=client_ip,
        )
        raise AppError(
            code="INVALID_CREDENTIALS",
            message="Invalid email or password",
            status_code=status.HTTP_401_UNAUTHORIZED,
        )

    # Successful login: reset failed counters
    user.failed_login_count = 0
    user.locked_until = None
    db.commit()

    record_audit_event(
        db=db,
        action="login_success",
        actor_id=str(user.id),
        target_id=str(user.id),
        ip=client_ip,
    )

    access_token = create_access_token(user)
    raw_refresh, _ = issue_refresh_token(db, user.id)

    return TokenResponse(
        access_token=access_token,
        refresh_token=raw_refresh,
        token_type="Bearer",
        expires_in=900,
    )


@router.post("/google", response_model=TokenResponse)
async def google_auth(
    payload: GoogleAuthRequest,
    request: Request,
    response: Response,
    db: Session = Depends(get_db),
):
    """
    Google sign-in via ID token.
    New Google accounts require an FPL team ID.
    Pre-existing email accounts require password login first to link.
    """
    response.headers["Cache-Control"] = "no-store"
    client_ip = get_client_ip(request)

    try:
        claims = verify_google_id_token(payload.id_token)
    except Exception as exc:
        raise AppError(
            code="INVALID_GOOGLE_TOKEN",
            message=f"Google authentication failed: {exc}",
            status_code=status.HTTP_401_UNAUTHORIZED,
        ) from exc

    google_sub = claims.get("sub")
    google_email = (claims.get("email") or "").lower()
    google_name = claims.get("name") or "Google User"

    # Check if Google identity already linked
    stmt = (
        select(AuthIdentity)
        .where(
            AuthIdentity.provider == "google",
            AuthIdentity.provider_subject == google_sub,
        )
    )
    auth_identity = db.execute(stmt).scalar_one_or_none()

    if auth_identity:
        user_stmt = select(User).where(User.id == auth_identity.user_id)
        user = db.execute(user_stmt).scalar_one_or_none()
        if not user or user.status == "pending_deletion":
            raise AppError(
                code="UNAUTHENTICATED",
                message="Account not found or deleted",
                status_code=status.HTTP_401_UNAUTHORIZED,
            )
        record_audit_event(
            db=db,
            action="login_success",
            actor_id=str(user.id),
            target_id=str(user.id),
            ip=client_ip,
            metadata={"provider": "google"},
        )
        access_token = create_access_token(user)
        raw_refresh, _ = issue_refresh_token(db, user.id)
        return TokenResponse(
            access_token=access_token,
            refresh_token=raw_refresh,
            token_type="Bearer",
            expires_in=900,
        )

    # New Google identity: check if email exists with password provider
    if google_email:
        existing_email_stmt = select(User).where(User.email == google_email)
        existing_user = db.execute(existing_email_stmt).scalar_one_or_none()
        if existing_user:
            raise AppError(
                code="EMAIL_EXISTS_USE_PASSWORD",
                message="An account with this email already exists. Please log in with password first.",
                status_code=status.HTTP_409_CONFLICT,
            )

    # New account: requires FPL team ID
    if not payload.fpl_team_id:
        raise AppError(
            code="MISSING_FPL_TEAM_ID",
            message="New Google accounts must provide an FPL team ID",
            status_code=status.HTTP_400_BAD_REQUEST,
        )

    team_exists = await check_fpl_team_exists(payload.fpl_team_id)
    if not team_exists:
        raise AppError(
            code="FPL_TEAM_NOT_FOUND",
            message="FPL team ID not found or invalid",
            status_code=status.HTTP_404_NOT_FOUND,
        )

    team_stmt = select(User).where(User.fpl_team_id == payload.fpl_team_id)
    if db.execute(team_stmt).scalar_one_or_none():
        raise AppError(
            code="FPL_TEAM_ALREADY_REGISTERED",
            message="This FPL team ID is already registered to an account",
            status_code=status.HTTP_409_CONFLICT,
        )

    user_id = uuid.uuid4()
    new_user = User(
        id=user_id,
        email=google_email or None,
        email_verified_at=datetime.now(UTC),  # Google accounts are pre-verified
        password_hash=None,
        display_name=google_name,
        fpl_team_id=payload.fpl_team_id,
        status="active",
        failed_login_count=0,
    )
    db.add(new_user)
    db.flush()

    new_identity = AuthIdentity(
        user_id=user_id,
        provider="google",
        provider_subject=google_sub,
    )
    db.add(new_identity)
    db.commit()

    record_audit_event(
        db=db,
        action="registration",
        actor_id=str(user_id),
        target_id=str(user_id),
        ip=client_ip,
        metadata={"provider": "google"},
    )

    access_token = create_access_token(new_user)
    raw_refresh, _ = issue_refresh_token(db, user_id)

    return TokenResponse(
        access_token=access_token,
        refresh_token=raw_refresh,
        token_type="Bearer",
        expires_in=900,
    )


@router.post("/refresh", response_model=TokenResponse)
async def refresh_tokens(
    payload: RefreshRequest,
    request: Request,
    response: Response,
    db: Session = Depends(get_db),
):
    """
    Rotates a refresh token and issues a new access token.
    On reuse detection, immediately revokes the whole family.
    """
    response.headers["Cache-Control"] = "no-store"
    client_ip = get_client_ip(request)

    try:
        new_raw_token, _, user_id = rotate_refresh_token(db, payload.refresh_token)
    except ValueError as exc:
        # Check if reuse detection triggered
        if "reuse detected" in str(exc).lower():
            record_audit_event(
                db=db,
                action="reuse_detection",
                ip=client_ip,
            )
        raise AppError(
            code="UNAUTHENTICATED",
            message=str(exc),
            status_code=status.HTTP_401_UNAUTHORIZED,
        ) from exc

    user = db.execute(select(User).where(User.id == user_id)).scalar_one_or_none()
    if not user or user.status == "pending_deletion":
        raise AppError(
            code="UNAUTHENTICATED",
            message="User account not found or deleted",
            status_code=status.HTTP_401_UNAUTHORIZED,
        )

    access_token = create_access_token(user)

    return TokenResponse(
        access_token=access_token,
        refresh_token=new_raw_token,
        token_type="Bearer",
        expires_in=900,
    )


@router.post("/logout")
async def logout(
    response: Response,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Revokes all refresh tokens for the authenticated user."""
    response.headers["Cache-Control"] = "no-store"
    revoke_all_user_tokens(db, current_user.id)
    record_audit_event(
        db=db,
        action="logout",
        actor_id=str(current_user.id),
        target_id=str(current_user.id),
    )
    return {"message": "Logged out successfully"}


@router.post("/password/forgot")
async def forgot_password(
    payload: ForgotPasswordRequest,
    response: Response,
    db: Session = Depends(get_db),
):
    """
    Generates a password reset code and emails it.
    Returns the same response regardless of whether the email is registered to limit enumeration.
    """
    response.headers["Cache-Control"] = "no-store"

    stmt = select(User).where(User.email == payload.email)
    user = db.execute(stmt).scalar_one_or_none()

    if user and user.status != "pending_deletion":
        code = create_and_store_email_code(db, user.id, "reset_password", expiry_minutes=30)
        await send_password_reset_email(user.email, code, expiry_minutes=30)

    return {"message": "If the email is registered, password reset instructions have been sent."}


@router.post("/password/reset")
async def reset_password(
    payload: ResetPasswordRequest,
    response: Response,
    db: Session = Depends(get_db),
):
    """
    Consumes a reset code, updates password with Argon2id, and revokes all refresh token families.
    """
    response.headers["Cache-Control"] = "no-store"

    if await is_password_breached(payload.new_password):
        raise AppError(
            code="PASSWORD_BREACHED",
            message="This password has appeared in a known data breach. Please choose a different password.",
            status_code=status.HTTP_400_BAD_REQUEST,
        )

    stmt = select(User).where(User.email == payload.email)
    user = db.execute(stmt).scalar_one_or_none()

    if not user:
        raise AppError(
            code="INVALID_RESET_CODE",
            message="Invalid or expired password reset code",
            status_code=status.HTTP_400_BAD_REQUEST,
        )

    valid = verify_email_code(db, user.id, payload.code, purpose="reset_password")
    if not valid:
        raise AppError(
            code="INVALID_RESET_CODE",
            message="Invalid or expired password reset code",
            status_code=status.HTTP_400_BAD_REQUEST,
        )

    # Update password & revoke all sessions
    user.password_hash = hash_password(payload.new_password)
    user.failed_login_count = 0
    user.locked_until = None
    revoke_all_user_tokens(db, user.id)
    db.commit()

    record_audit_event(
        db=db,
        action="password_reset",
        actor_id=str(user.id),
        target_id=str(user.id),
    )

    return {"message": "Password reset successfully. Please log in with your new password."}
