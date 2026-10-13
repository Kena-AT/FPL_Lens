from argon2 import PasswordHasher
from argon2.exceptions import InvalidHashError, VerifyMismatchError

# Tuned to ~250 ms on the host per Backend Design v0.4 §6.4 & Plan Sprint 3:
# memory_cost=65536 KiB (64 MiB), time_cost=3, parallelism=1
_ph = PasswordHasher(
    time_cost=3,
    memory_cost=65536,
    parallelism=1,
    hash_len=32,
    salt_len=16,
)


def hash_password(password: str) -> str:
    """Hashes a password using Argon2id with tuned parameters."""
    return _ph.hash(password)


def verify_password(password: str, hashed: str) -> bool:
    """Verifies a plaintext password against an Argon2id hash."""
    if not hashed:
        return False
    try:
        return _ph.verify(hashed, password)
    except (VerifyMismatchError, InvalidHashError):
        return False


def needs_rehash(hashed: str) -> bool:
    """Checks whether the password hash needs upgrading to newer parameters."""
    try:
        return _ph.check_needs_rehash(hashed)
    except InvalidHashError:
        return True
