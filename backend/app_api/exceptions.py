import logging
from rest_framework.views import exception_handler
from rest_framework.response import Response
from rest_framework import status

logger = logging.getLogger(__name__)

def custom_exception_handler(exc, context):
    """
    Custom DRF exception handler to ensure no raw python tracebacks or technical
    error messages leak to end-users. Returns formal JSON error responses.
    """
    response = exception_handler(exc, context)

    if response is not None:
        if isinstance(response.data, dict):
            # Sanitize technical error strings in dicts
            if 'error' in response.data and isinstance(response.data['error'], str):
                err_str = response.data['error']
                if any(tech in err_str for tech in ['OperationalError', 'ProgrammingError', 'DatabaseError', '[Errno', 'Traceback', 'Exception']):
                    response.data['error'] = 'An unexpected error occurred on the server. Please try again later.'
            elif 'detail' in response.data and isinstance(response.data['detail'], str):
                detail_str = response.data['detail']
                if any(tech in detail_str for tech in ['OperationalError', 'ProgrammingError', 'DatabaseError', '[Errno', 'Traceback', 'Exception']):
                    response.data['detail'] = 'An unexpected error occurred on the server. Please try again later.'
        return response

    # Handle unhandled Python exceptions (e.g. AttributeError, KeyError, TypeError, DatabaseError)
    logger.exception("Unhandled server exception: %s", exc)
    return Response(
        {'error': 'An unexpected server error occurred. Please try again later.'},
        status=status.HTTP_500_INTERNAL_SERVER_ERROR
    )
