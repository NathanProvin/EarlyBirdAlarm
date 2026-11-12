"""Checks the deployed Firestore rules (firestore.rules) on the live project, with two throwaway
anonymous accounts; deletes what it can (a redemption is never deletable: one stays per run, for
a deleted account). Needs two codes made in the console: `ogbetatester` (active) and
`expiredtest` (active, end in the past). Run from the repo root:
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


def fields(**kv):
    return {"fields": {k: {"stringValue": v} for k, v in kv.items()}}


def friends_of(uid, token):  # the inviter's count query
    return call("POST", f"{DB}:runQuery", token, {"structuredQuery": {
        "from": [{"collectionId": "referrals"}],
        "where": {"fieldFilter": {"field": {"fieldPath": "inviterUid"}, "op": "EQUAL", "value": {"stringValue": uid}}}}})[0]


redeem = fields(uid=a, code="ogbetatester")
checks = [  # (what, status, expected)
    ("A writes its own document", call("PATCH", f"{DB}/players/{a}", ta, doc)[0], 200),
    ("A reads its own document", call("GET", f"{DB}/players/{a}", ta)[0], 200),
    ("B reads A's document", call("GET", f"{DB}/players/{a}", tb)[0], 403),
    ("B writes A's document", call("PATCH", f"{DB}/players/{a}", tb, doc)[0], 403),
    ("B deletes A's document", call("DELETE", f"{DB}/players/{a}", tb)[0], 403),
    ("no account reads A's document", call("GET", f"{DB}/players/{a}")[0], 403),
    ("A reads another collection", call("GET", f"{DB}/secrets/x", ta)[0], 403),
    ("A writes another collection", call("PATCH", f"{DB}/secrets/x", ta, doc)[0], 403),
    ("A reads a code", call("GET", f"{DB}/codes/ogbetatester", ta)[0], 200),
    ("no account reads a code", call("GET", f"{DB}/codes/ogbetatester")[0], 403),
    ("A writes a code", call("PATCH", f"{DB}/codes/ogbetatester", ta, doc)[0], 403),
    ("B redeems for A", call("PATCH", f"{DB}/redemptions/{a}_ogbetatester", tb, redeem)[0], 403),
    ("A redeems a code", call("PATCH", f"{DB}/redemptions/{a}_ogbetatester", ta, redeem)[0], 200),
    ("A redeems it again", call("PATCH", f"{DB}/redemptions/{a}_ogbetatester", ta, redeem)[0], 403),
    ("A reads its redemption", call("GET", f"{DB}/redemptions/{a}_ogbetatester", ta)[0], 200),
    ("B reads A's redemption", call("GET", f"{DB}/redemptions/{a}_ogbetatester", tb)[0], 403),
    ("A deletes its redemption", call("DELETE", f"{DB}/redemptions/{a}_ogbetatester", ta)[0], 403),
    ("A redeems an expired code", call("PATCH", f"{DB}/redemptions/{a}_expiredtest", ta, fields(uid=a, code="expiredtest"))[0], 403),
    ("A redeems a missing code", call("PATCH", f"{DB}/redemptions/{a}_nosuchcode", ta, fields(uid=a, code="nosuchcode"))[0], 403),
    ("A invites itself", call("PATCH", f"{DB}/referrals/{a}", ta, fields(inviterUid=a))[0], 403),
    ("A writes B's referral", call("PATCH", f"{DB}/referrals/{b}", ta, fields(inviterUid=a))[0], 403),
    ("B joins through A", call("PATCH", f"{DB}/referrals/{b}", tb, fields(inviterUid=a))[0], 200),
    ("B changes its referral", call("PATCH", f"{DB}/referrals/{b}", tb, fields(inviterUid=b + "x"))[0], 403),
    ("A counts its friends", friends_of(a, ta), 200),
    ("B counts A's friends", friends_of(a, tb), 403),
    ("B deletes its referral", call("DELETE", f"{DB}/referrals/{b}", tb)[0], 200),
    ("A writes its own card chunk", call("PATCH", f"{DB}/players/{a}/cards/0", ta, doc)[0], 200),
    ("A lists its own card chunks", call("GET", f"{DB}/players/{a}/cards", ta)[0], 200),
    ("B reads A's card chunk", call("GET", f"{DB}/players/{a}/cards/0", tb)[0], 403),
    ("B writes A's card chunk", call("PATCH", f"{DB}/players/{a}/cards/1", tb, doc)[0], 403),
    ("B lists A's card chunks", call("GET", f"{DB}/players/{a}/cards", tb)[0], 403),
    ("A deletes its own card chunk", call("DELETE", f"{DB}/players/{a}/cards/0", ta)[0], 200),
    ("A deletes its own document", call("DELETE", f"{DB}/players/{a}", ta)[0], 200),
]
for token in (ta, tb):  # the throwaway accounts go too
    call("POST", f"https://identitytoolkit.googleapis.com/v1/accounts:delete?key={KEY}", body={"idToken": token})
for what, status, expected in checks:
    print(f"{'ok  ' if status == expected else 'FAIL'} {what}: {status} (expected {expected})")
assert all(s == e for _, s, e in checks), "rules check failed"
print("rules ok")
