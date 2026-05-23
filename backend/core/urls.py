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
from django.http import Http404, HttpResponseRedirect, HttpResponse
import requests

def serve_media_with_fallback(request, path, document_root=None, **kwargs):
    try:
        # Try serving the file from the local disk first
        return serve(request, path, document_root=document_root, **kwargs)
    except Http404:
        # Fall back to the live production server if it doesn't exist locally.
        # To avoid CORS issues on Flutter Web (Chrome), we proxy the bytes on the backend
        # and attach CORS headers, rather than issuing a browser-level HTTP redirect.
        url = f"https://thebaronclub.com/storage/{path}"
        try:
            response = requests.get(url, timeout=15)
            if response.status_code == 200:
                django_response = HttpResponse(
                    response.content, 
                    content_type=response.headers.get('Content-Type', 'image/jpeg')
                )
                django_response["Access-Control-Allow-Origin"] = "*"
                return django_response
        except Exception as e:
            print(f"DEBUG serve_media_with_fallback PROXY ERROR: {e}")
        
        # Fallback to redirect if proxying fails
        return HttpResponseRedirect(url)

urlpatterns = [
    path('api/', include('app_api.urls')),
    re_path(r'^storage/(?P<path>.*)$', serve_media_with_fallback, {'document_root': settings.MEDIA_ROOT}),
]
