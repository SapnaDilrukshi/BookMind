from datetime import datetime

ALLOWED_STATUSES = {"to_read", "reading", "finished", "later"}

def now_utc():
    return datetime.utcnow()

def safe_str(v):
    if v is None:
        return ""
    return str(v).strip()

def safe_list_str(v):
    if not v:
        return []
    if isinstance(v, list):
        return [safe_str(x) for x in v if safe_str(x)]
    # if client sends "a,b,c"
    if isinstance(v, str):
        return [x.strip() for x in v.split(",") if x.strip()]
    return []

def safe_int(v, default=None):
    try:
        return int(v)
    except Exception:
        return default

def normalize_status(s):
    s = safe_str(s).lower()
    return s if s in ALLOWED_STATUSES else None

def clamp_progress(p):
    p = safe_int(p, 0)
    if p < 0: return 0
    if p > 100: return 100
    return p
