unit Curl.HttpCodes;

interface

const
  ///// 1xx — Informational ////////////////////////////////////////////////////

  ///  Server has received the request headers, and that the client should
  ///  proceed to send the request body
  HTTP_CONTINUE = 100;

  ///  This means the requester has asked the server to switch protocols and
  ///  the server is acknowledging that it will do so.
  HTTP_SWITCHING_PROTOCOLS = 101;

  ///  As a WebDAV request may contain many sub-requests involving file
  ///  operations, it may take a long time to complete the request
  HTTP_PROCESSING = 102;

  ///  Problems with server-side DNS resolution
  HTTP_NAME_NOT_RESOLVED = 105;

  ///// 2xx — Success //////////////////////////////////////////////////////////

  ///  Standard response for successful HTTP requests.
  HTTP_OK = 200;

  ///  The request has been fulfilled and resulted in a new resource being
  ///  created.
  HTTP_CREATED = 201;

  ///  The request has been accepted for processing, but the processing has
  ///  not been completed.
  HTTP_ACCEPTED = 202;

  ///  The server successfully processed the request, but is returning
  ///  information that may be from another source.
  HTTP_NOT_AUTHORITATIVE_INFO = 203;

  ///  The server successfully processed the request, but is not returning
  ///  any content. Usually used as a response to a successful delete request.
  HTTP_NO_CONTENT = 204;

  ///  The server successfully processed the request, but is not returning
  ///  any content. Unlike a 204 response, this response requires that the
  ///  requester reset the document view.
  HTTP_RESET_CONTENT = 205;

  ///  The server is delivering only part of the resource due to a range
  ///  header sent by the client.
  HTTP_PARTIAL_CONTENT = 206;

  ///  (WebDAV) The message body that follows is an XML message and can contain
  ///  a number of separate response codes, depending on how many sub-requests
  ///  were made.
  HTTP_MULTI_STATUS = 207;

  ///  (WebDAV) The members of a DAV binding have already been enumerated in a
  ///  previous reply to this request, and are not being included again.
  HTTP_ALREADY_REPORTED = 208;

  ///  The server has fulfilled a request for the resource, and the response
  ///  is a representation of the result of one or more instance-manipulations
  ///  applied to the current instance.
  HTTP_IM_USED = 226;

  ///// 3xx — Redirection //////////////////////////////////////////////////////

  ///  Indicates multiple options for the resource that the client may follow.
  ///  It, for instance, could be used to present different format options for
  ///  video, list files with different extensions, or word sense disambiguation.
  HTTP_MULTIPLE_CHOICES = 300;

  ///  This and all future requests should be directed to the given URI.
  HTTP_MOVED_PERMANENTLY = 301;

  ///  Mostly unused, most servers use 303 and 307 instead.
  HTTP_FOUND = 302;

  ///  The response to the request can be found under another URI using a
  ///  GET method.
  HTTP_SEE_OTHER = 303;

  ///  Indicates that the resource has not been modified since the version
  ///  specified by the request headers If-Modified-Since or If-None-Match.
  HTTP_NOT_MODIFIED = 304;

  ///  The requested resource is only available through a proxy, whose
  ///  address is provided in the response.
  HTTP_USE_PROXY = 305;

  ///  Unused
  HTTP_SWITCH_PROXY = 306;

  ///  (HTTP/1.1) The request should be repeated with another URI; however,
  ///  future requests should still use the original URI.
  HTTP_TEMPORARY_REDIRECT = 307;

  ///  (Experimental) The request, and all future requests should be repeated
  ///  using another URI and the same method.
  HTTP_PERMANENT_REDIRECT = 308;

  ///// 4xx Client error ///////////////////////////////////////////////////////

  ///  The server will not process the request due to something that is
  ///  perceived to be a client error.
  HTTP_BAD_REQUEST = 400;

  ///  Similar to 403 Forbidden, but specifically for use when authentication
  ///  is required and has failed or has not yet been provided.
  HTTP_UNAUTHORIZED = 401;

  ///  Mostly unused. For instance Google uses this code when displays CAPTCHA.
  HTTP_PAYMENT_REQUIRED = 402;

  ///  The request was a valid request, but the server is refusing to respond
  ///  to it. Unlike a 401 Unauthorized response, authenticating will make
  ///  no difference.
  HTTP_FORBIDDEN = 403;

  ///  The requested resource could not be found but may be available again
  ///  in the future. Subsequent requests by the client are permissible.
  HTTP_NOT_FOUND = 404;

  ///  A request was made of a resource using a request method not supported
  ///  by that resource; for example, using GET on a form which requires data
  ///  to be presented via POST, or using PUT on a read-only resource.
  HTTP_METHOD_NOT_ALLOWED = 405;

  ///  The requested resource is only capable of generating content not
  ///  acceptable according to the Accept headers sent in the request.
  HTTP_NOT_ACCEPTABLE = 406;

  ///  The client must first authenticate itself with the proxy.
  HTTP_PROXY_AUTHENTICATION_REQUIRED = 407;

  ///  The server timed out waiting for the request.
  HTTP_REQUEST_TIMEOUT = 408;

  ///  The request could not be processed because of conflict in the request,
  ///  such as an edit conflict in the case of multiple updates.
  HTTP_CONFLICT = 409;

  ///  Indicates that the resource requested is no longer available and
  ///  will not be available again.
  HTTP_GONE = 410;

  ///  The request did not specify the length of its content, which is required
  ///  by the requested resource.
  HTTP_LENGTH_REQUIRED = 411;

  ///  The server does not meet one of the preconditions that the requester
  ///  put on the request.
  HTTP_PRECONDITION_FAILED = 412;

  ///  The request is larger than the server is willing or able to process.
  HTTP_REQUEST_ENTITY_TOO_LARGE = 413;

  ///  The URI provided was too long for the server to process. Often the result
  ///  of too much data being encoded as a query-string of a GET request, in
  ///  which case it should be converted to a POST request.
  HTTP_REQUEST_URI_TOO_LONG = 414;

  ///  The request entity has a media type which the server or resource does
  ///  not support. For example, the client uploads an image as image/svg+xml,
  ///  but the server requires that images use a different format.
  HTTP_UNSUPPORTED_MEDIA_TYPE = 415;

  ///  The client has asked for a portion of the file, but the server cannot
  ///  supply that portion. For example, if the client asked for a part of
  ///  the file that lies beyond the end of the file.
  HTTP_REQUEST_RANGE_NOT_SATISFIABLE = 416;

  ///  The server cannot meet the requirements of the Expect request-header
  ///  field.
  HTTP_EXPECTATION_FAILED = 417;

  ///  Just a joke :)
  HTTP_IM_A_TEAPOT = 418;

  ///  (Experimental) Previously valid authentication has expired.
  HTTP_AUTHENTICATION_TIMEOUT = 419;

  ///  (WebDAV) The request was well-formed but was unable to be followed
  ///  due to semantic errors.
  HTTP_UNPROCESSABLE_ENTITY = 422;

  ///  (WebDAV) The resource that is being accessed is locked.
  HTTP_LOCKED = 423;

  ///  The request failed due to failure of a previous request (e.g.,
  ///  a PROPPATCH).
  HTTP_FAILED_DEPENDENCY = 424;

  ///  The client should switch to a different protocol such as TLS/1.0.
  HTTP_UPGRADE_REQUIRED = 426;

  ///  (WebDAV and likewise) The origin server requires the request to be
  ///  conditional. Intended to prevent "the 'lost update' problem.
  HTTP_PRECONDITION_REQUIRED = 428;

  ///  The user has sent too many requests in a given amount of time.
  HTTP_TOO_MANY_REQUESTS = 429;

  ///  The server is unwilling to process the request because either an
  ///  individual header field, or all the header fields collectively, are
  ///  too large.
  HTTP_REQUEST_HEADER_FIELDS_TOO_LARGE = 431;

  ///  (Experimental) Censorship or government-mandated blocked access.
  HTTP_UNAVAILABLE_FOR_LEGAL_REASONS = 451;

  ///// 5xx — Server error /////////////////////////////////////////////////////

  ///  A generic error message, given when an unexpected condition was
  ///  encountered and no more specific message is suitable.
  HTTP_INTERNAL_SERVER_ERROR = 500;

  ///  The server either does not recognize the request method, or it lacks
  ///  the ability to fulfil the request.
  HTTP_NOT_IMPLEMENTED = 501;

  ///  The server was acting as a gateway or proxy and received an invalid
  ///  response from the upstream server.
  HTTP_BAD_GATEWAY = 502;

  ///  The server is currently unavailable (because it is overloaded or down
  ///  for maintenance). Generally, this is a temporary state.
  HTTP_SERVICE_UNAVAILABLE = 503;

  ///  The server was acting as a gateway or proxy and did not receive a timely
  ///  response from the upstream server.
  HTTP_GATEWAY_TIMEOUT = 504;

  ///  The server does not support the HTTP protocol version used in
  ///  the request.
  HTTP_VERSION_NOT_SUPPORTED = 505;

  ///  Transparent content negotiation for the request results in a circular
  ///  reference.
  HTTP_VARIANT_ALSO_NEGOTIATES = 506;

  ///  (WebDAV) The server is unable to store the representation needed to
  ///  complete the request.
  HTTP_INSUFFICIENT_STORAGE = 507;

  ///  (WebDAV) The server detected an infinite loop while processing
  ///  the request (sent in lieu of 208 Already Reported).
  HTTP_LOOP_DETECTED = 508;

  ///  (Experimental) This error occurs when the server reaches the bandwidth
  ///  limit that the system administrator imposed.
  HTTP_BANDWIDTH_LIMIT_EXCEEDED = 509;

  ///  Further extensions to the request are required for the server to fulfil
  ///  it.
  HTTP_NOT_EXTENDED = 510;

implementation

end.

