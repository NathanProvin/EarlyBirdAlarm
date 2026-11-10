"""Checks the deployed Firestore rules (firestore.rules) on the live project, with two throwaway
anonymous accounts; deletes what it creates. Run from the repo root:
    py -I app/firestore_rules_check.py
"""
import json
import urllib.error
import urllib.request
from pathlib import Path

cfg = json.loads((Path(__file__).parent / "android/app/google-services.json").read_text())
KEY = cfg["client"][0]["api_key"][0]["current_key"]
DB = f"https://firestore.googleapis.com/v1/projects/{cfg['project_info']['project_id']}/databases/(default)/documents"


def call(method, url, token=None, body=None):
    req = urllib.request.Request(url, method=method, data=json.dumps(body).encode() if body else None,
                                 headers={"Content-Type": "application/json",
                                          **({"Authorization": f"Bearer {token}"} if token else {})})
    try:
        with urllib.request.urlopen(req) as r:
            return r.status, json.loads(r.read() or b"{}")
    except urllib.error.HTTPError as e:
        return e.code, {}


def anonymous():
    status, j = call("POST", f"https://identitytoolkit.googleapis.com/v1/accounts:signUp?key={KEY}", body={"returnSecureToken": True})
    assert status == 200, f"anonymous sign-up refused ({status}): is Anonymous enabled?"
    return j["localId"], j["idToken"]


(a, ta), (b, tb) = anonymous(), anonymous()
doc = {"fields": {"test": {"booleanValue": True}}}
checks = [  # (what, status, expected)
    ("A writes its own document", call("PATCH", f"{DB}/players/{a}", ta, doc)[0], 200),
    ("A reads its own document", call("GET", f"{DB}/players/{a}", ta)[0], 200),
    ("B reads A's document", call("GET", f"{DB}/players/{a}", tb)[0], 403),
    ("B writes A's document", call("PATCH", f"{DB}/players/{a}", tb, doc)[0], 403),
    ("B deletes A's document", call("DELETE", f"{DB}/players/{a}", tb)[0], 403),
    ("no account reads A's document", call("GET", f"{DB}/players/{a}")[0], 403),
    ("A reads another collection", call("GET", f"{DB}/codes/RedRobin", ta)[0], 403),
    ("A writes another collection", call("PATCH", f"{DB}/codes/RedRobin", ta, doc)[0], 403),
    ("A deletes its own document", call("DELETE", f"{DB}/players/{a}", ta)[0], 200),
]
for token in (ta, tb):  # the throwaway accounts go too
    call("POST", f"https://identitytoolkit.googleapis.com/v1/accounts:delete?key={KEY}", body={"idToken": token})
for what, status, expected in checks:
    print(f"{'ok  ' if status == expected else 'FAIL'} {what}: {status} (expected {expected})")
assert all(s == e for _, s, e in checks), "rules check failed"
print("rules ok")
