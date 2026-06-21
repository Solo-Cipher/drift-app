#!/usr/bin/env python3
"""
Production-ready web server for Flutter web app.
Serves static files with proper MIME types and SPA fallback.
"""
import http.server
import os
import sys
import signal
import mimetypes
from pathlib import Path

# Ensure proper MIME types for Flutter web
mimetypes.add_type('application/javascript', '.js')
mimetypes.add_type('application/wasm', '.wasm')
mimetypes.add_type('application/octet-stream', '.bin')
mimetypes.add_type('text/css', '.css')
mimetypes.add_type('image/svg+xml', '.svg')
mimetypes.add_type('font/woff2', '.woff2')
mimetypes.add_type('font/woff', '.woff')
mimetypes.add_type('font/ttf', '.ttf')

WEB_ROOT = Path(__file__).parent / 'build' / 'web'
PORT = 3003

class FlutterHTTPRequestHandler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=str(WEB_ROOT), **kwargs)

    def do_GET(self):
        # SPA routing: if path doesn't exist as a file, serve index.html
        requested = WEB_ROOT / self.path.lstrip('/')
        if not requested.is_file() and not self.path.startswith('/assets') and not self.path.startswith('/canvaskit'):
            self.path = '/index.html'
        super().do_GET()

    def log_message(self, format, *args):
        # Quieter logging
        pass

def main():
    server = http.server.HTTPServer(('0.0.0.0', PORT), FlutterHTTPRequestHandler)
    print(f'DRIFT server running on http://0.0.0.0:{PORT}', flush=True)
    print(f'Serving from: {WEB_ROOT}', flush=True)

    def shutdown(signum, frame):
        print('\nShutting down server...', flush=True)
        server.shutdown()

    signal.signal(signal.SIGTERM, shutdown)
    signal.signal(signal.SIGINT, shutdown)

    server.serve_forever()

if __name__ == '__main__':
    main()
