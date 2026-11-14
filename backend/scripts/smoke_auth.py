"""Exercise authentication over real HTTP against a local development instance.

Creates one random test account. Never prints passwords or JWTs. Python 3.10+.
"""

import argparse
import json
import uuid
from urllib.error import HTTPError
from urllib.parse import urlparse
from urllib.request import Request, urlopen


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--url", default="http://127.0.0.1:8080")
    base = parser.parse_args().url.rstrip("/")
    parsed = urlparse(base)
    if parsed.scheme != "http" or parsed.hostname not in {"localhost", "127.0.0.1", "::1"} or parsed.username:
        parser.error("Only local HTTP development URLs are allowed.")

    def request(method, path, expected, body=None, token=None):
        headers = {}
        if body is not None:
            headers["Content-Type"] = "application/json"
        if token is not None:
            headers["Authorization"] = f"Bearer {token}"
        req = Request(base + path, data=json.dumps(body).encode() if body is not None else None,
                      headers=headers, method=method)
        try:
            response = urlopen(req, timeout=15)
        except HTTPError as error:
            response = error
        with response:
            status = response.code
            payload = response.read()
            if status != expected:
                raise RuntimeError(f"{method} {path}: expected {expected}, received {status}")
            if response.headers.get("Set-Cookie"):
                raise RuntimeError("Unexpected session cookie")
            print(f"{method} {path}: {status}")
            return json.loads(payload) if "application/json" in response.headers.get("Content-Type", "") else None

    suffix = uuid.uuid4().hex[:12]
    email = f"smoke-{suffix}@example.com"
    password = "LocalSmokePass123!"
    auth = request("POST", "/api/v1/auth/register", 201,
                   {"birthYear": 2000, "birthMonth": 1, "email": f" {email.upper()} ", "nickname": f"Smoke_{suffix}", "password": password})
    profile = request("GET", "/api/v1/users/me", 200, token=auth["accessToken"])
    if profile["email"] != email or not profile["createdAt"].endswith("Z") or "passwordHash" in profile:
        raise RuntimeError("Unexpected profile representation")
    login = request("POST", "/api/v1/auth/login", 200, {"email": email, "password": password})
    request("POST", "/api/v1/auth/login", 401, {"email": email, "password": "WrongPassword123!"})
    request("GET", "/api/v1/users/me", 401, token=auth["refreshToken"])
    request("POST", "/api/v1/auth/refresh", 401, token=auth["accessToken"])
    rotated = request("POST", "/api/v1/auth/refresh", 200, token=auth["refreshToken"])
    request("POST", "/api/v1/auth/refresh", 401, token=auth["refreshToken"])
    request("POST", "/api/v1/auth/logout", 204, token=rotated["refreshToken"])
    request("POST", "/api/v1/auth/refresh", 401, token=rotated["refreshToken"])
    request("GET", "/api/v1/users/me", 200, token=auth["accessToken"])
    other = request("POST", "/api/v1/auth/refresh", 200, token=login["refreshToken"])
    request("POST", "/api/v1/auth/logout", 204, token=other["refreshToken"])
    request("GET", "/swagger-ui.html", 200)  # urllib follows Swagger's redirect.
    spec = request("GET", "/v3/api-docs", 200)
    if not {"accessBearer", "refreshBearer"} <= spec["components"]["securitySchemes"].keys():
        raise RuntimeError("Missing Swagger Bearer schemes")
    print("Authentication HTTP smoke check passed.")


if __name__ == "__main__":
    main()
