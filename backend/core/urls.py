"""
URL configuration for core project.

The `urlpatterns` list routes URLs to views. For more information please see:
    https://docs.djangoproject.com/en/6.0/topics/http/urls/
Examples:
Function views
    1. Add an import:  from my_app import views
    2. Add a URL to urlpatterns:  path('', views.home, name='home')
Class-based views
    1. Add an import:  from other_app.views import Home
    2. Add a URL to urlpatterns:  path('', Home.as_view(), name='home')
Including another URLconf
    1. Import the include() function: from django.urls import include, path
    2. Add a URL to urlpatterns:  path('blog/', include('blog.urls'))
"""
from django.urls import path, include, re_path
from django.conf import settings
from django.views.static import serve
from django.http import Http404, HttpResponseRedirect, HttpResponse, JsonResponse
from django.db import connection
from django.core.cache import cache
import requests
import posixpath

def health_check(request):
    db_ok = False
    try:
        with connection.cursor() as cursor:
            cursor.execute("SELECT 1")
            db_ok = cursor.fetchone() is not None
    except Exception:
        db_ok = False

    cache_ok = False
    try:
        cache.set('health_check', 'ok', 10)
        cache_ok = cache.get('health_check') == 'ok'
    except Exception:
        cache_ok = False

    status_code = 200 if (db_ok and cache_ok) else 503
    return JsonResponse({
        'status': 'healthy' if status_code == 200 else 'unhealthy',
        'database': 'connected' if db_ok else 'disconnected',
        'cache': 'working' if cache_ok else 'unavailable',
    }, status=status_code)

def serve_media_with_fallback(request, path, document_root=None, **kwargs):
    # Sanitize path to prevent directory traversal and SSRF
    normalized_path = posixpath.normpath(path).lstrip('/')
    if (
        normalized_path.startswith('..') or 
        '/../' in normalized_path or 
        '\\' in normalized_path or 
        '\x00' in normalized_path
    ):
        raise Http404("Invalid media path")
    path = normalized_path

    try:
        # Try serving the file from the local disk first
        response = serve(request, path, document_root=document_root, **kwargs)
        response["Access-Control-Allow-Origin"] = "*"
        return response
    except Http404:
        # Fall back to the live production server if it doesn't exist locally.
        url = f"https://thebaronclub.com/storage/{path}"
        try:
            # allow_redirects=False is CRITICAL to prevent proxying loops
            response = requests.get(url, timeout=8, allow_redirects=False)
            if response.status_code == 200:
                django_response = HttpResponse(
                    response.content, 
                    content_type=response.headers.get('Content-Type', 'image/jpeg')
                )
                django_response["Access-Control-Allow-Origin"] = "*"
                return django_response
        except Exception as e:
            print(f"DEBUG serve_media_with_fallback PROXY ERROR: {e}")
        
        # If the file is missing on both domains or redirects, return a clean 404
        raise Http404("Media file not found")

urlpatterns = [
    path('health/', health_check, name='health_check'),
    path('api/', include('app_api.urls')),
    re_path(r'^storage/(?P<path>.*)$', serve_media_with_fallback, {'document_root': settings.MEDIA_ROOT}),
    re_path(r'^app-storage/(?P<path>.*)$', serve_media_with_fallback, {'document_root': settings.MEDIA_ROOT}),
]
