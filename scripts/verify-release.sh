#!/bin/sh
set -eu
BASE_URL=${BASE_URL:-http://127.0.0.1:18082}
python3 - "$BASE_URL" <<'PY'
import json, sys, urllib.error, urllib.request
base = sys.argv[1]
for route, validator in [
    ('/health', lambda data: data.get('status') == 'ok'),
    ('/notes', lambda data: isinstance(data.get('notes'), list)),
]:
    try:
        with urllib.request.urlopen(base + route, timeout=4) as resp:
            body = resp.read().decode()
            status = resp.status
    except urllib.error.HTTPError as exc:
        body = exc.read().decode()
        status = exc.code
    except Exception as exc:
        raise SystemExit(f"FAIL: unreachable endpoint {base}{route}: {exc}")

    if status != 200:
        raise SystemExit(f"FAIL: {route} expected 200, got {status}: {body}")
    try:
        data = json.loads(body)
    except json.JSONDecodeError as exc:
        raise SystemExit(f"FAIL: {route} returned invalid JSON: {exc}")
    if not validator(data):
        raise SystemExit(f"FAIL: {route} payload did not match expectations: {body}")
print('Release checks passed')
PY
