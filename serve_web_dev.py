#!/usr/bin/env python3
"""Static server for build/web with SPA fallback (dev-only, port 43305)."""
import functools
import http.server
import os

ROOT = os.path.join(os.path.dirname(__file__), "build", "web")


class SpaHandler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=ROOT, **kwargs)

    def send_head(self):
        path = self.translate_path(self.path)
        if not os.path.exists(path) and not self.path.startswith("/assets"):
            self.path = "/index.html"
        return super().send_head()


if __name__ == "__main__":
    server = http.server.ThreadingHTTPServer(
        ("127.0.0.1", 43305), SpaHandler
    )
    server.serve_forever()
