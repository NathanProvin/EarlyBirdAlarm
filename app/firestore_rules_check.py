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
# The API key only accepts the Android app (Google Cloud restriction): the script calls as it.
ANDROID = {"X-Android-Package": cfg["client"][0]["client_info"]["android_client_info"]["package_name"],
           "X-Android-Cert": "2E82FA65627814738464095D7E54630403015B86"}  # a SHA-1 registered in Firebase
DB = f"https://firestore.googleapis.com/v1/projects/{cfg['project_info']['project_id']}/databases/(default)/documents"


def call(method, url, token=None, body=None):
    req = urllib.request.Request(url, method=method, data=json.dumps(body).encode() if body else None,
                                 headers={"Content-Type": "application/json", **ANDROID,
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
# Profile page (2026-11-13): names, profiles, friend requests, friends.
na, nb = f"rc{a[:8].lower()}", f"rc{b[:8].lower()}"
def profile(name):
    return {"fields": {"name": {"stringValue": name}, "avatar": {"mapValue": {"fields": {}}},
                       "hall": {"arrayValue": {}}}}
def request(frm, to):
    return {"fields": {"from": {"stringValue": frm}, "to": {"stringValue": to},
                       "at": {"timestampValue": "2026-11-13T00:00:00Z"}}}
empty = {"fields": {}}
lo, hi = sorted([a, b])
tlo, thi = (ta, tb) if lo == a else (tb, ta)
tid = f"{DB}/trades/{lo}_{hi}"
def trade(**over):
    f = {"a": {"stringValue": lo}, "b": {"stringValue": hi},
         "aCards": {"arrayValue": {}}, "bCards": {"arrayValue": {}},
         "aOk": {"nullValue": None}, "bOk": {"nullValue": None},
         "aDone": {"booleanValue": False}, "bDone": {"booleanValue": False},
         "created": {"timestampValue": "2026-11-13T00:00:00Z"}}
    f.update(over)
    return {"fields": f}
card = {"arrayValue": {"values": [{"mapValue": {"fields": {"bird": {"stringValue": "x"}}}}]}}
def put(token, body, *fields):
    mask = "&".join(f"updateMask.fieldPaths={x}" for x in fields)
    return call("PATCH", f"{tid}?{mask}", token, body)[0]
checks += [
    ("A takes a name", call("PATCH", f"{DB}/usernames/{na}", ta, fields(uid=a))[0], 200),
    ("B takes A's name", call("PATCH", f"{DB}/usernames/{na}", tb, fields(uid=b))[0], 403),
    ("B takes a name for A", call("PATCH", f"{DB}/usernames/{nb}x", tb, fields(uid=a))[0], 403),
    ("A takes an invalid name", call("PATCH", f"{DB}/usernames/ab", ta, fields(uid=a))[0], 403),
    ("B takes a name", call("PATCH", f"{DB}/usernames/{nb}", tb, fields(uid=b))[0], 200),
    ("A shows its name", call("PATCH", f"{DB}/profiles/{a}", ta, profile(na.upper()))[0], 200),
    ("A shows B's name", call("PATCH", f"{DB}/profiles/{a}", ta, profile(nb))[0], 403),
    ("B writes A's profile", call("PATCH", f"{DB}/profiles/{a}", tb, profile(nb))[0], 403),
    ("B shows its name", call("PATCH", f"{DB}/profiles/{b}", tb, profile(nb))[0], 200),
    ("B reads A's profile", call("GET", f"{DB}/profiles/{a}", tb)[0], 200),
    ("no account reads A's profile", call("GET", f"{DB}/profiles/{a}")[0], 403),
    ("B frees A's name", call("DELETE", f"{DB}/usernames/{na}", tb)[0], 403),
    ("trade with a stranger", call("PATCH", tid, tlo, trade())[0], 403),
    ("B asks A as A", call("PATCH", f"{DB}/friendRequests/{a}_{b}", tb, request(a, b))[0], 403),
    ("B asks A", call("PATCH", f"{DB}/friendRequests/{a}_{b}", tb, request(b, a))[0], 200),
    ("A reads the request", call("GET", f"{DB}/friendRequests/{a}_{b}", ta)[0], 200),
    ("A lists the requests it got", call("POST", f"{DB}:runQuery", ta, {"structuredQuery": {
        "from": [{"collectionId": "friendRequests"}],
        "where": {"fieldFilter": {"field": {"fieldPath": "to"}, "op": "EQUAL", "value": {"stringValue": a}}}}})[0], 200),
    ("B lists the requests it sent", call("POST", f"{DB}:runQuery", tb, {"structuredQuery": {
        "from": [{"collectionId": "friendRequests"}],
        "where": {"fieldFilter": {"field": {"fieldPath": "from"}, "op": "EQUAL", "value": {"stringValue": b}}}}})[0], 200),
    ("B lists A's requests", call("POST", f"{DB}:runQuery", tb, {"structuredQuery": {
        "from": [{"collectionId": "friendRequests"}],
        "where": {"fieldFilter": {"field": {"fieldPath": "to"}, "op": "EQUAL", "value": {"stringValue": a}}}}})[0], 403),
    ("B befriends A alone", call("PATCH", f"{DB}/friends/{b}/list/{a}", tb, empty)[0], 403),
    ("B adds itself to A", call("PATCH", f"{DB}/friends/{a}/list/{b}", tb, empty)[0], 403),
    ("A accepts: its side", call("PATCH", f"{DB}/friends/{a}/list/{b}", ta, empty)[0], 200),
    ("A accepts: B's side", call("PATCH", f"{DB}/friends/{b}/list/{a}", ta, empty)[0], 200),
    ("A deletes the request", call("DELETE", f"{DB}/friendRequests/{a}_{b}", ta)[0], 200),
    ("B reads its friends", call("GET", f"{DB}/friends/{b}/list", tb)[0], 200),
    ("A reads B's friends", call("GET", f"{DB}/friends/{b}/list", ta)[0], 403),
    ("lo opens a trade", call("PATCH", tid, tlo, trade())[0], 200),
    ("hi offers a card", put(thi, trade(bCards=card), "bCards"), 200),
    ("hi touches lo's offer", put(thi, trade(aCards=card), "aCards"), 403),
    ("lo changes the date", put(tlo, trade(created={"timestampValue": "2020-01-01T00:00:00Z"}), "created"), 403),
    ("lo offers a card", put(tlo, trade(aCards=card), "aCards"), 200),
    ("lo validates", put(tlo, trade(aOk={"stringValue": "h1"}), "aOk"), 200),
    ("hi validates the same", put(thi, trade(bOk={"stringValue": "h1"}), "bOk"), 200),
    ("lo changes its offer after both", put(tlo, trade(aCards={"arrayValue": {}}), "aCards"), 403),
    ("hi cancels a swap in progress", call("DELETE", tid, thi)[0], 403),
    ("lo applied", put(tlo, trade(aDone={"booleanValue": True}), "aDone"), 200),
    ("hi applied", put(thi, trade(bDone={"booleanValue": True}), "bDone"), 200),
    ("hi deletes the finished trade", call("DELETE", tid, thi)[0], 200),
    ("B removes A: A's side", call("DELETE", f"{DB}/friends/{a}/list/{b}", tb)[0], 200),
    ("B removes A: its side", call("DELETE", f"{DB}/friends/{b}/list/{a}", tb)[0], 200),
    ("A deletes its profile", call("DELETE", f"{DB}/profiles/{a}", ta)[0], 200),
    ("A frees its name", call("DELETE", f"{DB}/usernames/{na}", ta)[0], 200),
]
call("DELETE", f"{DB}/profiles/{b}", tb)
call("DELETE", f"{DB}/usernames/{nb}", tb)
for token in (ta, tb):  # the throwaway accounts go too
    call("POST", f"https://identitytoolkit.googleapis.com/v1/accounts:delete?key={KEY}", body={"idToken": token})
for what, status, expected in checks:
    print(f"{'ok  ' if status == expected else 'FAIL'} {what}: {status} (expected {expected})")
assert all(s == e for _, s, e in checks), "rules check failed"
print("rules ok")
