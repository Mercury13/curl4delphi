unit Curl.Lib;

interface

uses
  Winapi.Winsock2;

// In C enum’s are int’s, so let’s set enum size to 4.
{$MINENUMSIZE 4}

const
  CurlBindingVersionMajor = 7;
  CurlBindingVersionMinor = 56;
  CurlBindingVersionPatch = 1;
  CurlBindingVersionHex =
        CurlBindingVersionMajor shl 16 +
        CurlBindingVersionMinor shl 8 +
        CurlBindingVersionPatch;
  CurlBindingVersionString = '7.56.1';

  FirefoxUserAgent = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:53.0) Gecko/20100101 Firefox/53.0';
  MozillaUserAgent = FirefoxUserAgent;
  ChromeUserAgent = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/60.0.3112.113 Safari/537.36';
  IeUserAgent = 'Mozilla/5.0 (Windows NT 10.0; WOW64; Trident/7.0; rv:11.0) like Gecko';
  EdgeUserAgent = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/51.0.2704.79 Safari/537.36 Edge/14.14393';

type
  // Primitive cUrl types
  TUnixTime   = NativeUInt;
  TCurlOff    = int64;
  TCurlSocket = TSocket;

  TCurlInner = record end;
  HCurl = ^TCurlInner;

  // enumeration of file types
  TCurlFileType = (
    CURLFILETYPE_FILE, CURLFILETYPE_DIRECTORY, CURLFILETYPE_SYMLINK,
    CURLFILETYPE_DEVICE_BLOCK, CURLFILETYPE_DEVICE_CHAR,
    CURLFILETYPE_NAMEDPIPE, CURLFILETYPE_SOCKET,
    CURLFILETYPE_DOOR,    // is possible only on Sun Solaris now
    CURLFILETYPE_UNKNOWN  // should never occur
    );

  TCurlIoErr = (
    CURLIOE_OK,            // I/O operation successful
    CURLIOE_UNKNOWNCMD,    // command was unknown to callback
    CURLIOE_FAILRESTART    // failed to restart the read
  );

  TCurlIoCmd = (
    CURLIOCMD_NOP,         // no operation
    CURLIOCMD_RESTARTREAD  // restart the read stream from start
  );


const
  // cUrl constants
  CURL_SOCKET_BAD = High(TCurlSocket);

  CURL_HTTPPOST_FILENAME    = 1 shl 0;   // specified content is a file name
  CURL_HTTPPOST_READFILE    = 1 shl 1;   // specified content is a file name
  CURL_HTTPPOST_PTRNAME     = 1 shl 2;   // name is only stored pointer
                                         //   do not free in formfree
  CURL_HTTPPOST_PTRCONTENTS = 1 shl 3;   // contents is only stored pointer
                                         //   do not free in formfree
  CURL_HTTPPOST_BUFFER      = 1 shl 4;   // upload file from buffer
  CURL_HTTPPOST_PTRBUFFER   = 1 shl 5;   // upload file from pointer contents
  CURL_HTTPPOST_CALLBACK    = 1 shl 6;   // upload file contents by using the
                                         //   regular read callback to get the data
                                         //   and pass the given pointer as custom
                                         //   pointer
  CURL_HTTPPOST_LARGE       = 1 shl 7;   //  use size in 'contentlen',
                                         //   added in 7.46.0

  // The maximum receive buffer size configurable via CURLOPT_BUFFERSIZE.
  CURL_MAX_READ_SIZE = 524288;

  // Tests have proven that 20K is a very bad buffer size for uploads on
  //   Windows, while 16K for some odd reason performed a lot better.
  //   We do the ifndef check to allow this value to easier be changed at build
  //   time for those who feel adventurous. The practical minimum is about
  //   400 bytes since libcurl uses a buffer of this size as a scratch area
  //   (unrelated to network send operations).
  CURL_MAX_WRITE_SIZE = 16384;

  // The only reason to have a max limit for this is to avoid the risk of a bad
  // server feeding libcurl with a never-ending header that will cause reallocs
  // infinitely
  CURL_MAX_HTTP_HEADER = 100*1024;

  // This is a magic return code for the write callback that, when returned,
  // will signal libcurl to pause receiving on the current transfer.
  CURL_WRITEFUNC_PAUSE = $10000001;

type
  // linked-list structure for the CURLOPT_QUOTE option (and other)
  PCurlSList = ^TCurlSList;
  TCurlSList = record
    Data : PAnsiChar;
    Next : PCurlSList;
  end;
  PPCurlSList = ^PCurlSList;

  PCurlHttpPost = ^TCurlHttpPost;
  TCurlHttpPost = record
    Next : PCurlHttpPost;           // next entry in the list
    Name : PAnsiChar;               // pointer to allocated name
    NameLength : Cardinal;          // length of name length
    Contents : PAnsiChar;           // pointer to allocated data contents
    ContentsLength : Cardinal;      // length of contents field
    Buffer : PAnsiChar;             // pointer to allocated buffer contents
    BufferLength : Cardinal;        // length of buffer field
    ContentType : PAnsiChar;        // Content-Type
    ContentHeader : PCurlSList;     // list of extra headers for this form
    More : PCurlHttpPost;           // if one field name has more than one
                                    //   file, this link should link to following
                                    //   files
    Flags : LongWord;               // Flags, HTTPPOST_
    ShowFileName : PAnsiChar;       // The file name to show. If not set, the
                                    //   actual file name will be used (if this
                                    //   is a file part)
    UserP : pointer;                // custom pointer used for
                                    //   HTTPPOST_CALLBACK posts
  end;

  // This is the CURLOPT_XFERINFOFUNCTION callback proto. It was introduced in
  // 7.32.0, it avoids floating point and provides more detailed information.
  EvCurlXferInfo = function (
          ClientP : pointer;
          DlTotal, DlNow, UlTotal, UlNow : TCurlOff) : integer;  cdecl;

  EvCurlWrite = function (
          const Buffer;
          Size, NItems : NativeUInt;
          OutStream : pointer) : NativeUInt;  cdecl;


const
  CURLFINFOFLAG_KNOWN_FILENAME    = 1 shl 0;
  CURLFINFOFLAG_KNOWN_FILETYPE    = 1 shl 1;
  CURLFINFOFLAG_KNOWN_TIME        = 1 shl 2;
  CURLFINFOFLAG_KNOWN_PERM        = 1 shl 3;
  CURLFINFOFLAG_KNOWN_UID         = 1 shl 4;
  CURLFINFOFLAG_KNOWN_GID         = 1 shl 5;
  CURLFINFOFLAG_KNOWN_SIZE        = 1 shl 6;
  CURLFINFOFLAG_KNOWN_HLINKCOUNT  = 1 shl 7;

type
  // Content of this structure depends on information which is known and is
  // achievable (e.g. by FTP LIST parsing). Please see the url_easy_setopt(3) man
  // page for callbacks returning this structure -- some fields are mandatory,
  // some others are optional. The FLAG field has special meaning.
  TCurlFileStrings = record
    Time, Perm, User, Group, Target : PAnsiChar;
  end;

  TCurlFileInfo = record
    FileName : PAnsiChar;
    FileType : TCurlFileType;
    Time : TUnixTime;
    Perm : longword;
    Uid, Gid : integer;
    Size : TCurlOff;
    Hardlinks : longint;
    Strings : TCurlFileStrings;
    Flags : cardinal;

    // used internally
    b_Data : PAnsiChar;
    b_Size, b_Used : NativeUInt;
  end;


const
  // return codes for CURLOPT_CHUNK_BGN_FUNCTION
  CURL_CHUNK_BGN_FUNC_OK      = 0;
  CURL_CHUNK_BGN_FUNC_FAIL    = 1;  // tell the lib to end the task
  CURL_CHUNK_BGN_FUNC_SKIP    = 2;  // skip this chunk over

type
  // if splitting of data transfer is enabled, this callback is called before
  // download of an individual chunk started. Note that parameter "remains" works
  // only for FTP wildcard downloading (for now), otherwise is not used
  EvCurlChinkBgn = function (
          TransferInfo, Ptr : pointer; Remains : integer) : longint;  cdecl;

const
  CURL_CHUNK_END_FUNC_OK      = 0;
  CURL_CHUNK_END_FUNC_FAIL    = 1;

type
  // If splitting of data transfer is enabled this callback is called after
  // download of an individual chunk finished.
  // Note! After this callback was set then it have to be called FOR ALL chunks.
  // Even if downloading of this chunk was skipped in CHUNK_BGN_FUNC.
  // This is the reason why we don't need "transfer_info" parameter in this
  // callback and we are not interested in "remains" parameter too.
  EvCurlChunkEnd = function (Ptr : pointer) : longint;  cdecl;

const
  CURL_FNMATCHFUNC_MATCH    = 0;  // string corresponds to the pattern
  CURL_FNMATCHFUNC_NOMATCH  = 1;  // pattern doesn't match the string
  CURL_FNMATCHFUNC_FAIL     = 2;  // an error occurred

type
  // callback type for wildcard downloading pattern matching. If the
  // string matches the pattern, return CURL_FNMATCHFUNC_MATCH value, etc.
  EvCurlFnmatch = function (
          Ptr : pointer; Pattern, Str : PAnsiChar) : integer;  cdecl;

const
  // These are the return codes for the seek callbacks
  CURL_SEEKFUNC_OK       = 0;
  CURL_SEEKFUNC_FAIL     = 1; // fail the entire transfer
  CURL_SEEKFUNC_CANTSEEK = 2; // tell libcurl seeking can't be done, so
                              //      libcurl might try other means instead

type
  EvCurlSeek = function (
          InStream : pointer;
          Offset : TCurlOff;
          Origin : integer) : integer;  cdecl;

const
  // This is a return code for the read callback that, when returned, will
  // signal libcurl to immediately abort the current transfer.
  CURL_READFUNC_ABORT = $10000000;
  // This is a return code for the read callback that, when returned, will
  // signal libcurl to pause sending data on the current transfer.
  CURL_READFUNC_PAUSE = $10000001;

type
  EvCurlRead = function (
          var Buffer;
          Size, NItems : NativeUInt;
          InStream : pointer) : NativeUInt;

type
  TCurlSockType = (
    CURLSOCKTYPE_IPCXN,  // socket created for a specific IP connection
    CURLSOCKTYPE_ACCEPT  // socket created by accept() call
    );

  TCurlSockOpt = (
    // The return code from the sockopt_callback can signal information back
    // to libcurl:
    CURL_SOCKOPT_OK,
    CURL_SOCKOPT_ERROR,  // causes libcurl to abort and return
                         //      CURLE_ABORTED_BY_CALLBACK
    CURL_SOCKOPT_ALREADY_CONNECTED
  );

  EvCurlSockopt = function(
          ClientP : pointer;
          Curlfd : TCurlSocket;
          Purpose : TCurlSockType) : TCurlSockOpt;  cdecl;

  TCurlSockAddr = record
    Family, SockType, Protocol : integer;
    AddrLen : Cardinal;
    Addr : TSockAddr;
  end;

  EvCurlOpenSocket = function(
          ClientP : integer;
          Purpose : TCurlSockType;
          var Address : TCurlSockAddr) : TCurlSocket;  cdecl;

  EvCurlCloseSocket = function (
          ClientP : integer;
          Item : TCurlSocket) : integer;  cdecl;

  EvCurlIoctl = function (
          Handle : HCurl;
          Cmd : integer;
          ClientP : pointer) : TCurlIoErr;  cdecl;

  // The following typedef's are signatures of malloc, free, realloc, strdup and
  // calloc respectively.  Function pointers of these types can be passed to the
  // curl_global_init_mem() function to set user defined memory management
  // callback routines.
  EvCurlMalloc = function (Size : NativeUInt) : pointer;  cdecl;
  EvCurlFree = procedure (Ptr : pointer)  cdecl;
  EvCurlRealloc = function (Ptr : pointer; Size : NativeUInt) : pointer;  cdecl;
  EvCurlStrDup = function (Str : PAnsiChar) : PAnsiChar;  cdecl;
  EvCurlCalloc = function (Nmemb, Size : NativeUInt) : pointer;  cdecl;

  // the kind of data that is passed to information_callback
  TCurlInfoType = (
    CURLINFO_TEXT,         // 0
    CURLINFO_HEADER_IN,    // 1
    CURLINFO_HEADER_OUT,   // 2
    CURLINFO_DATA_IN,      // 3
    CURLINFO_DATA_OUT,     // 4
    CURLINFO_SSL_DATA_IN,  // 5
    CURLINFO_SSL_DATA_OUT, // 6
    CURLINFO_END
  );

  EvCurlDebug = function (
        Handle : HCurl;
        aType : TCurlInfoType;
        Data : PAnsiChar;
        Size : NativeUInt;
        UserPtr : pointer) : integer;  cdecl;

  // All possible error codes from all sorts of curl functions. Future versions
  // may return other values, stay prepared.
  TCurlCode = (
    CURLE_OK,
    CURLE_UNSUPPORTED_PROTOCOL,    // 1
    CURLE_FAILED_INIT,             // 2
    CURLE_URL_MALFORMAT,           // 3
    CURLE_NOT_BUILT_IN,            // 4 - [was obsoleted in August 2007 for
                                   //   7.17.0, reused in April 2011 for 7.21.5]
    CURLE_COULDNT_RESOLVE_PROXY,   // 5
    CURLE_COULDNT_RESOLVE_HOST,    // 6
    CURLE_COULDNT_CONNECT,         // 7
    CURLE_FTP_WEIRD_SERVER_REPLY,  // 8
    CURLE_REMOTE_ACCESS_DENIED,    // 9 a service was denied by the server
                                   //   due to lack of access - when login fails
                                   //   this is not returned.
    CURLE_FTP_ACCEPT_FAILED,       // 10 - [was obsoleted in April 2006 for
                                   //   7.15.4, reused in Dec 2011 for 7.24.0]
    CURLE_FTP_WEIRD_PASS_REPLY,    // 11
    CURLE_FTP_ACCEPT_TIMEOUT,      // 12 - timeout occurred accepting server
                                   //   [was obsoleted in August 2007 for 7.17.0,
                                   //   reused in Dec 2011 for 7.24.0]
    CURLE_FTP_WEIRD_PASV_REPLY,    // 13
    CURLE_FTP_WEIRD_227_FORMAT,    // 14
    CURLE_FTP_CANT_GET_HOST,       // 15
    CURLE_HTTP2,                   // 16 - A problem in the http2 framing layer.
                                   //   [was obsoleted in August 2007 for 7.17.0,
                                   //   reused in July 2014 for 7.38.0]
    CURLE_FTP_COULDNT_SET_TYPE,    // 17
    CURLE_PARTIAL_FILE,            // 18
    CURLE_FTP_COULDNT_RETR_FILE,   // 19
    CURLE_OBSOLETE20,              // 20 - NOT USED
    CURLE_QUOTE_ERROR,             // 21 - quote command failure
    CURLE_HTTP_RETURNED_ERROR,     // 22
    CURLE_WRITE_ERROR,             // 23
    CURLE_OBSOLETE24,              // 24 - NOT USED
    CURLE_UPLOAD_FAILED,           // 25 - failed upload "command"
    CURLE_READ_ERROR,              // 26 - couldn't open/read from file
    CURLE_OUT_OF_MEMORY,           // 27
    // Note: CURLE_OUT_OF_MEMORY may sometimes indicate a conversion error
    //        instead of a memory allocation error if CURL_DOES_CONVERSIONS
    //        is defined
    CURLE_OPERATION_TIMEDOUT,      // 28 - the timeout time was reached
    CURLE_OBSOLETE29,              // 29 - NOT USED
    CURLE_FTP_PORT_FAILED,         // 30 - FTP PORT operation failed
    CURLE_FTP_COULDNT_USE_REST,    // 31 - the REST command failed
    CURLE_OBSOLETE32,              // 32 - NOT USED
    CURLE_RANGE_ERROR,             // 33 - RANGE "command" didn't work
    CURLE_HTTP_POST_ERROR,         // 34
    CURLE_SSL_CONNECT_ERROR,       // 35 - wrong when connecting with SSL
    CURLE_BAD_DOWNLOAD_RESUME,     // 36 - couldn't resume download
    CURLE_FILE_COULDNT_READ_FILE,  // 37
    CURLE_LDAP_CANNOT_BIND,        // 38
    CURLE_LDAP_SEARCH_FAILED,      // 39
    CURLE_OBSOLETE40,              // 40 - NOT USED
    CURLE_FUNCTION_NOT_FOUND,      // 41
    CURLE_ABORTED_BY_CALLBACK,     // 42
    CURLE_BAD_FUNCTION_ARGUMENT,   // 43
    CURLE_OBSOLETE44,              // 44 - NOT USED
    CURLE_INTERFACE_FAILED,        // 45 - CURLOPT_INTERFACE failed
    CURLE_OBSOLETE46,              // 46 - NOT USED
    CURLE_TOO_MANY_REDIRECTS ,     // 47 - catch endless re-direct loops
    CURLE_UNKNOWN_OPTION,          // 48 - User specified an unknown option
    CURLE_TELNET_OPTION_SYNTAX ,   // 49 - Malformed telnet option
    CURLE_OBSOLETE50,              // 50 - NOT USED
    CURLE_PEER_FAILED_VERIFICATION, // 51 - peer's certificate or fingerprint
                                    //   wasn't verified fine
    CURLE_GOT_NOTHING,             // 52 - when this is a specific error
    CURLE_SSL_ENGINE_NOTFOUND,     // 53 - SSL crypto engine not found
    CURLE_SSL_ENGINE_SETFAILED,    // 54 - can not set SSL crypto engine as
                                   //   default
    CURLE_SEND_ERROR,              // 55 - failed sending network data
    CURLE_RECV_ERROR,              // 56 - failure in receiving network data
    CURLE_OBSOLETE57,              // 57 - NOT IN USE
    CURLE_SSL_CERTPROBLEM,         // 58 - problem with the local certificate
    CURLE_SSL_CIPHER,              // 59 - couldn't use specified cipher
    CURLE_SSL_CACERT,              // 60 - problem with the CA cert (path?)
    CURLE_BAD_CONTENT_ENCODING,    // 61 - Unrecognized/bad encoding
    CURLE_LDAP_INVALID_URL,        // 62 - Invalid LDAP URL
    CURLE_FILESIZE_EXCEEDED,       // 63 - Maximum file size exceeded
    CURLE_USE_SSL_FAILED,          // 64 - Requested FTP SSL level failed
    CURLE_SEND_FAIL_REWIND,        // 65 - Sending the data requires a rewind
                                   //   that failed
    CURLE_SSL_ENGINE_INITFAILED,   // 66 - failed to initialise ENGINE
    CURLE_LOGIN_DENIED,            // 67 - user, password or similar was not
                                   //   accepted and we failed to login
    CURLE_TFTP_NOTFOUND,           // 68 - file not found on server
    CURLE_TFTP_PERM,               // 69 - permission problem on server
    CURLE_REMOTE_DISK_FULL,        // 70 - out of disk space on server
    CURLE_TFTP_ILLEGAL,            // 71 - Illegal TFTP operation
    CURLE_TFTP_UNKNOWNID,          // 72 - Unknown transfer ID
    CURLE_REMOTE_FILE_EXISTS,      // 73 - File already exists
    CURLE_TFTP_NOSUCHUSER,         // 74 - No such user
    CURLE_CONV_FAILED,             // 75 - conversion failed
    CURLE_CONV_REQD,               // 76 - caller must register conversion
                                   //   callbacks using curl_easy_setopt options
                                   //   CURLOPT_CONV_FROM_NETWORK_FUNCTION,
                                   //   CURLOPT_CONV_TO_NETWORK_FUNCTION, and
                                   //   CURLOPT_CONV_FROM_UTF8_FUNCTION
    CURLE_SSL_CACERT_BADFILE,      // 77 - could not load CACERT file, missing
                                   //   or wrong format
    CURLE_REMOTE_FILE_NOT_FOUND,   // 78 - remote file not found
    CURLE_SSH,                     // 79 - error from the SSH layer, somewhat
                                   //   generic so the error message will be of
                                   //   interest when this has happened

    CURLE_SSL_SHUTDOWN_FAILED,     // 80 - Failed to shut down the SSL
                                   //   connection
    CURLE_AGAIN,                   // 81 - socket is not ready for send/recv,
                                   //   wait till it's ready and try again (Added
                                   //   in 7.18.2)
    CURLE_SSL_CRL_BADFILE,         // 82 - could not load CRL file, missing or
                                   //   wrong format (Added in 7.19.0)
    CURLE_SSL_ISSUER_ERROR,        // 83 - Issuer check failed.  (Added in
                                   //   7.19.0)
    CURLE_FTP_PRET_FAILED,         // 84 - a PRET command failed
    CURLE_RTSP_CSEQ_ERROR,         // 85 - mismatch of RTSP CSeq numbers
    CURLE_RTSP_SESSION_ERROR,      // 86 - mismatch of RTSP Session Ids
    CURLE_FTP_BAD_FILE_LIST,       // 87 - unable to parse FTP file list
    CURLE_CHUNK_FAILED,            // 88 - chunk callback reported error
    CURLE_NO_CONNECTION_AVAILABLE, // 89 - No connection available, the
                                   //   session will be queued
    CURLE_SSL_PINNEDPUBKEYNOTMATCH, // 90 - specified pinned public key did not
                                    //   match
    CURLE_SSL_INVALIDCERTSTATUS,   // 91 - invalid certificate status
    CURLE_HTTP2_STREAM             // 92 - stream error in HTTP/2 framing layer
  );

  // This prototype applies to all conversion callbacks
  EvCurlConv = function (Buffer : PChar; Length : NativeUInt) : TCurlCode;  cdecl;

  EvCurlSslCtx = function (
          Curl : HCurl;             // easy handle
          SslCtx : pointer;         // actually an OpenSSL SSL_CTX
          UserPtr : pointer) : TCurlCode;  cdecl;

  TCurlProxyType = (
    CURLPROXY_HTTP = 0,     // added in 7.10, new in 7.19.4 default is to use
                            // CONNECT HTTP/1.1
    CURLPROXY_HTTP_1_0 = 1, // added in 7.19.4, force to use CONNECT
                            //   HTTP/1.0
    CURLPROXY_SOCKS4 = 4,   // support added in 7.15.2, enum existed already
                            //  in 7.10
    CURLPROXY_SOCKS5 = 5,   // added in 7.10
    CURLPROXY_SOCKS4A = 6,  // added in 7.18.0
    CURLPROXY_SOCKS5_HOSTNAME = 7 // Use the SOCKS5 protocol but pass along the
                                  // host name rather than the IP address. added
                                  // in 7.18.0
  );

const
 // Bitmasks for CURLOPT_HTTPAUTH and CURLOPT_PROXYAUTH options:
  CURLAUTH_NONE         = 0;          // No HTTP authentication
  CURLAUTH_BASIC        = 1 shl 0;    // HTTP Basic authentication (default)
  CURLAUTH_DIGEST       = 1 shl 1;    // HTTP Digest authentication
  CURLAUTH_NEGOTIATE    = 1 shl 2;    // HTTP Negotiate (SPNEGO) authentication
  CURLAUTH_NTLM         = 1 shl 3;    // HTTP NTLM authentication
  CURLAUTH_DIGEST_IE    = 1 shl 4;    // HTTP Digest authentication with IE flavour
  CURLAUTH_NTLM_WB      = 1 shl 5;    // HTTP NTLM authentication delegated to winbind helper
      // Use together with a single other type to force no
      // authentication or just that single type
  CURLAUTH_ONLY         = 1 shl 31;
  CURLAUTH_ANY          = not CURLAUTH_DIGEST_IE;     // All fine types set
  CURLAUTH_ANYSAFE      = not (CURLAUTH_BASIC or CURLAUTH_DIGEST_IE);   // All fine types except Basic

  CURLSSH_AUTH_ANY       = not 0;   // all types supported by the server
  CURLSSH_AUTH_NONE      = 0;       // none allowed, silly but complete
  CURLSSH_AUTH_PUBLICKEY = 1 shl 0; // public/private key files
  CURLSSH_AUTH_PASSWORD  = 1 shl 1; // password
  CURLSSH_AUTH_HOST      = 1 shl 2; // host key files
  CURLSSH_AUTH_KEYBOARD  = 1 shl 3; // keyboard interactive
  CURLSSH_AUTH_AGENT     = 1 shl 4; // agent (ssh-agent, pageant...)
  CURLSSH_AUTH_DEFAULT = CURLSSH_AUTH_ANY;

  CURLGSSAPI_DELEGATION_NONE        = 0;        // no delegation (default)
  CURLGSSAPI_DELEGATION_POLICY_FLAG = 1 shl 0;  // if permitted by policy
  CURLGSSAPI_DELEGATION_FLAG        = 1 shl 1;  // delegate always

  CURL_ERROR_SIZE = 256;

type
  TCurlKhType = (
    CURLKHTYPE_UNKNOWN,
    CURLKHTYPE_RSA1,
    CURLKHTYPE_RSA,
    CURLKHTYPE_DSS
  );

  TCurlKhKey = record
    Key : PAnsiChar; // points to a zero-terminated string encoded with base64
                     // if len is zero, otherwise to the "raw" data
    Len : NativeUInt;
    KeyType : TCurlKhType;
  end;

  // this is the set of return values expected from the curl_sshkeycallback
  // callback
  TCurlKhStat = (
    CURLKHSTAT_FINE_ADD_TO_FILE,
    CURLKHSTAT_FINE,
    CURLKHSTAT_REJECT, // reject the connection, return an error
    CURLKHSTAT_DEFER   // do not accept it, but we can't answer right now so
                       // this causes a CURLE_DEFER error but otherwise the
                       // connection will be left intact etc
  );

  // this is the set of status codes pass in to the callback
  TCurlKhMatch = (
    CURLKHMATCH_OK,       // match
    CURLKHMATCH_MISMATCH, // host found, key mismatch!
    CURLKHMATCH_MISSING   // no matching host/key found
  );

  EvCurlSshKey = function (
          Easy : HCurl;                           // easy handle
          const KnownKey, FoundKey : TCurlKhKey;  // known / found
          Match : TCurlKhMatch;                   // libcurl's view on the keys
          ClientP : pointer) : integer;  cdecl;   // custom pointer passed from app

  TCurlUseSsl = (
    CURLUSESSL_NONE,    // do not attempt to use SSL
    CURLUSESSL_TRY,     // try using SSL, proceed anyway otherwise
    CURLUSESSL_CONTROL, // SSL for the control connection or fail
    CURLUSESSL_ALL      // SSL for all communication or fail
  );

const
  // Definition of bits for the CURLOPT_SSL_OPTIONS argument:
  //
  // - ALLOW_BEAST tells libcurl to allow the BEAST SSL vulnerability in the
  // name of improving interoperability with older servers. Some SSL libraries
  // have introduced work-arounds for this flaw but those work-arounds sometimes
  // make the SSL communication fail. To regain functionality with those broken
  // servers, a user can this way allow the vulnerability back.
  CURLSSLOPT_ALLOW_BEAST = 1 shl 0;


  // - NO_REVOKE tells libcurl to disable certificate revocation checks for those
  // SSL backends where such behavior is present.
  CURLSSLOPT_NO_REVOKE   = 1 shl 1;

type
  // parameter for the CURLOPT_FTP_SSL_CCC option
  TCurlFtpCcc = (
    CURLFTPSSL_CCC_NONE,    // do not send CCC
    CURLFTPSSL_CCC_PASSIVE, // Let the server initiate the shutdown
    CURLFTPSSL_CCC_ACTIVE   // Initiate the shutdown
  );

  // parameter for the CURLOPT_FTPSSLAUTH option
  TCurlFtpAuth = (
    CURLFTPAUTH_DEFAULT, // let libcurl decide
    CURLFTPAUTH_SSL,     // use "AUTH SSL"
    CURLFTPAUTH_TLS      // use "AUTH TLS"
  );

  // parameter for the CURLOPT_FTP_CREATE_MISSING_DIRS option
  TCurlFtpCreateDir = (
    CURLFTP_CREATE_DIR_NONE,  // do NOT create missing dirs!
    CURLFTP_CREATE_DIR,       // (FTP/SFTP) if CWD fails, try MKD and then CWD
                              // again if MKD succeeded, for SFTP this does
                              // similar magic
    CURLFTP_CREATE_DIR_RETRY  // (FTP only) if CWD fails, try MKD and then CWD
                              // again even if MKD failed!
  );

  // parameter for the CURLOPT_FTP_FILEMETHOD option
  TCurlFtpMethod = (
    CURLFTPMETHOD_DEFAULT,   // let libcurl pick
    CURLFTPMETHOD_MULTICWD,  // single CWD operation for each path part
    CURLFTPMETHOD_NOCWD,     // no CWD at all
    CURLFTPMETHOD_SINGLECWD  // one CWD to full dir, then work on file
  );

const
  CURLHEADER_UNIFIED  = 0;
  CURLHEADER_SEPARATE = 1 shl 0;

  // CURLPROTO_ defines are for the CURLOPT_*PROTOCOLS options
  CURLPROTO_HTTP   = 1 shl 0;
  CURLPROTO_HTTPS  = 1 shl 1;
  CURLPROTO_FTP    = 1 shl 2;
  CURLPROTO_FTPS   = 1 shl 3;
  CURLPROTO_SCP    = 1 shl 4;
  CURLPROTO_SFTP   = 1 shl 5;
  CURLPROTO_TELNET = 1 shl 6;
  CURLPROTO_LDAP   = 1 shl 7;
  CURLPROTO_LDAPS  = 1 shl 8;
  CURLPROTO_DICT   = 1 shl 9;
  CURLPROTO_FILE   = 1 shl 10;
  CURLPROTO_TFTP   = 1 shl 11;
  CURLPROTO_IMAP   = 1 shl 12;
  CURLPROTO_IMAPS  = 1 shl 13;
  CURLPROTO_POP3   = 1 shl 14;
  CURLPROTO_POP3S  = 1 shl 15;
  CURLPROTO_SMTP   = 1 shl 16;
  CURLPROTO_SMTPS  = 1 shl 17;
  CURLPROTO_RTSP   = 1 shl 18;
  CURLPROTO_RTMP   = 1 shl 19;
  CURLPROTO_RTMPT  = 1 shl 20;
  CURLPROTO_RTMPE  = 1 shl 21;
  CURLPROTO_RTMPTE = 1 shl 22;
  CURLPROTO_RTMPS  = 1 shl 23;
  CURLPROTO_RTMPTS = 1 shl 24;
  CURLPROTO_GOPHER = 1 shl 25;
  CURLPROTO_SMB    = 1 shl 26;
  CURLPROTO_SMBS   = 1 shl 27;
  CURLPROTO_ALL    = not 0;   // enable everything

// long may be 32 or 64 bits, but we should never depend on anything else
//   but 32
  CURLOPTTYPE_LONG          = 0;
  CURLOPTTYPE_OBJECTPOINT   = 10000;
  CURLOPTTYPE_STRINGPOINT   = CURLOPTTYPE_OBJECTPOINT;
  CURLOPTTYPE_FUNCTIONPOINT = 20000;
  CURLOPTTYPE_OFF_T         = 30000;

type
  TCurlIntOption = (
    // Port number to connect to, if other than default.
    CURLOPT_PORT = CURLOPTTYPE_LONG + 3,

    // Time-out the read operation after this amount of seconds
    CURLOPT_TIMEOUT = CURLOPTTYPE_LONG + 13,

    // If the CURLOPT_INFILE is used, this can be used to inform libcurl about
    // how large the file being sent really is. That allows better error
    // checking and better verifies that the upload was successful. -1 means
    // unknown size.
    //
    // For large file support, there is also a _LARGE version of the key
    // which takes an off_t type, allowing platforms with larger off_t
    // sizes to handle larger files.  See below for INFILESIZE_LARGE.
    CURLOPT_INFILESIZE = CURLOPTTYPE_LONG + 14,

    // If the download receives less than "low speed limit" bytes/second
    // during "low speed time" seconds, the operations is aborted.
    // You could i.e if you have a pretty high speed connection, abort if
    // it is less than 2000 bytes/sec during 20 seconds.

    // Set the "low speed limit"
    CURLOPT_LOW_SPEED_LIMIT = CURLOPTTYPE_LONG + 19,

    // Set the "low speed time"
    CURLOPT_LOW_SPEED_TIME = CURLOPTTYPE_LONG + 20,

    // Set the continuation offset.
    //
    // Note there is also a _LARGE version of this key which uses
    // off_t types, allowing for large file offsets on platforms which
    // use larger-than-32-bit off_t's.  Look below for RESUME_FROM_LARGE.
    CURLOPT_RESUME_FROM = CURLOPTTYPE_LONG + 21,

    // send TYPE parameter?
    CURLOPT_CRLF = CURLOPTTYPE_LONG + 27,

    // Identified as SslVersion
    //CURLOPT_SSLVERSION = CURLOPTTYPE_LONG + 32,

    // What kind of HTTP time condition to use, see defines
    CURLOPT_TIMECONDITION = CURLOPTTYPE_LONG + 33,

    // Time to use with the above condition. Specified in number of seconds
    // since 1 Jan 1970
    CURLOPT_TIMEVALUE = CURLOPTTYPE_LONG + 34,

    CURLOPT_VERBOSE = CURLOPTTYPE_LONG + 41,        // talk a lot
    CURLOPT_HEADER = CURLOPTTYPE_LONG + 42,         // throw the header out too
    CURLOPT_NOPROGRESS = CURLOPTTYPE_LONG + 43,     // shut off the progress meter
    CURLOPT_NOBODY = CURLOPTTYPE_LONG + 44,         // use HEAD to get http document
    CURLOPT_FAILONERROR = CURLOPTTYPE_LONG + 45,    // no output on http error codes >= 400
    CURLOPT_UPLOAD = CURLOPTTYPE_LONG + 46,         // this is an upload
    CURLOPT_POST = CURLOPTTYPE_LONG + 47,           // HTTP POST method
    CURLOPT_DIRLISTONLY = CURLOPTTYPE_LONG + 48,    // bare names when listing directories

    CURLOPT_APPEND = CURLOPTTYPE_LONG + 50,         // Append instead of overwrite on upload!

    // Identified as NetRc
    //CURLOPT_NETRC = CURLOPTTYPE_LONG + 51,

    CURLOPT_FOLLOWLOCATION = CURLOPTTYPE_LONG + 52,    // use Location: Luke!

    CURLOPT_TRANSFERTEXT = CURLOPTTYPE_LONG + 53,   // transfer data in text/ASCII format
    CURLOPT_PUT = CURLOPTTYPE_LONG + 54,            // HTTP PUT

    // We want the referrer field set automatically when following locations
    CURLOPT_AUTOREFERER = CURLOPTTYPE_LONG + 58,

    // Port of the proxy, can be set in the proxy string as well with:
    // "[host]:[port]"
    CURLOPT_PROXYPORT = CURLOPTTYPE_LONG + 59,

    // size of the POST input data, if strlen() is not good to use
    CURLOPT_POSTFIELDSIZE = CURLOPTTYPE_LONG + 60,

    // tunnel non-http operations through a HTTP proxy
    CURLOPT_HTTPPROXYTUNNEL = CURLOPTTYPE_LONG + 61,

    // Set if we should verify the peer in ssl handshake, set 1 to verify.
    CURLOPT_SSL_VERIFYPEER = CURLOPTTYPE_LONG + 64,

    // Maximum number of http redirects to follow
    CURLOPT_MAXREDIRS = CURLOPTTYPE_LONG + 68,

    // Pass a long set to 1 to get the date of the requested document (if
    // possible)! Pass a zero to shut it off.
    CURLOPT_FILETIME = CURLOPTTYPE_LONG + 69,

    // Max amount of cached alive connections
    CURLOPT_MAXCONNECTS = CURLOPTTYPE_LONG + 71,

    // Set to explicitly use a new connection for the upcoming transfer.
    // Do not use this unless you're absolutely sure of this, as it makes the
    // operation slower and is less friendly for the network.
    CURLOPT_FRESH_CONNECT = CURLOPTTYPE_LONG + 74,

    // Set to explicitly forbid the upcoming transfer's connection to be re-used
    // when done. Do not use this unless you're absolutely sure of this, as it
    // makes the operation slower and is less friendly for the network.
    CURLOPT_FORBID_REUSE = CURLOPTTYPE_LONG + 75,

    // Time-out connect operations after this amount of seconds, if connects are
    // OK within this time, then fine... This only aborts the connect phase.
    CURLOPT_CONNECTTIMEOUT = CURLOPTTYPE_LONG + 78,

    // Set this to force the HTTP request to get back to GET. Only really usable
    // if POST, PUT or a custom request have been used first.
    CURLOPT_HTTPGET = CURLOPTTYPE_LONG + 80,

    // Set if we should verify the Common name from the peer certificate in ssl
    // handshake, set 1 to check existence, 2 to ensure that it matches the
    // provided hostname.
    CURLOPT_SSL_VERIFYHOST = CURLOPTTYPE_LONG + 81,

    // Specify which HTTP version to use! This must be set to one of the
    // CURL_HTTP_VERSION* enums set below.
    CURLOPT_HTTP_VERSION = CURLOPTTYPE_LONG + 84,

    // Specifically switch on or off the FTP engine's use of the EPSV command. By
    // default, that one will always be attempted before the more traditional
    // PASV command.
    CURLOPT_FTP_USE_EPSV = CURLOPTTYPE_LONG + 85,

    // set the crypto engine for the SSL-sub system as default
    // the param has no meaning...
    CURLOPT_SSLENGINE_DEFAULT = CURLOPTTYPE_LONG + 90,

    // Non-zero value means to use the global dns cache
    CURLOPT_DNS_USE_GLOBAL_CACHE = CURLOPTTYPE_LONG + 91,   // DEPRECATED, do not use!

    // DNS cache timeout
    CURLOPT_DNS_CACHE_TIMEOUT = CURLOPTTYPE_LONG + 92,

    // mark this as start of a cookie session
    CURLOPT_COOKIESESSION = CURLOPTTYPE_LONG + 96,

    // Instruct libcurl to use a smaller receive buffer
    CURLOPT_BUFFERSIZE = CURLOPTTYPE_LONG + 98,

    // Instruct libcurl to not use any signal/alarm handlers, even when using
    // timeouts. This option is useful for multi-threaded applications.
    // See libcurl-the-guide for more background information.
    CURLOPT_NOSIGNAL = CURLOPTTYPE_LONG + 99,

    // Continue to send authentication (user+password) when following locations,
    // even when hostname changed. This can potentially send off the name
    // and password to whatever host the server decides.
    CURLOPT_UNRESTRICTED_AUTH = CURLOPTTYPE_LONG + 105,

    // Specifically switch on or off the FTP engine's use of the EPRT command (
    // it also disables the LPRT attempt). By default, those ones will always be
    // attempted before the good old traditional PORT command.
    CURLOPT_FTP_USE_EPRT = CURLOPTTYPE_LONG + 106,

    // Set this to a bitmask value to enable the particular authentications
    // methods you like. Use this in combination with CURLOPT_USERPWD.
    // Note that setting multiple bits may cause extra network round-trips.
    CURLOPT_HTTPAUTH = CURLOPTTYPE_LONG + 107,

    // FTP Option that causes missing dirs to be created on the remote server.
    // In 7.19.4 we introduced the convenience enums for this option using the
    // CURLFTP_CREATE_DIR prefix.
    CURLOPT_FTP_CREATE_MISSING_DIRS = CURLOPTTYPE_LONG + 110,

    // Set this to a bitmask value to enable the particular authentications
    // methods you like. Use this in combination with CURLOPT_PROXYUSERPWD.
    // Note that setting multiple bits may cause extra network round-trips.
    CURLOPT_PROXYAUTH = CURLOPTTYPE_LONG + 111,

    // FTP option that changes the timeout, in seconds, associated with
    // getting a response.  This is different from transfer timeout time and
    // essentially places a demand on the FTP server to acknowledge commands
    // in a timely manner.
    CURLOPT_FTP_RESPONSE_TIMEOUT = CURLOPTTYPE_LONG + 112,
    CURLOPT_SERVER_RESPONSE_TIMEOUT = CURLOPT_FTP_RESPONSE_TIMEOUT,

    // Set this option to limit the size of a file that will be downloaded from
    // an HTTP or FTP server.
    //
    // Note there is also _LARGE version which adds large file support for
    // platforms which have larger off_t sizes.  See MAXFILESIZE_LARGE below.
    CURLOPT_MAXFILESIZE = CURLOPTTYPE_LONG + 114,

    // Gone to its own enum
    //CURLOPT_USE_SSL = CURLOPTTYPE_LONG + 119,

    // Enable/disable the TCP Nagle algorithm
    CURLOPT_TCP_NODELAY = CURLOPTTYPE_LONG + 121,

    // When FTP over SSL/TLS is selected (with CURLOPT_USE_SSL, this option
    // can be used to change libcurl's default action which is to first try
    // "AUTH SSL" and then "AUTH TLS" in this order, and proceed when a OK
    // response has been received.
    //
    // Available parameters are:
    // CURLFTPAUTH_DEFAULT - let libcurl decide
    // CURLFTPAUTH_SSL     - try "AUTH SSL" first, then TLS
    // CURLFTPAUTH_TLS     - try "AUTH TLS" first, then SSL
    CURLOPT_FTPSSLAUTH = CURLOPTTYPE_LONG + 129,

    // ignore Content-Length
    CURLOPT_IGNORE_CONTENT_LENGTH = CURLOPTTYPE_LONG + 136,

    // Set to non-zero to skip the IP address received in a 227 PASV FTP server
    // response. Typically used for FTP-SSL purposes but is not restricted to
    // that. libcurl will then instead use the same IP address it used for the
    // control connection.
    CURLOPT_FTP_SKIP_PASV_IP = CURLOPTTYPE_LONG + 137,

    // Gone to its own enum
    //CURLOPT_FTP_FILEMETHOD = CURLOPTTYPE_LONG + 138,

    // Local port number to bind the socket to
    CURLOPT_LOCALPORT = CURLOPTTYPE_LONG + 139,

    // Number of ports to try, including the first one set with LOCALPORT.
    // Thus, setting it to 1 will make no additional attempts but the first.
    CURLOPT_LOCALPORTRANGE = CURLOPTTYPE_LONG + 140,

    // no transfer, set up connection and let application use the socket by
    // extracting it with CURLINFO_LASTSOCKET
    CURLOPT_CONNECT_ONLY = CURLOPTTYPE_LONG + 141,

    // set to 0 to disable session ID re-use for this transfer, default is
    // enabled (== 1)
    CURLOPT_SSL_SESSIONID_CACHE = CURLOPTTYPE_LONG + 150,

    // allowed SSH authentication methods
    CURLOPT_SSH_AUTH_TYPES = CURLOPTTYPE_LONG + 151,

    // Send CCC (Clear Command Channel) after authentication
    CURLOPT_FTP_SSL_CCC = CURLOPTTYPE_LONG + 154,

    // Same as TIMEOUT and CONNECTTIMEOUT, but with ms resolution
    CURLOPT_TIMEOUT_MS = CURLOPTTYPE_LONG + 155,
    CURLOPT_CONNECTTIMEOUT_MS = CURLOPTTYPE_LONG + 156,

    // set to zero to disable the libcurl's decoding and thus pass the raw body
    // data to the application even when it is encoded/compressed
    CURLOPT_HTTP_TRANSFER_DECODING = CURLOPTTYPE_LONG + 157,
    CURLOPT_HTTP_CONTENT_DECODING = CURLOPTTYPE_LONG + 158,

    // Permission used when creating new files and directories on the remote
    // server for protocols that support it, SFTP/SCP/FILE
    CURLOPT_NEW_FILE_PERMS = CURLOPTTYPE_LONG + 159,
    CURLOPT_NEW_DIRECTORY_PERMS = CURLOPTTYPE_LONG + 160,

    // Set the behaviour of POST when redirecting. Values must be set to one
    // of CURL_REDIR* defines below. This used to be called CURLOPT_POST301
    CURLOPT_POSTREDIR = CURLOPTTYPE_LONG + 161,

    // set transfer mode (;type=<a|i>) when doing FTP via an HTTP proxy
    CURLOPT_PROXY_TRANSFER_MODE = CURLOPTTYPE_LONG + 166,

    // (IPv6) Address scope
    CURLOPT_ADDRESS_SCOPE = CURLOPTTYPE_LONG + 171,

    // Collect certificate chain info and allow it to get retrievable with
    // CURLINFO_CERTINFO after the transfer is complete.
    CURLOPT_CERTINFO = CURLOPTTYPE_LONG + 172,

    // block size for TFTP transfers
    CURLOPT_TFTP_BLKSIZE = CURLOPTTYPE_LONG + 178,

    // Socks Service
    CURLOPT_SOCKS5_GSSAPI_NEC = CURLOPTTYPE_LONG + 180,

    // set the bitmask for the protocols that are allowed to be used for the
    // transfer, which thus helps the app which takes URLs from users or other
    // external inputs and want to restrict what protocol(s) to deal
    // with. Defaults to CURLPROTO_ALL.
    CURLOPT_PROTOCOLS = CURLOPTTYPE_LONG + 181,

    // set the bitmask for the protocols that libcurl is allowed to follow to,
    // as a subset of the CURLOPT_PROTOCOLS ones. That means the protocol needs
    // to be set in both bitmasks to be allowed to get redirected to. Defaults
    // to all protocols except FILE and SCP.
    CURLOPT_REDIR_PROTOCOLS = CURLOPTTYPE_LONG + 182,

    // FTP: send PRET before PASV
    CURLOPT_FTP_USE_PRET = CURLOPTTYPE_LONG + 188,

    // RTSP request method (OPTIONS, SETUP, PLAY, etc...)
    // Identified as RTSP request
    //CURLOPT_RTSP_REQUEST = CURLOPTTYPE_LONG + 189,

    // Manually initialize the client RTSP CSeq for this handle
    CURLOPT_RTSP_CLIENT_CSEQ = CURLOPTTYPE_LONG + 193,

    // Manually initialize the server RTSP CSeq for this handle
    CURLOPT_RTSP_SERVER_CSEQ = CURLOPTTYPE_LONG + 194,

    // Turn on wildcard matching
    CURLOPT_WILDCARDMATCH = CURLOPTTYPE_LONG + 197,

    // Set to 1 to enable the "TE:" header in HTTP requests to ask for
    // compressed transfer-encoded responses. Set to 0 to disable the use of TE:
    // in outgoing requests. The current default is 0, but it might change in a
    // future libcurl release.
    //
    // libcurl will ask for the compressed methods it knows of, and if that
    // isn't any, it will not ask for transfer-encoding at all even if this
    // option is set to 1.
    CURLOPT_TRANSFER_ENCODING = CURLOPTTYPE_LONG + 207,

    // allow GSSAPI credential delegation
    CURLOPT_GSSAPI_DELEGATION = CURLOPTTYPE_LONG + 210,

    // Time-out accept operations (currently for FTP only) after this amount
    // of miliseconds.
    CURLOPT_ACCEPTTIMEOUT_MS = CURLOPTTYPE_LONG + 212,

    // Set TCP keepalive
    CURLOPT_TCP_KEEPALIVE = CURLOPTTYPE_LONG + 213,

    // non-universal keepalive knobs (Linux, AIX, HP-UX, more)
    CURLOPT_TCP_KEEPIDLE = CURLOPTTYPE_LONG + 214,
    CURLOPT_TCP_KEEPINTVL = CURLOPTTYPE_LONG + 215,

    // Enable/disable specific SSL features with a bitmask, see CURLSSLOPT_*
    CURLOPT_SSL_OPTIONS = CURLOPTTYPE_LONG + 216,

    // Enable/disable SASL initial response
    CURLOPT_SASL_IR = CURLOPTTYPE_LONG + 218,

    // Enable/disable TLS NPN extension (http2 over ssl might fail without)
    CURLOPT_SSL_ENABLE_NPN = CURLOPTTYPE_LONG + 225,

    // Enable/disable TLS ALPN extension (http2 over ssl might fail without)
    CURLOPT_SSL_ENABLE_ALPN = CURLOPTTYPE_LONG + 226,

    // Time to wait for a response to a HTTP request containing an
    // Expect: 100-continue header before sending the data anyway.
    CURLOPT_EXPECT_100_TIMEOUT_MS = CURLOPTTYPE_LONG + 227,

    // Pass in a bitmask of "header options"
    CURLOPT_HEADEROPT = CURLOPTTYPE_LONG + 229,

    // Set if we should verify the certificate status
    CURLOPT_SSL_VERIFYSTATUS = CURLOPTTYPE_LONG + 232,

    // Set if we should enable TLS false start.
    CURLOPT_SSL_FALSESTART = CURLOPTTYPE_LONG + 233,

    // Do not squash dot-dot sequences
    CURLOPT_PATH_AS_IS = CURLOPTTYPE_LONG + 234,

    // Wait/don't wait for pipe/mutex to clarify
    CURLOPT_PIPEWAIT = CURLOPTTYPE_LONG + 237,

    // Set stream weight, 1 - 256 (default is 16)
    CURLOPT_STREAM_WEIGHT = CURLOPTTYPE_LONG + 239,

    // Do not send any tftp option requests to the server
    CURLOPT_TFTP_NO_OPTIONS = CURLOPTTYPE_LONG + 242,

    // Set TCP Fast Open
    CURLOPT_TCP_FASTOPEN = CURLOPTTYPE_LONG + 244,

    // Continue to send data if the server responds early with an
    // HTTP status code >= 300
    CURLOPT_KEEP_SENDING_ON_ERROR = CURLOPTTYPE_LONG + 245,

    // Set if we should verify the proxy in ssl handshake,
    // set 1 to verify.
    CURLOPT_PROXY_SSL_VERIFYPEER = CURLOPTTYPE_LONG + 248,

    // Set if we should verify the Common name from the proxy certificate in ssl
    // handshake, set 1 to check existence, 2 to ensure that it matches
    // the provided hostname.
    CURLOPT_PROXY_SSL_VERIFYHOST = CURLOPTTYPE_LONG + 249,

    // Identified as SslVersion
    //CURLOPT_PROXY_SSLVERSION = CURLOPTTYPE_LONG + 250,

    // Enable/disable specific SSL features with a bitmask for proxy, see
    // CURLSSLOPT_*
    CURLOPT_PROXY_SSL_OPTIONS = CURLOPTTYPE_LONG + 261,

    // Suppress proxy CONNECT response headers from user callbacks
    CURLOPT_SUPPRESS_CONNECT_HEADERS = CURLOPTTYPE_LONG + 265,

    // bitmask of allowed auth methods for connections to SOCKS5 proxies
    CURLOPT_SOCKS5_AUTH = CURLOPTTYPE_LONG + 267,

    // Enable/disable SSH compression
    CURLOPT_SSH_COMPRESSION = CURLOPTTYPE_LONG + 268
  );

  TCurlProxyTypeOption = (
    // indicates type of proxy. accepted values are CURLPROXY_HTTP (default,
    // CURLPROXY_SOCKS4, CURLPROXY_SOCKS4A and CURLPROXY_SOCKS5.
    CURLOPT_PROXYTYPE = CURLOPTTYPE_LONG + 101
  );

  TCurlUseSslOption = (
    // Enable SSL/TLS for FTP, pick one of:
    // CURLUSESSL_TRY     - try using SSL, proceed anyway otherwise
    // CURLUSESSL_CONTROL - SSL for the control connection or fail
    // CURLUSESSL_ALL     - SSL for all communication or fail
    CURLOPT_USE_SSL = CURLOPTTYPE_LONG + 119
  );

  TCurlFtpMethodOption = (
    // Select "file method" to use when doing FTP, see the curl_ftpmethod
    // above.
    CURLOPT_FTP_FILEMETHOD = CURLOPTTYPE_LONG + 138
  );

  TCurlIpResolveOption = (
    // Set this option to one of the CURL_IPRESOLVE_* defines (see below) to
    // tell libcurl to resolve names to those IP versions only. This only has
    // affect on systems with support for more than one, i.e IPv4 _and_ IPv6.
    CURLOPT_IPRESOLVE = CURLOPTTYPE_LONG + 113
  );

  TCurlRtspSeqOption = (
    // RTSP request method (OPTIONS, SETUP, PLAY, etc...)
    CURLOPT_RTSP_REQUEST = CURLOPTTYPE_LONG + 189
  );

  TCurlNetRcOption = (
      // Specify whether to read the user+password from the .netrc or the URL.
    // This must be one of the CURL_NETRC_* enums below.
    CURLOPT_NETRC = CURLOPTTYPE_LONG + 51
  );

  TCurlSslVersionOption = (
    // What version to specifically try to use.
    // See CURL_SSLVERSION defines below.
    CURLOPT_SSLVERSION = CURLOPTTYPE_LONG + 32,

    // What version to specifically try to use for proxy.
    // See CURL_SSLVERSION defines below.
    CURLOPT_PROXY_SSLVERSION = CURLOPTTYPE_LONG + 250
  );

  TCurlOffOption = (
    // See the comment for INFILESIZE above, but in short, specifies
    // the size of the file being uploaded.  -1 means unknown.
    CURLOPT_INFILESIZE_LARGE = CURLOPTTYPE_OFF_T + 115,

    // Sets the continuation offset.  There is also a LONG version of this;
    // look above for RESUME_FROM.
    CURLOPT_RESUME_FROM_LARGE = CURLOPTTYPE_OFF_T + 116,

    // Sets the maximum size of data that will be downloaded from
    // an HTTP or FTP server.  See MAXFILESIZE for the LONG version.
    CURLOPT_MAXFILESIZE_LARGE = CURLOPTTYPE_OFF_T + 117,

    // The _LARGE version of the standard POSTFIELDSIZE option
    CURLOPT_POSTFIELDSIZE_LARGE = CURLOPTTYPE_OFF_T + 120,

    // if the connection proceeds too quickly then need to slow it down
    // limit-rate: maximum number of bytes per second to send or receive
    CURLOPT_MAX_SEND_SPEED_LARGE = CURLOPTTYPE_OFF_T + 145,
    CURLOPT_MAX_RECV_SPEED_LARGE = CURLOPTTYPE_OFF_T + 146
  );

  TCurlStringOption = (
    // The full URL to get/put
    CURLOPT_URL = CURLOPTTYPE_STRINGPOINT + 2,

    // Name of proxy to use.
    CURLOPT_PROXY = CURLOPTTYPE_STRINGPOINT + 4,

    // "user:password;options" to use when fetching.
    CURLOPT_USERPWD = CURLOPTTYPE_STRINGPOINT + 5,

    // "user:password" to use with proxy.
    CURLOPT_PROXYUSERPWD = CURLOPTTYPE_STRINGPOINT + 6,

    // Range to get, specified as an ASCII string.
    CURLOPT_RANGE = CURLOPTTYPE_STRINGPOINT + 7,

    // Set the referrer page (needed by some CGIs)
    CURLOPT_REFERER = CURLOPTTYPE_STRINGPOINT + 16,

    // Set the FTP PORT string (interface name, named or numerical IP address)
    // Use i.e '-' to use default address.
    CURLOPT_FTPPORT = CURLOPTTYPE_STRINGPOINT + 17,

    // Set the User-Agent string (examined by some CGIs)
    CURLOPT_USERAGENT = CURLOPTTYPE_STRINGPOINT + 18,

    // Set cookie in request:
    CURLOPT_COOKIE = CURLOPTTYPE_STRINGPOINT + 22,

    // name of the file keeping your private SSL-certificate
    CURLOPT_SSLCERT = CURLOPTTYPE_STRINGPOINT + 25,

    // password for the SSL or SSH private key
    CURLOPT_KEYPASSWD = CURLOPTTYPE_STRINGPOINT + 26,

    // point to a file to read the initial cookies from, also enables
    // "cookie awareness"
    CURLOPT_COOKIEFILE = CURLOPTTYPE_STRINGPOINT + 31,

    // Custom request, for customizing the get command like
    // HTTP: DELETE, TRACE and others
    // FTP: to use a different list command
    CURLOPT_CUSTOMREQUEST = CURLOPTTYPE_STRINGPOINT + 36,

    // Set the interface string to use as outgoing network interface
    CURLOPT_INTERFACE = CURLOPTTYPE_STRINGPOINT + 62,

    // Set the krb4/5 security level, this also enables krb4/5 awareness.  This
    // is a string, 'clear', 'safe', 'confidential' or 'private'.  If the string
    // is set but doesn't match one of these, 'private' will be used.
    CURLOPT_KRBLEVEL = CURLOPTTYPE_STRINGPOINT + 63,

    // The CApath or CAfile used to validate the peer certificate
    // this option is used only if SSL_VERIFYPEER is true
    CURLOPT_CAINFO = CURLOPTTYPE_STRINGPOINT + 65,

    // Set to a file name that contains random data for libcurl to use to
    // seed the random engine when doing SSL connects.
    CURLOPT_RANDOM_FILE = CURLOPTTYPE_STRINGPOINT + 76,

    // Set to the Entropy Gathering Daemon socket pathname
    CURLOPT_EGDSOCKET = CURLOPTTYPE_STRINGPOINT + 77,

    // Specify which file name to write all known cookies in after completed
    // operation. Set file name to "-" (dash) to make it go to stdout.
    CURLOPT_COOKIEJAR = CURLOPTTYPE_STRINGPOINT + 82,

    // Specify which SSL ciphers to use
    CURLOPT_SSL_CIPHER_LIST = CURLOPTTYPE_STRINGPOINT + 83,

    // type of the file keeping your SSL-certificate ("DER", "PEM", "ENG")
    CURLOPT_SSLCERTTYPE = CURLOPTTYPE_STRINGPOINT + 86,

    // name of the file keeping your private SSL-key
    CURLOPT_SSLKEY = CURLOPTTYPE_STRINGPOINT + 87,

    // type of the file keeping your private SSL-key ("DER", "PEM", "ENG")
    CURLOPT_SSLKEYTYPE = CURLOPTTYPE_STRINGPOINT + 88,

    // crypto engine for the SSL-sub system
    CURLOPT_SSLENGINE = CURLOPTTYPE_STRINGPOINT + 89,

    // The CApath directory used to validate the peer certificate
    // this option is used only if SSL_VERIFYPEER is true
    // Does not work on Windows, so stop!
    //CURLOPT_CAPATH = CURLOPTTYPE_STRINGPOINT + 97,

    // Set the Accept-Encoding string. Use this to tell a server you would like
    // the response to be compressed. Before 7.21.6, this was known as
    // CURLOPT_ENCODING
    CURLOPT_ACCEPT_ENCODING = CURLOPTTYPE_STRINGPOINT + 102,

    // Set this option to the file name of your .netrc file you want libcurl
    // to parse (using the CURLOPT_NETRC option). If not set, libcurl will do
    // a poor attempt to find the user's home directory and check for a .netrc
    // file in there.
    CURLOPT_NETRC_FILE = CURLOPTTYPE_STRINGPOINT + 118,

    // zero terminated string for pass on to the FTP server when asked for
    // "account" info
    CURLOPT_FTP_ACCOUNT = CURLOPTTYPE_STRINGPOINT + 134,

    // feed cookies into cookie engine
    CURLOPT_COOKIELIST = CURLOPTTYPE_STRINGPOINT + 135,

    // Pointer to command string to send if USER/PASS fails.
    CURLOPT_FTP_ALTERNATIVE_TO_USER = CURLOPTTYPE_STRINGPOINT + 147,

    // Used by scp/sftp to do public/private key authentication
    CURLOPT_SSH_PUBLIC_KEYFILE = CURLOPTTYPE_STRINGPOINT + 152,
    CURLOPT_SSH_PRIVATE_KEYFILE = CURLOPTTYPE_STRINGPOINT + 153,

    // used by scp/sftp to verify the host's public key
    CURLOPT_SSH_HOST_PUBLIC_KEY_MD5 = CURLOPTTYPE_STRINGPOINT + 162,

    // POST volatile input fields.
    CURLOPT_COPYPOSTFIELDS = CURLOPTTYPE_STRINGPOINT + 165,

    // CRL file
    CURLOPT_CRLFILE = CURLOPTTYPE_STRINGPOINT + 169,

    // Issuer certificate
    CURLOPT_ISSUERCERT = CURLOPTTYPE_STRINGPOINT + 170,

    // "name" and "pwd" to use when fetching.
    CURLOPT_USERNAME = CURLOPTTYPE_STRINGPOINT + 173,
    CURLOPT_PASSWORD = CURLOPTTYPE_STRINGPOINT + 174,

      // "name" and "pwd" to use with Proxy when fetching.
    CURLOPT_PROXYUSERNAME = CURLOPTTYPE_STRINGPOINT + 175,
    CURLOPT_PROXYPASSWORD = CURLOPTTYPE_STRINGPOINT + 176,

    // Comma separated list of hostnames defining no-proxy zones. These should
    // match both hostnames directly, and hostnames within a domain. For
    // example, local.com will match local.com and www.local.com, but NOT
    // notlocal.com or www.notlocal.com. For compatibility with other
    // implementations of this, .local.com will be considered to be the same as
    // local.com. A single * is the only valid wildcard, and effectively
    // disables the use of proxy.
    CURLOPT_NOPROXY = CURLOPTTYPE_STRINGPOINT + 177,

    // Socks Service
    CURLOPT_SOCKS5_GSSAPI_SERVICE = CURLOPTTYPE_STRINGPOINT + 179,

    // set the SSH knownhost file name to use
    CURLOPT_SSH_KNOWNHOSTS = CURLOPTTYPE_STRINGPOINT + 183,

    // set the SMTP mail originator
    CURLOPT_MAIL_FROM = CURLOPTTYPE_STRINGPOINT + 186,

    // The RTSP session identifier
    CURLOPT_RTSP_SESSION_ID = CURLOPTTYPE_STRINGPOINT + 190,

    // The RTSP stream URI
    CURLOPT_RTSP_STREAM_URI = CURLOPTTYPE_STRINGPOINT + 191,

    // The Transport: header to use in RTSP requests
    CURLOPT_RTSP_TRANSPORT = CURLOPTTYPE_STRINGPOINT + 192,

    // Set a username for authenticated TLS
    CURLOPT_TLSAUTH_USERNAME = CURLOPTTYPE_STRINGPOINT + 204,

    // Set a password for authenticated TLS
    CURLOPT_TLSAUTH_PASSWORD = CURLOPTTYPE_STRINGPOINT + 205,

    // Set authentication type for authenticated TLS
    CURLOPT_TLSAUTH_TYPE = CURLOPTTYPE_STRINGPOINT + 206,

    // Set the name servers to use for DNS resolution
    CURLOPT_DNS_SERVERS = CURLOPTTYPE_STRINGPOINT + 211,

    // Set the SMTP auth originator
    CURLOPT_MAIL_AUTH = CURLOPTTYPE_STRINGPOINT + 217,

    // The XOAUTH2 bearer token
    CURLOPT_XOAUTH2_BEARER = CURLOPTTYPE_STRINGPOINT + 220,

    // Set the interface string to use as outgoing network
    // interface for DNS requests.
    // Only supported by the c-ares DNS backend
    CURLOPT_DNS_INTERFACE = CURLOPTTYPE_STRINGPOINT + 221,

    // Set the local IPv4 address to use for outgoing DNS requests.
    // Only supported by the c-ares DNS backend
    CURLOPT_DNS_LOCAL_IP4 = CURLOPTTYPE_STRINGPOINT + 222,

    // Set the local IPv4 address to use for outgoing DNS requests.
    // Only supported by the c-ares DNS backend
    CURLOPT_DNS_LOCAL_IP6 = CURLOPTTYPE_STRINGPOINT + 223,

    // Set authentication options directly
    CURLOPT_LOGIN_OPTIONS = CURLOPTTYPE_STRINGPOINT + 224,

    // The public key in DER form used to validate the peer public key
    // this option is used only if SSL_VERIFYPEER is true
    CURLOPT_PINNEDPUBLICKEY = CURLOPTTYPE_STRINGPOINT + 230,

    // Path to Unix domain socket
    CURLOPT_UNIX_SOCKET_PATH = CURLOPTTYPE_STRINGPOINT + 231,

    // Proxy Service Name
    CURLOPT_PROXY_SERVICE_NAME = CURLOPTTYPE_STRINGPOINT + 235,

    // Service Name
    CURLOPT_SERVICE_NAME = CURLOPTTYPE_STRINGPOINT + 236,

    // Set the protocol used when curl is given a URL without a protocol
    CURLOPT_DEFAULT_PROTOCOL = CURLOPTTYPE_STRINGPOINT + 238,

    // The CApath or CAfile used to validate the proxy certificate
    // this option is used only if PROXY_SSL_VERIFYPEER is true
    CURLOPT_PROXY_CAINFO = CURLOPTTYPE_STRINGPOINT + 246,

    // The CApath directory used to validate the proxy certificate
    // this option is used only if PROXY_SSL_VERIFYPEER is true
    CURLOPT_PROXY_CAPATH = CURLOPTTYPE_STRINGPOINT + 247,

    // Set a username for authenticated TLS for proxy
    CURLOPT_PROXY_TLSAUTH_USERNAME = CURLOPTTYPE_STRINGPOINT + 251,

    // Set a password for authenticated TLS for proxy
    CURLOPT_PROXY_TLSAUTH_PASSWORD = CURLOPTTYPE_STRINGPOINT + 252,

    // Set authentication type for authenticated TLS for proxy
    CURLOPT_PROXY_TLSAUTH_TYPE = CURLOPTTYPE_STRINGPOINT + 253,

    // name of the file keeping your private SSL-certificate for proxy
    CURLOPT_PROXY_SSLCERT = CURLOPTTYPE_STRINGPOINT + 254,

    // type of the file keeping your SSL-certificate ("DER", "PEM", "ENG") for
    // proxy
    CURLOPT_PROXY_SSLCERTTYPE = CURLOPTTYPE_STRINGPOINT + 255,

    // name of the file keeping your private SSL-key for proxy
    CURLOPT_PROXY_SSLKEY = CURLOPTTYPE_STRINGPOINT + 256,

    // type of the file keeping your private SSL-key ("DER", "PEM", "ENG") for
    // proxy
    CURLOPT_PROXY_SSLKEYTYPE = CURLOPTTYPE_STRINGPOINT + 257,

    // password for the SSL private key for proxy
    CURLOPT_PROXY_KEYPASSWD = CURLOPTTYPE_STRINGPOINT + 258,

    // Specify which SSL ciphers to use for proxy
    CURLOPT_PROXY_SSL_CIPHER_LIST = CURLOPTTYPE_STRINGPOINT + 259,

    // CRL file for proxy
    CURLOPT_PROXY_CRLFILE = CURLOPTTYPE_STRINGPOINT + 260,

    // Name of pre proxy to use.
    CURLOPT_PRE_PROXY = CURLOPTTYPE_STRINGPOINT + 262,

    // The public key in DER form used to validate the proxy public key
    // this option is used only if PROXY_SSL_VERIFYPEER is true
    CURLOPT_PROXY_PINNEDPUBLICKEY = CURLOPTTYPE_STRINGPOINT + 263,

    // Path to an abstract Unix domain socket
    CURLOPT_ABSTRACT_UNIX_SOCKET = CURLOPTTYPE_STRINGPOINT + 264,

    // The request target, instead of extracted from the URL
    CURLOPT_REQUEST_TARGET = CURLOPTTYPE_STRINGPOINT + 266
  );

  TCurlSlistOption = (
    // This points to a linked list of headers, struct curl_slist kind. This
    // list is also used for RTSP (in spite of its name)
    CURLOPT_HTTPHEADER = CURLOPTTYPE_OBJECTPOINT + 23,

    // send linked-list of QUOTE commands
    CURLOPT_QUOTE = CURLOPTTYPE_OBJECTPOINT + 28,

    // send linked-list of post-transfer QUOTE commands
    CURLOPT_POSTQUOTE = CURLOPTTYPE_OBJECTPOINT + 39,

    // This points to a linked list of telnet options
    CURLOPT_TELNETOPTIONS = CURLOPTTYPE_OBJECTPOINT + 70,

    // send linked-list of pre-transfer QUOTE commands
    CURLOPT_PREQUOTE = CURLOPTTYPE_OBJECTPOINT + 93,

    // Set aliases for HTTP 200 in the HTTP Response header
    CURLOPT_HTTP200ALIASES = CURLOPTTYPE_OBJECTPOINT + 104,

    // set the SMTP mail receiver(s)
    CURLOPT_MAIL_RCPT = CURLOPTTYPE_OBJECTPOINT + 187,

    // send linked-list of name:port:address sets
    CURLOPT_RESOLVE = CURLOPTTYPE_OBJECTPOINT + 203,

    // This points to a linked list of headers used for proxy requests only,
    // struct curl_slist kind
    CURLOPT_PROXYHEADER = CURLOPTTYPE_OBJECTPOINT + 228,

    // Linked-list of host:port:connect-to-host:connect-to-port,
    // overrides the URL's host:port (only for the network layer)
    CURLOPT_CONNECT_TO = CURLOPTTYPE_OBJECTPOINT + 243
  );

  TCurlPostOption = (
    // This points to a linked list of post entries, struct curl_httppost
    CURLOPT_HTTPPOST = CURLOPTTYPE_OBJECTPOINT + 24
  );

  TCurlMimeOption = (
    // Post MIME data.
    CURLOPT_MIMEPOST = CURLOPTTYPE_OBJECTPOINT + 269
  );

  TCurlOption = (
    // This is the FILE * or void * the regular output should be written to.
    CURLOPT_WRITEDATA = CURLOPTTYPE_OBJECTPOINT + 1,

    // Specified file stream to upload from (use as input):
    CURLOPT_READDATA = CURLOPTTYPE_OBJECTPOINT + 9,

    // Buffer to receive error messages in, must be at least CURL_ERROR_SIZE
    // bytes big. If this is not used, error messages go to stderr instead:
    CURLOPT_ERRORBUFFER = CURLOPTTYPE_OBJECTPOINT + 10,

    // Function that will be called to store the output (instead of fwrite). The
    // parameters will use fwrite() syntax, make sure to follow them.
    CURLOPT_WRITEFUNCTION = CURLOPTTYPE_FUNCTIONPOINT + 11,

    // Function that will be called to read the input (instead of fread). The
    // parameters will use fread() syntax, make sure to follow them.
    CURLOPT_READFUNCTION = CURLOPTTYPE_FUNCTIONPOINT + 12,

    // POST static input fields.
    CURLOPT_POSTFIELDS = CURLOPTTYPE_OBJECTPOINT + 15,

    // Identified as slist
    // CURLOPT_HTTPHEADER = CURLOPTTYPE_OBJECTPOINT + 23,

    // Identified as httppost
    //CURLOPT_HTTPPOST = CURLOPTTYPE_OBJECTPOINT + 24,

    // Identified as slist
    //CURLOPT_QUOTE = CURLOPTTYPE_OBJECTPOINT + 28,

    // send FILE * or void * to store headers to, if you use a callback it
    // is simply passed to the callback unmodified
    CURLOPT_HEADERDATA = CURLOPTTYPE_OBJECTPOINT + 29,

    // 35 = OBSOLETE

    // Pass a FILE * as parameter. Tell libcurl to use this stream instead
    // of stderr when showing the progress meter and displaying
    // CURLOPT_VERBOSE data.
    CURLOPT_STDERR = CURLOPTTYPE_OBJECTPOINT + 37,

    // 38 is not used

    // Identified as slist
    //CURLOPT_POSTQUOTE = CURLOPTTYPE_OBJECTPOINT + 39,

    // 55 = OBSOLETE

    // DEPRECATED
    // Function that will be called instead of the internal progress display
    // function. This function should be defined as the curl_progress_callback
    // prototype defines.
    // CURLOPT_PROGRESSFUNCTION = CURLOPTTYPE_FUNCTIONPOINT + 56,

    // Data passed to the CURLOPT_PROGRESSFUNCTION and CURLOPT_XFERINFOFUNCTION
    // callbacks
    CURLOPT_PROGRESSDATA = CURLOPTTYPE_OBJECTPOINT + 57,
    CURLOPT_XFERINFODATA = CURLOPT_PROGRESSDATA,

    // 66 = OBSOLETE
    // 67 = OBSOLETE
    // 73 = OBSOLETE

    // Identified as slist
    //CURLOPT_TELNETOPTIONS = CURLOPTTYPE_OBJECTPOINT + 70,

    // Function that will be called to store headers (instead of fwrite). The
    // parameters will use fwrite() syntax, make sure to follow them.
    CURLOPT_HEADERFUNCTION = CURLOPTTYPE_FUNCTIONPOINT + 79,

    // Identified as slist
    //CURLOPT_PREQUOTE = CURLOPTTYPE_OBJECTPOINT + 93,

    // set the debug function
    CURLOPT_DEBUGFUNCTION = CURLOPTTYPE_FUNCTIONPOINT + 94,

    // set the data for the debug function
    CURLOPT_DEBUGDATA = CURLOPTTYPE_OBJECTPOINT + 95,

    // Provide a CURLShare for mutexing non-ts data
    CURLOPT_SHARE = CURLOPTTYPE_OBJECTPOINT + 100,

    // Set pointer to private data
    CURLOPT_PRIVATE = CURLOPTTYPE_OBJECTPOINT + 103,

    // Identified as slist
    //CURLOPT_HTTP200ALIASES = CURLOPT_OBJECTPOINT + 104,

    // Set the ssl context callback function, currently only for OpenSSL ssl_ctx
    // in second argument. The function must be matching the
    // curl_ssl_ctx_callback proto.
    CURLOPT_SSL_CTX_FUNCTION = CURLOPTTYPE_FUNCTIONPOINT + 108,

    // Set the userdata for the ssl context callback function's third
    // argument
    CURLOPT_SSL_CTX_DATA = CURLOPTTYPE_OBJECTPOINT + 109,

    // 122 OBSOLETE, used in 7.12.3. Gone in 7.13.0
    // 123 OBSOLETE. Gone in 7.16.0
    // 124 OBSOLETE, used in 7.12.3. Gone in 7.13.0
    // 125 OBSOLETE, used in 7.12.3. Gone in 7.13.0
    // 126 OBSOLETE, used in 7.12.3. Gone in 7.13.0
    // 127 OBSOLETE. Gone in 7.16.0
    // 128 OBSOLETE. Gone in 7.16.0

    CURLOPT_IOCTLFUNCTION = CURLOPTTYPE_FUNCTIONPOINT + 130,
    CURLOPT_IOCTLDATA = CURLOPTTYPE_OBJECTPOINT + 131,

    // 132 OBSOLETE. Gone in 7.16.0
    // 133 OBSOLETE. Gone in 7.16.0

    // Function that will be called to convert from the
    // network encoding (instead of using the iconv calls in libcurl)
    CURLOPT_CONV_FROM_NETWORK_FUNCTION = CURLOPTTYPE_FUNCTIONPOINT + 142,

    // Function that will be called to convert to the
    // network encoding (instead of using the iconv calls in libcurl)
    CURLOPT_CONV_TO_NETWORK_FUNCTION = CURLOPTTYPE_FUNCTIONPOINT + 143,

    // Function that will be called to convert from UTF8
    // (instead of using the iconv calls in libcurl)
    // Note that this is used only for SSL certificate processing
    CURLOPT_CONV_FROM_UTF8_FUNCTION = CURLOPTTYPE_FUNCTIONPOINT + 144,

    // callback function for setting socket options
    CURLOPT_SOCKOPTFUNCTION = CURLOPTTYPE_FUNCTIONPOINT + 148,
    CURLOPT_SOCKOPTDATA = CURLOPTTYPE_OBJECTPOINT + 149,

    // Callback function for opening socket (instead of socket(2)). Optionally,
    // callback is able change the address or refuse to connect returning
    // CURL_SOCKET_BAD.  The callback should have type
    // curl_opensocket_callback
    CURLOPT_OPENSOCKETFUNCTION = CURLOPTTYPE_FUNCTIONPOINT + 163,
    CURLOPT_OPENSOCKETDATA = CURLOPTTYPE_OBJECTPOINT + 164,

    // Callback function for seeking in the input stream
    CURLOPT_SEEKFUNCTION = CURLOPTTYPE_FUNCTIONPOINT + 167,
    CURLOPT_SEEKDATA = CURLOPTTYPE_OBJECTPOINT + 168,

    // set the SSH host key callback, must point to a curl_sshkeycallback
    // function
    CURLOPT_SSH_KEYFUNCTION = CURLOPTTYPE_FUNCTIONPOINT + 184,

    // set the SSH host key callback custom pointer
    CURLOPT_SSH_KEYDATA = CURLOPTTYPE_OBJECTPOINT + 185,

    // Identified as slist
    //CURLOPT_MAIL_RCPT = CURLOPTTYPE_OBJECTPOINT + 187,

    // The stream to pass to INTERLEAVEFUNCTION.
    CURLOPT_INTERLEAVEDATA = CURLOPTTYPE_OBJECTPOINT + 195,

    // Let the application define a custom write method for RTP data
    CURLOPT_INTERLEAVEFUNCTION = CURLOPTTYPE_FUNCTIONPOINT + 196,

    // Directory matching callback called before downloading of an
    // individual file (chunk) started
    CURLOPT_CHUNK_BGN_FUNCTION = CURLOPTTYPE_FUNCTIONPOINT + 198,

    // Directory matching callback called after the file (chunk)
    // was downloaded, or skipped
    CURLOPT_CHUNK_END_FUNCTION = CURLOPTTYPE_FUNCTIONPOINT + 199,

    // Change match (fnmatch-like) callback for wildcard matching
    CURLOPT_FNMATCH_FUNCTION = CURLOPTTYPE_FUNCTIONPOINT + 200,

    // Let the application define custom chunk data pointer
    CURLOPT_CHUNK_DATA = CURLOPTTYPE_OBJECTPOINT + 201,

    // FNMATCH_FUNCTION user pointer
    CURLOPT_FNMATCH_DATA = CURLOPTTYPE_OBJECTPOINT + 202,

    // Identified as slist
    //CURLOPT_RESOLVE = CURLOPTTYPE_OBJECTPOINT + 203,

    // Callback function for closing socket (instead of close(2)). The callback
    // should have type curl_closesocket_callback
    CURLOPT_CLOSESOCKETFUNCTION = CURLOPTTYPE_FUNCTIONPOINT + 208,
    CURLOPT_CLOSESOCKETDATA = CURLOPTTYPE_OBJECTPOINT + 209,

    // Function that will be called instead of the internal progress display
    // function. This function should be defined as the curl_xferinfo_callback
    // prototype defines. (Deprecates CURLOPT_PROGRESSFUNCTION)
    CURLOPT_XFERINFOFUNCTION = CURLOPTTYPE_FUNCTIONPOINT + 219,

    // Identified as slist
    //CURLOPT_PROXYHEADER = CURLOPTTYPE_OBJECTPOINT + 228,

    // Set stream dependency on another CURL handle
    CURLOPT_STREAM_DEPENDS = CURLOPTTYPE_OBJECTPOINT + 240,

    // Set E-xclusive stream dependency on another CURL handle
    CURLOPT_STREAM_DEPENDS_E = CURLOPTTYPE_OBJECTPOINT + 241

    // Identified as slist
    //CURLOPT_CONNECT_TO = CURLOPTTYPE_OBJECTPOINT + 243,

    // Identified as MIMEdata
    //CURLOPT_MIMEPOST = CURLOPTTYPE_OBJECTPOINT + 269
  );


type
  // Below here follows defines for the CURLOPT_IPRESOLVE option. If a host
  //   name resolves addresses using more than one IP protocol version, this
  //   option might be handy to force libcurl to use a specific IP version.
  TCurlIpResolve = (
    CURL_IPRESOLVE_WHATEVER, // default, resolves addresses to all IP
                              //       versions that your system allows
    CURL_IPRESOLVE_V4,        // resolve to IPv4 addresses
    CURL_IPRESOLVE_V6         // resolve to IPv6 addresses
  );

const
  // three convenient "aliases" that follow the name scheme better
  CURLOPT_RTSPHEADER = CURLOPT_HTTPHEADER;

type
  // These enums are for use with the CURLOPT_HTTP_VERSION option.
  TCurlHttpVersion = (
    CURL_HTTP_VERSION_NONE, // setting this means we don't care, and that we'd
                            // like the library to choose the best possible
                            // for us!
    CURL_HTTP_VERSION_1_0,  // please use HTTP 1.0 in the request
    CURL_HTTP_VERSION_1_1,  // please use HTTP 1.1 in the request
    CURL_HTTP_VERSION_2_0,  // please use HTTP 2.0 in the request
    CURL_HTTP_VERSION_2 = CURL_HTTP_VERSION_2_0
  );

  // Public API enums for RTSP requests
  TCurlRtspSeq = (
    CURL_RTSPREQ_NONE,
    CURL_RTSPREQ_OPTIONS,
    CURL_RTSPREQ_DESCRIBE,
    CURL_RTSPREQ_ANNOUNCE,
    CURL_RTSPREQ_SETUP,
    CURL_RTSPREQ_PLAY,
    CURL_RTSPREQ_PAUSE,
    CURL_RTSPREQ_TEARDOWN,
    CURL_RTSPREQ_GET_PARAMETER,
    CURL_RTSPREQ_SET_PARAMETER,
    CURL_RTSPREQ_RECORD,
    CURL_RTSPREQ_RECEIVE
  );

  // These enums are for use with the CURLOPT_NETRC option.
  TCurlNetrc = (
    CURL_NETRC_IGNORED,  // The .netrc will never be read.
                         // This is the default.
    CURL_NETRC_OPTIONAL, // A user:password in the URL will be preferred
                         // to one in the .netrc.
    CURL_NETRC_REQUIRED  // A user:password in the URL will be ignored.
  );                     // Unless one is set programmatically, the .netrc
                         // will be queried.

  TCurlSslVersion = (
    CURL_SSLVERSION_DEFAULT,
    CURL_SSLVERSION_TLSv1,
    CURL_SSLVERSION_SSLv2,
    CURL_SSLVERSION_SSLv3,
    CURL_SSLVERSION_TLSv1_0,
    CURL_SSLVERSION_TLSv1_1,
    CURL_SSLVERSION_TLSv1_2 );

  // Unused right now
  //TCurlTlsAuth = (
  //  CURL_TLSAUTH_NONE,
  //  CURL_TLSAUTH_SRP );

const
  // symbols to use with CURLOPT_POSTREDIR.
  //   CURL_REDIR_POST_301, CURL_REDIR_POST_302 and CURL_REDIR_POST_303
  //   can be bitwise ORed so that CURL_REDIR_POST_301 | CURL_REDIR_POST_302
  //   | CURL_REDIR_POST_303 == CURL_REDIR_POST_ALL
  CURL_REDIR_GET_ALL  = 0;
  CURL_REDIR_POST_301 = 1;
  CURL_REDIR_POST_302 = 2;
  CURL_REDIR_POST_303 = 4;
  CURL_REDIR_POST_ALL = CURL_REDIR_POST_301 or CURL_REDIR_POST_302 or CURL_REDIR_POST_303;

  CURL_TIMECOND_NONE = 0;
  CURL_TIMECOND_IFMODSINCE = 1;
  CURL_TIMECOND_IFUNMODSINCE = 2;
  CURL_TIMECOND_LASTMOD = 3;
  CURL_TIMECOND_LAST = 4;

// curl_strequal() and curl_strnequal() are subject for removal in a future
//   libcurl, see lib/README.curlx for details
function curl_strequal(s1, s2 : PAnsiChar) : integer;  cdecl;  external 'libcurl.dll';
function curl_strnequal(s1, s2 : PAnsiChar; n : NativeUInt) : integer;  cdecl;  external 'libcurl.dll';

// Mime/form handling support.
type
  TCurlMimeInner = record end;
  TCurlMimePartInner = record end;
  HCurlMime = ^TCurlMimeInner;
  HCurlMimePart = ^TCurlMimePartInner;


// Note for Delphi users:
// These options are new, and are not wrapped right now.
// Delphi does not compile them into EXE when they are unused →
//   no need to guard with compiler directives.

// NAME curl_mime_init()
//
// DESCRIPTION
//
// Create a mime context and return its handle. The easy parameter is the
// target handle.
//
function curl_mime_init(easy : HCurl) : HCurlMime;  cdecl;  external 'libcurl.dll';

// NAME curl_mime_free()
//
// DESCRIPTION
//
// release a mime handle and its substructures.
//
procedure curl_mime_free(mime : HCurlMime);
      cdecl;  external 'libcurl.dll';

// NAME curl_mime_addpart()
//
// DESCRIPTION
//
// Append a new empty part to the given mime context and return a handle to
// the created part.
//
function curl_mime_addpart(mime : HCurlMime) : HCurlMimePart;
      cdecl;  external 'libcurl.dll';

// NAME curl_mime_name()
//
// DESCRIPTION
//
// Set mime/form part name.
//
function curl_mime_name(part : HCurlMimePart; name : PAnsiChar) : TCurlCode;
      cdecl;  external 'libcurl.dll';

// NAME curl_mime_filename()
//
// DESCRIPTION
//
// Set mime part remote file name.
//
function curl_mime_filename(
      Part : HCurlMimePart; filename : PAnsiChar) : TCurlCode;
      cdecl;  external 'libcurl.dll';

//
// NAME curl_mime_type()
//
// DESCRIPTION
//
// Set mime part type.
//
function curl_mime_type(part : HCurlMime; mimetype : PAnsiChar) : TCurlCode;
      cdecl;  external 'libcurl.dll';

// NAME curl_mime_encoder()
//
// DESCRIPTION
//
// Set mime data transfer encoder.
//
function curl_mime_encoder(
      part : HCurlMimePart; encoding : PAnsiChar) : TCurlCode;
      cdecl;  external 'libcurl.dll';

// NAME curl_mime_data()
//
// DESCRIPTION
//
// Set mime part data source from memory data,
//
function curl_mime_data(
      part : HCurlMimePart; data : Pointer; datasize : NativeUint) : TCurlCode;
      cdecl;  external 'libcurl.dll';

// NAME curl_mime_filedata()
//
// DESCRIPTION
//
// Set mime part data source from named file.
//
function curl_mime_filedata(
      part : HCurlMimePart; filename : PAnsiChar) : TCurlCode;
      cdecl;  external 'libcurl.dll';

// NAME curl_mime_data_cb()
//
// DESCRIPTION
//
// Set mime part data source from callback function.
//
function curl_mime_data_cb(
      part : HCurlMimePart;
      datasize : TCurlOff;
      readfunc : EvCurlRead;
      seekfunc : EvCurlSeek;
      freefunc : EvCurlFree;
      arg : pointer) : TCurlCode;
      cdecl;  external 'libcurl.dll';

// NAME curl_mime_subparts()
//
// DESCRIPTION
//
// Set mime part data source from subparts.
//
function curl_mime_subparts(
      part : HCurlMimePart; subparts : HCurlMime) : TCurlCode;
      cdecl;  external 'libcurl.dll';

// NAME curl_mime_headers()
//
// DESCRIPTION
//
// Set mime part headers.
//
function curl_mime_headers(
      part : HCurlMimePart;
      headers : PCurlSList;
      take_ownership : integer) : TCurlCode;
      cdecl;  external 'libcurl.dll';


type
  TCurlFormOption = (
    CURLFORM_NOTHING,        //********* the first one is unused ************

    CURLFORM_COPYNAME,
    CURLFORM_PTRNAME,
    CURLFORM_NAMELENGTH,
    CURLFORM_COPYCONTENTS,
    CURLFORM_PTRCONTENTS,
    CURLFORM_CONTENTSLENGTH,
    CURLFORM_FILECONTENT,
    CURLFORM_ARRAY,
    CURLFORM_OBSOLETE,
    CURLFORM_FILE,

    CURLFORM_BUFFER,
    CURLFORM_BUFFERPTR,
    CURLFORM_BUFFERLENGTH,

    CURLFORM_CONTENTTYPE,
    CURLFORM_CONTENTHEADER,
    CURLFORM_FILENAME,
    CURLFORM_END,
    CURLFORM_OBSOLETE2,

    CURLFORM_STREAM,
    CURLFORM_CONTENTLEN   // added in 7.46.0, provide a curl_off_t length
                          // In x86 programs use in curl_formadd_initial only!
  );


  // structure to be used as parameter for CURLFORM_ARRAY
  TCurlForms = record
      Option : TCurlFormOption;
      Value : PAnsiChar;
  end;
  PCurlForms = ^TCurlForms;

  // use this for multipart formpost building
  // Returns code for curl_formadd()
  //
  // Returns:
  // CURL_FORMADD_OK             on success
  // CURL_FORMADD_MEMORY         if the allocation of a FormInfo struct failed
  // CURL_FORMADD_OPTION_TWICE   if one option is given twice for one Form
  // CURL_FORMADD_NULL           if a null pointer was given for a char
  // CURL_FORMADD_UNKNOWN_OPTION if an unknown option was used
  // CURL_FORMADD_INCOMPLETE     if the some FormInfo is not complete (or error)
  // CURL_FORMADD_MEMORY         if a curl_httppost struct cannot be allocated
  // CURL_FORMADD_MEMORY         if some allocation for string copying failed.
  // CURL_FORMADD_ILLEGAL_ARRAY  if an illegal option is used in an array
  //
  //*************************************************************************
  TCurlFormCode = (
    CURL_FORMADD_OK, // first, no error
    CURL_FORMADD_MEMORY,
    CURL_FORMADD_OPTION_TWICE,
    CURL_FORMADD_NULL,
    CURL_FORMADD_UNKNOWN_OPTION,
    CURL_FORMADD_INCOMPLETE,
    CURL_FORMADD_ILLEGAL_ARRAY,
    CURL_FORMADD_DISABLED // libcurl was built with this disabled
  );

//
// NAME curl_formadd()
//
// DESCRIPTION
//
// Pretty advanced function for building multi-part formposts. Each invoke
// adds one part that together construct a full post. Then use
// CURLOPT_HTTPPOST to send it off to libcurl.
//
// Note for Delphi users: we’re limited to 10 arguments, just because
//   I’m lazy to write more overloads :)
//   If you REALLY know what to do and aren’t afraid of varargs,
//   you can use curl_formadd_initial.
//
function curl_formadd_initial(
        var httppost, last_post : PCurlHttpPost) : TCurlFormCode;
        varargs; cdecl; external 'libcurl.dll' name 'curl_formadd';

function curl_formadd(
        var httppost, last_post : PCurlHttpPost;
        option1 : TCurlFormOption; data1 : PAnsiChar;
        optend : TCurlFormOption = CURLFORM_END) : TCurlFormCode;
        overload; inline;

function curl_formadd(
        var httppost, last_post : PCurlHttpPost;
        option1 : TCurlFormOption; data1 : PAnsiChar;
        option2 : TCurlFormOption; data2 : PAnsiChar;
        optend : TCurlFormOption = CURLFORM_END) : TCurlFormCode;
        overload;  inline;

function curl_formadd(
        var httppost, last_post : PCurlHttpPost;
        option1 : TCurlFormOption; data1 : PAnsiChar;
        option2 : TCurlFormOption; data2 : PAnsiChar;
        option3 : TCurlFormOption; data3 : PAnsiChar;
        optend : TCurlFormOption = CURLFORM_END) : TCurlFormCode;
        overload; inline;

function curl_formadd(
        var httppost, last_post : PCurlHttpPost;
        option1 : TCurlFormOption; data1 : PAnsiChar;
        option2 : TCurlFormOption; data2 : PAnsiChar;
        option3 : TCurlFormOption; data3 : PAnsiChar;
        option4 : TCurlFormOption; data4 : PAnsiChar;
        optend : TCurlFormOption = CURLFORM_END) : TCurlFormCode;
        overload; inline;

function curl_formadd(
        var httppost, last_post : PCurlHttpPost;
        option1 : TCurlFormOption; data1 : PAnsiChar;
        option2 : TCurlFormOption; data2 : PAnsiChar;
        option3 : TCurlFormOption; data3 : PAnsiChar;
        option4 : TCurlFormOption; data4 : PAnsiChar;
        option5 : TCurlFormOption; data5 : PAnsiChar;
        optend : TCurlFormOption = CURLFORM_END) : TCurlFormCode;
        overload; inline;

function curl_formadd(
        var httppost, last_post : PCurlHttpPost;
        option1 : TCurlFormOption; data1 : PAnsiChar;
        option2 : TCurlFormOption; data2 : PAnsiChar;
        option3 : TCurlFormOption; data3 : PAnsiChar;
        option4 : TCurlFormOption; data4 : PAnsiChar;
        option5 : TCurlFormOption; data5 : PAnsiChar;
        option6 : TCurlFormOption; data6 : PAnsiChar;
        optend : TCurlFormOption = CURLFORM_END) : TCurlFormCode;
        overload; inline;

function curl_formadd(
        var httppost, last_post : PCurlHttpPost;
        option1 : TCurlFormOption; data1 : PAnsiChar;
        option2 : TCurlFormOption; data2 : PAnsiChar;
        option3 : TCurlFormOption; data3 : PAnsiChar;
        option4 : TCurlFormOption; data4 : PAnsiChar;
        option5 : TCurlFormOption; data5 : PAnsiChar;
        option6 : TCurlFormOption; data6 : PAnsiChar;
        option7 : TCurlFormOption; data7 : PAnsiChar;
        optend : TCurlFormOption = CURLFORM_END) : TCurlFormCode;
        overload; inline;

function curl_formadd(
        var httppost, last_post : PCurlHttpPost;
        option1 : TCurlFormOption; data1 : PAnsiChar;
        option2 : TCurlFormOption; data2 : PAnsiChar;
        option3 : TCurlFormOption; data3 : PAnsiChar;
        option4 : TCurlFormOption; data4 : PAnsiChar;
        option5 : TCurlFormOption; data5 : PAnsiChar;
        option6 : TCurlFormOption; data6 : PAnsiChar;
        option7 : TCurlFormOption; data7 : PAnsiChar;
        option8 : TCurlFormOption; data8 : PAnsiChar;
        optend : TCurlFormOption = CURLFORM_END) : TCurlFormCode;
        overload; inline;

function curl_formadd(
        var httppost, last_post : PCurlHttpPost;
        option1 : TCurlFormOption; data1 : PAnsiChar;
        option2 : TCurlFormOption; data2 : PAnsiChar;
        option3 : TCurlFormOption; data3 : PAnsiChar;
        option4 : TCurlFormOption; data4 : PAnsiChar;
        option5 : TCurlFormOption; data5 : PAnsiChar;
        option6 : TCurlFormOption; data6 : PAnsiChar;
        option7 : TCurlFormOption; data7 : PAnsiChar;
        option8 : TCurlFormOption; data8 : PAnsiChar;
        option9 : TCurlFormOption; data9 : PAnsiChar;
        optend : TCurlFormOption = CURLFORM_END) : TCurlFormCode;
        overload; inline;

function curl_formadd(
        var httppost, last_post : PCurlHttpPost;
        option1 : TCurlFormOption; data1 : PAnsiChar;
        option2 : TCurlFormOption; data2 : PAnsiChar;
        option3 : TCurlFormOption; data3 : PAnsiChar;
        option4 : TCurlFormOption; data4 : PAnsiChar;
        option5 : TCurlFormOption; data5 : PAnsiChar;
        option6 : TCurlFormOption; data6 : PAnsiChar;
        option7 : TCurlFormOption; data7 : PAnsiChar;
        option8 : TCurlFormOption; data8 : PAnsiChar;
        option9 : TCurlFormOption; data9 : PAnsiChar;
        option10 : TCurlFormOption; data10 : PAnsiChar;
        optend : TCurlFormOption = CURLFORM_END) : TCurlFormCode;
        overload; inline;


// callback function for curl_formget()
// The void *arg pointer will be the one passed as second argument to
//   curl_formget().
// The character buffer passed to it must not be freed.
// Should return the buffer length passed to it as the argument "len" on
//   success.
//
type
  EvCurlFormGet = function (
        arg : pointer; buf : PAnsiChar; len : NativeUint) : NativeUint;  cdecl;


// NAME curl_formget()
//
// DESCRIPTION
//
// Serialize a curl_httppost struct built with curl_formadd().
// Accepts a void pointer as second argument which will be passed to
// the curl_formget_callback function.
// Returns 0 on success.
function curl_formget(
        form : PCurlHttpPost;
        arg : pointer;
        append : EvCurlFormGet) : integer;
          cdecl;  external 'libcurl.dll';

// NAME curl_formfree()
//
// DESCRIPTION
//
// Free a multipart formpost previously built with curl_formadd().
procedure curl_formfree(form : PCurlHttpPost);
          cdecl;  external 'libcurl.dll';

// NAME curl_getenv()
//
// DESCRIPTION
//
// Returns a malloc()'ed string that MUST be curl_free()ed after usage is
// complete. DEPRECATED - see lib/README.curlx
function curl_getenv(variable : PAnsiChar) : PAnsiChar;
          cdecl;  external 'libcurl.dll';

// NAME curl_version()
//
// DESCRIPTION
//
// Returns a static ascii string of the libcurl version.
function curl_version : PAnsiChar;
          cdecl;  external 'libcurl.dll';

// NAME curl_easy_escape()
//
// DESCRIPTION
//
// Escapes URL strings (converts all letters consider illegal in URLs to their
// %XX versions). This function returns a new allocated string or NULL if an
// error occurred.
function curl_easy_escape(
        handle : HCurl;
        str : PAnsiChar;
        length : integer) : PAnsiChar;
          cdecl;  external 'libcurl.dll';

// the previous version:
function curl_escape(
        str : PAnsiChar;
        length : integer) : PAnsiChar;
          cdecl;  external 'libcurl.dll';


// NAME curl_easy_unescape()
//
// DESCRIPTION
//
// Unescapes URL encoding in strings (converts all %XX codes to their 8bit
// versions). This function returns a new allocated string or NULL if an error
// occurred.
// Conversion Note: On non-ASCII platforms the ASCII %XX codes are
// converted into the host encoding.
//
function curl_easy_unescape(
        handle : HCurl;
        str : PAnsiChar;
        length : integer;
        var outlength : integer) : PAnsiChar;
          cdecl;  external 'libcurl.dll';

// the previous version
function curl_unescape(
        str : PAnsiChar;
        length : integer) : PAnsiChar;
          cdecl;  external 'libcurl.dll';

// NAME curl_free()
//
// DESCRIPTION
//
// Provided for de-allocation in the same translation unit that did the
// allocation. Added in libcurl 7.10
//
procedure curl_free(p : pointer);
          cdecl;  external 'libcurl.dll';

// NAME curl_global_init()
//
// DESCRIPTION
//
// curl_global_init() should be invoked exactly once for each application that
// uses libcurl and before any call of other libcurl functions.
//
// This function is not thread-safe!
//
function curl_global_init(flags : longint) : TCurlCode;
          cdecl;  external 'libcurl.dll';

// NAME curl_global_init_mem()
//
// DESCRIPTION
//
// curl_global_init() or curl_global_init_mem() should be invoked exactly once
// for each application that uses libcurl.  This function can be used to
// initialize libcurl and set user defined memory management callback
// functions.  Users can implement memory management routines to check for
// memory leaks, check for mis-use of the curl library etc.  User registered
// callback routines with be invoked by this library instead of the system
// memory management routines like malloc, free etc.
function curl_global_init_mem(
        flags : longint;
        m : EvCurlMalloc;
        f : EvCurlFree;
        r : EvCurlRealloc;
        s : EvCurlStrDup;
        c : EvCurlCalloc) : TCurlCode;
          cdecl;  external 'libcurl.dll';

// NAME curl_global_cleanup()
//
// DESCRIPTION
//
// curl_global_cleanup() should be invoked exactly once for each application
// that uses libcurl
//
procedure curl_global_cleanup;
          cdecl;  external 'libcurl.dll';

// NAME curl_slist_append()
//
// DESCRIPTION
//
// Appends a string to a linked list. If no list exists, it will be created
// first. Returns the new list, after appending.
//
function curl_slist_append(
      list : PCurlSList; data : PAnsiChar) : PCurlSList;
          cdecl;  external 'libcurl.dll';

// NAME curl_slist_free_all()
//
// DESCRIPTION
//
// free a previously built curl_slist.
//
procedure curl_slist_free_all(list : PCurlSList);
          cdecl;  external 'libcurl.dll';

// NAME curl_getdate()
//
// DESCRIPTION
//
// Returns the time, in seconds since 1 Jan 1970 of the time string given in
// the first argument. The time argument in the second parameter is unused
// and should be set to NULL.
//
function curl_getdate(
        p : PAnsiChar;
        unused : TUnixTime = 0) : TUnixTime;
          cdecl;  external 'libcurl.dll';

// info about the certificate chain, only for OpenSSL builds. Asked
//   for with CURLOPT_CERTINFO / CURLINFO_CERTINFO
type
  TCurlCertInfo = record
    NumOfCert : integer;  // number of certificates with information
    CertInfo : PPCurlSlist; // for each index in this array, there's a
  end;                      //    linked list with textual information in the
                            //    format "name: value"

// enum for the different supported SSL backends
  TCurlSslBackend = (
    CURLSSLBACKEND_NONE = 0,
    CURLSSLBACKEND_OPENSSL = 1,
    CURLSSLBACKEND_GNUTLS = 2,
    CURLSSLBACKEND_NSS = 3,
    CURLSSLBACKEND_OBSOLETE4 = 4,  // Was QSOSSL.
    CURLSSLBACKEND_GSKIT = 5,
    CURLSSLBACKEND_POLARSSL = 6,
    CURLSSLBACKEND_CYASSL = 7,
    CURLSSLBACKEND_SCHANNEL = 8,
    CURLSSLBACKEND_DARWINSSL = 9,
    CURLSSLBACKEND_AXTLS = 10
  );

// Information about the SSL library used and the respective internal SSL
//   handle, which can be used to obtain further information regarding the
//   connection. Asked for with CURLINFO_TLS_SESSION.
  TCurlTlsSessionInfo = record
    backend : TCurlSslBackend;
    internals : pointer;
  end;

const
  CURLINFO_STRING   = $100000;
  CURLINFO_LONG     = $200000;
  CURLINFO_DOUBLE   = $300000;
  CURLINFO_SLIST    = $400000;
  CURLINFO_PTR      = CURLINFO_SLIST;
  CURLINFO_SOCKET   = $500000;
  CURLINFO_OFF_T    = $600000;
  CURLINFO_MASK     = $0fffff;
  CURLINFO_TYPEMASK = $f00000;

type
  TCurlLongInfo = (
    CURLINFO_RESPONSE_CODE    = CURLINFO_LONG   + 2,
    CURLINFO_HEADER_SIZE      = CURLINFO_LONG   + 11,
    CURLINFO_REQUEST_SIZE     = CURLINFO_LONG   + 12,
    CURLINFO_SSL_VERIFYRESULT = CURLINFO_LONG   + 13,
    CURLINFO_FILETIME         = CURLINFO_LONG   + 14,
    CURLINFO_REDIRECT_COUNT   = CURLINFO_LONG   + 20,
    CURLINFO_HTTP_CONNECTCODE = CURLINFO_LONG   + 22,
    CURLINFO_HTTPAUTH_AVAIL   = CURLINFO_LONG   + 23,
    CURLINFO_PROXYAUTH_AVAIL  = CURLINFO_LONG   + 24,
    CURLINFO_OS_ERRNO         = CURLINFO_LONG   + 25,
    CURLINFO_NUM_CONNECTS     = CURLINFO_LONG   + 26,
    CURLINFO_LASTSOCKET       = CURLINFO_LONG   + 29,
    CURLINFO_CONDITION_UNMET  = CURLINFO_LONG   + 35,
    CURLINFO_RTSP_CLIENT_CSEQ = CURLINFO_LONG   + 37,
    CURLINFO_RTSP_SERVER_CSEQ = CURLINFO_LONG   + 38,
    CURLINFO_RTSP_CSEQ_RECV   = CURLINFO_LONG   + 39,
    CURLINFO_PRIMARY_PORT     = CURLINFO_LONG   + 40,
    CURLINFO_LOCAL_PORT       = CURLINFO_LONG   + 42,
    CURLINFO_HTTP_CODE = CURLINFO_RESPONSE_CODE,
    CURLINFO_HTTP_VERSION     = CURLINFO_LONG   + 46,
    CURLINFO_PROXY_SSL_VERIFYRESULT = CURLINFO_LONG + 47,
    CURLINFO_PROTOCOL         = CURLINFO_LONG   + 48
  );

  TCurlDoubleInfo = (
    CURLINFO_TOTAL_TIME       = CURLINFO_DOUBLE + 3,
    CURLINFO_NAMELOOKUP_TIME  = CURLINFO_DOUBLE + 4,
    CURLINFO_CONNECT_TIME     = CURLINFO_DOUBLE + 5,
    CURLINFO_PRETRANSFER_TIME = CURLINFO_DOUBLE + 6,
    CURLINFO_STARTTRANSFER_TIME = CURLINFO_DOUBLE + 17,
    CURLINFO_REDIRECT_TIME    = CURLINFO_DOUBLE + 19,
    CURLINFO_APPCONNECT_TIME  = CURLINFO_DOUBLE + 33
  );

  TCurlDoubleInfoDeprecated = (
    CURLINFO_SIZE_UPLOAD      = CURLINFO_DOUBLE + 7,
    CURLINFO_SIZE_DOWNLOAD    = CURLINFO_DOUBLE + 8,
    CURLINFO_SPEED_DOWNLOAD   = CURLINFO_DOUBLE + 9,
    CURLINFO_SPEED_UPLOAD     = CURLINFO_DOUBLE + 10,
    CURLINFO_CONTENT_LENGTH_DOWNLOAD   = CURLINFO_DOUBLE + 15,
    CURLINFO_CONTENT_LENGTH_UPLOAD     = CURLINFO_DOUBLE + 16
  );

  TCurlStringInfo = (
    CURLINFO_EFFECTIVE_URL    = CURLINFO_STRING + 1,
    CURLINFO_CONTENT_TYPE     = CURLINFO_STRING + 18,
    CURLINFO_PRIVATE          = CURLINFO_STRING + 21,
    CURLINFO_FTP_ENTRY_PATH   = CURLINFO_STRING + 30,
    CURLINFO_REDIRECT_URL     = CURLINFO_STRING + 31,
    CURLINFO_PRIMARY_IP       = CURLINFO_STRING + 32,
    CURLINFO_RTSP_SESSION_ID  = CURLINFO_STRING + 36,
    CURLINFO_LOCAL_IP         = CURLINFO_STRING + 41,
    CURLINFO_SCHEME           = CURLINFO_STRING + 49
  );

  TCurlSListInfo = (
    CURLINFO_SSL_ENGINES      = CURLINFO_SLIST  + 27,
    CURLINFO_COOKIELIST       = CURLINFO_SLIST  + 28,
    CURLINFO_TLS_SESSION      = CURLINFO_SLIST  + 43
  );

  TCurlPtrInfo = (
    CURLINFO_CERTINFO         = CURLINFO_SLIST  + 34,
    CURLINFO_TLS_SSL_PTR      = CURLINFO_PTR    + 45
  );

  TCurlSocketInfo = (
    CURLINFO_ACTIVESOCKET     = CURLINFO_SOCKET + 44
  );

  TCurlOffInfo = (
    CURLINFO_SIZE_UPLOAD_T    = CURLINFO_OFF_T  + 7,
    CURLINFO_SIZE_DOWNLOAD_T  = CURLINFO_OFF_T  + 8,
    CURLINFO_SPEED_DOWNLOAD_T = CURLINFO_OFF_T  + 9,
    CURLINFO_SPEED_UPLOAD_T   = CURLINFO_OFF_T  + 10,
    CURLINFO_CONTENT_LENGTH_DOWNLOAD_T = CURLINFO_OFF_T  + 15,
    CURLINFO_CONTENT_LENGTH_UPLOAD_T   = CURLINFO_OFF_T  + 16
  );


  TCurlClosePolicy = (
    CURLCLOSEPOLICY_NONE, // first, never use this
    CURLCLOSEPOLICY_OLDEST,
    CURLCLOSEPOLICY_LEAST_RECENTLY_USED,
    CURLCLOSEPOLICY_LEAST_TRAFFIC,
    CURLCLOSEPOLICY_SLOWEST,
    CURLCLOSEPOLICY_CALLBACK
  );

const
  CURL_GLOBAL_SSL     = 1 shl 0;
  CURL_GLOBAL_WIN32   = 1 shl 1;
  CURL_GLOBAL_ALL     = CURL_GLOBAL_SSL or CURL_GLOBAL_WIN32;
  CURL_GLOBAL_NOTHING = 0;
  CURL_GLOBAL_DEFAULT = CURL_GLOBAL_ALL;
  CURL_GLOBAL_ACK_EINTR = 1 shl 2;


//*****************************************************************************
// Setup defines, protos etc for the sharing stuff.
//

type
  // Different data locks for a single share
  TCurlLockData = (
    CURL_LOCK_DATA_NONE,
    //  CURL_LOCK_DATA_SHARE is used internally to say that
    //  the locking is just made to change the internal state of the share
    //  itself.
    CURL_LOCK_DATA_SHARE,
    CURL_LOCK_DATA_COOKIE,
    CURL_LOCK_DATA_DNS,
    CURL_LOCK_DATA_SSL_SESSION,
    CURL_LOCK_DATA_CONNECT
  );

  // Different lock access types
  TCurlLockAccess = (
    CURL_LOCK_ACCESS_NONE = 0,   // unspecified action
    CURL_LOCK_ACCESS_SHARED = 1, // for read perhaps
    CURL_LOCK_ACCESS_SINGLE = 2  // for write perhaps
  );

  EvCurlLock = procedure (
        handle : HCurl;
        data : TCurlLockData;
        locktype : TCurlLockAccess;
        userptr : pointer);  cdecl;
  EvCurlUnlock = procedure (
        handle : HCurl;
        data : TCurlLockData;
        userptr : pointer);  cdecl;

type
  TCurlSh = pointer;

  TCurlShCode = (
    CURLSHE_OK,           // all is fine
    CURLSHE_BAD_OPTION,   // 1
    CURLSHE_IN_USE,       // 2
    CURLSHE_INVALID,      // 3
    CURLSHE_NOMEM,        // 4 out of memory
    CURLSHE_NOT_BUILT_IN  // 5 feature not present in lib
  );

  TCurlShOption = (
    CURLSHOPT_NONE,       // don't use
    CURLSHOPT_SHARE,      // specify a data type to share
    CURLSHOPT_UNSHARE,    // specify which data type to stop sharing
    CURLSHOPT_LOCKFUNC,   // pass in a 'curl_lock_function' pointer
    CURLSHOPT_UNLOCKFUNC, // pass in a 'curl_unlock_function' pointer
    CURLSHOPT_USERDATA    // pass in a user data pointer used in the lock/unlock
  );                      //   callback functions

function curl_share_init : TCurlSh;
          cdecl;  external 'libcurl.dll';

function curl_share_setopt(
          share : TCurlSh;
          option : TCurlShOption) : TCurlShCode;  varargs;
          cdecl;  external 'libcurl.dll';

function curl_share_cleanup(share : TCurlSh) : TCurlShCode;
          cdecl;  external 'libcurl.dll';

//****************************************************************************
// Structures for querying information about the curl library at runtime.
//
type
  TCurlVersion = (
    CURLVERSION_FIRST,
    CURLVERSION_SECOND,
    CURLVERSION_THIRD,
    CURLVERSION_FOURTH,
    // The 'CURLVERSION_NOW' is the symbolic name meant to be used by
    //   basically all programs ever that want to get version information. It is
    //   meant to be a built-in version number for what kind of struct the caller
    //   expects. If the struct ever changes, we redefine the NOW to another enum
    //   from above.
    CURLVERSION_NOW = CURLVERSION_FOURTH
  );

  TCurlVersionInfo = record
    age : TCurlVersion;         // age of the returned struct
    version : PAnsiChar;        // LIBCURL_VERSION
    version_num : cardinal;     // LIBCURL_VERSION_NUM
    host : PAnsiChar;           // OS/host/cpu/machine when configured
    features : integer;         // bitmask, see defines below
    ssl_version : PAnsiChar;    // human readable string
    ssl_version_num : integer;  // not used anymore, always 0
    libz_version : PAnsiChar;   // human readable string
    // protocols is terminated by an entry with a NULL protoname
    protocols : PPAnsiChar;

    // The fields below this were added in CURLVERSION_SECOND
    ares : PAnsiChar;
    ares_num : integer;

    // This field was added in CURLVERSION_THIRD
    libidn : PAnsiChar;

    // These field were added in CURLVERSION_FOURTH

    // Same as '_libiconv_version' if built with HAVE_ICONV
    iconv_ver_num : integer;

    libssh_version : PAnsiChar; // human readable string
  end;
  PCurlVersionInfo = ^TCurlVersionInfo;

const
  CURL_VERSION_IPV6         = 1 shl 0;  // IPv6-enabled
  CURL_VERSION_KERBEROS4    = 1 shl 1;  // Kerberos V4 auth is supported
                                        //     (deprecated)
  CURL_VERSION_SSL          = 1 shl 2;  // SSL options are present
  CURL_VERSION_LIBZ         = 1 shl 3;  // libz features are present
  CURL_VERSION_NTLM         = 1 shl 4;  // NTLM auth is supported
  CURL_VERSION_GSSNEGOTIATE = 1 shl 5;  // Negotiate auth is supported
                                        //     (deprecated)
  CURL_VERSION_DEBUG        = 1 shl 6;  // Built with debug capabilities
  CURL_VERSION_ASYNCHDNS    = 1 shl 7;  // Asynchronous DNS resolves
  CURL_VERSION_SPNEGO       = 1 shl 8;  // SPNEGO auth is supported
  CURL_VERSION_LARGEFILE    = 1 shl 9;  // Supports files larger than 2GB
  CURL_VERSION_IDN          = 1 shl 10; // Internationized Domain Names are
                                        //     supported
  CURL_VERSION_SSPI         = 1 shl 11; // Built against Windows SSPI
  CURL_VERSION_CONV         = 1 shl 12; // Character conversions supported
  CURL_VERSION_CURLDEBUG    = 1 shl 13; // Debug memory tracking supported
  CURL_VERSION_TLSAUTH_SRP  = 1 shl 14; // TLS-SRP auth is supported
  CURL_VERSION_NTLM_WB      = 1 shl 15; // NTLM delegation to winbind helper
                                        //     is suported
  CURL_VERSION_HTTP2        = 1 shl 16; // HTTP2 support built-in
  CURL_VERSION_GSSAPI       = 1 shl 17; // Built against a GSS-API library
  CURL_VERSION_KERBEROS5    = 1 shl 18; // Kerberos V5 auth is supported
  CURL_VERSION_UNIX_SOCKETS = 1 shl 19; // Unix domain sockets support

// NAME curl_version_info()
//
// DESCRIPTION
//
// This function returns a pointer to a static copy of the version info
// struct. See above.
//
function curl_version_info(
        x : TCurlVersion = CURLVERSION_NOW) : PCurlVersionInfo;
          cdecl;  external 'libcurl.dll';


// NAME curl_easy_strerror()
//
// DESCRIPTION
//
// The curl_easy_strerror function may be used to turn a CURLcode value
// into the equivalent human readable error string.  This is useful
// for printing meaningful error messages.
//
function curl_easy_strerror(code : TCurlCode) : PAnsiChar;
          cdecl;  external 'libcurl.dll' name 'curl_easy_strerror';

// NAME curl_share_strerror()
//
// DESCRIPTION
//
// The curl_share_strerror function may be used to turn a CURLSHcode value
// into the equivalent human readable error string.  This is useful
// for printing meaningful error messages.
//
function curl_share_strerror(code : TCurlShCode) : PAnsiChar;
          cdecl;  external 'libcurl.dll';


// NAME curl_easy_pause()
//
// DESCRIPTION
//
// The curl_easy_pause function pauses or unpauses transfers. Select the new
// state by setting the bitmask, use the convenience defines below.
//
function curl_easy_pause(handle : HCurl; bitmask : integer) : TCurlCode;
          cdecl;  external 'libcurl.dll';

const
  CURLPAUSE_RECV      = 1 shl 0;
  CURLPAUSE_RECV_CONT = 0;
  CURLPAUSE_SEND      = 1 shl 2;
  CURLPAUSE_SEND_CONT = 0;

  CURLPAUSE_ALL       = CURLPAUSE_RECV or CURLPAUSE_SEND;
  CURLPAUSE_CONT      = CURLPAUSE_RECV_CONT or CURLPAUSE_SEND_CONT;


function curl_easy_init : HCurl;
        cdecl;  external 'libcurl.dll';

function curl_easy_setopt_initial(
        curl : HCurl) : TCurlCode;  varargs;
        cdecl;  external 'libcurl.dll'  name 'curl_easy_setopt';

function curl_easy_setopt(
        curl : HCurl;
        option : TCurlOffOption;
        data : TCurlOff) : TCurlCode;  overload;  inline;

function curl_easy_setopt(
        curl : HCurl;
        option : TCurlStringOption;
        data : PAnsiChar) : TCurlCode;  overload;  inline;

function curl_easy_setopt(
        curl : HCurl;
        option : TCurlStringOption;
        data : RawByteString) : TCurlCode;  overload;  inline;

function curl_easy_setopt(
        curl : HCurl;
        option : TCurlOption;
        data : pointer) : TCurlCode;  overload;  inline;

function curl_easy_setopt(
        curl : HCurl;
        option : TCurlIntOption;
        data : NativeUInt) : TCurlCode;  overload;  inline;

function curl_easy_setopt(
        curl : HCurl;
        option : TCurlIntOption;
        data : boolean) : TCurlCode;  overload;  inline;

function curl_easy_setopt(
        curl : HCurl;
        option : TCurlSlistOption;
        data : PCurlSList) : TCurlCode;  overload;  inline;

function curl_easy_setopt(
        curl : HCurl;
        option : TCurlPostOption;
        data : PCurlHttpPost) : TCurlCode;  overload;  inline;

function curl_easy_setopt(
        curl : HCurl;
        option : TCurlProxyTypeOption;
        data : TCurlProxyType) : TCurlCode;  overload;  inline;

function curl_easy_setopt(
        curl : HCurl;
        option : TCurlUseSslOption;
        data : TCurlUseSsl) : TCurlCode;  overload;  inline;

function curl_easy_setopt(
        curl : HCurl;
        option : TCurlIpResolveOption;
        data : TCurlIpResolve) : TCurlCode;  overload;  inline;

function curl_easy_setopt(
        curl : HCurl;
        option : TCurlFtpMethodOption;
        data : TCurlFtpMethod) : TCurlCode;  overload;  inline;

function curl_easy_setopt(
        curl : HCurl;
        option : TCurlRtspSeqOption;
        data : TCurlRtspSeq) : TCurlCode;  overload; inline;

function curl_easy_setopt(
        curl : HCurl;
        option : TCurlNetRcOption;
        data : TCurlNetrc) : TCurlCode;  overload; inline;

function curl_easy_setopt(
        curl : HCurl;
        option : TCurlSslVersionOption;
        data : TCurlSslVersion) : TCurlCode;  overload; inline;

function curl_easy_perform(curl : HCurl) : TCurlCode;
          cdecl;  external 'libcurl.dll';

procedure curl_easy_cleanup(curl : HCurl);
          cdecl;  external 'libcurl.dll';

// NAME curl_easy_getinfo()
//
// DESCRIPTION
//
// Request internal information from the curl session with this function.  The
// third argument MUST be a pointer to a long, a pointer to a char * or a
// pointer to a double (as the documentation describes elsewhere).  The data
// pointed to will be filled in accordingly and can be relied upon only if the
// function returns CURLE_OK.  This function is intended to get used *AFTER* a
// performed transfer, all results from this function are undefined until the
// transfer is completed.

function curl_easy_getinfo_initial(
      curl : HCurl) : TCurlCode;  varargs;
          cdecl;  external 'libcurl.dll' name 'curl_easy_getinfo';

function curl_easy_getinfo(
      curl : HCurl;
      info : TCurlStringInfo;
      var p : PAnsiChar) : TCurlCode;  overload;  inline;

function curl_easy_getinfo(
      curl : HCurl;
      info : TCurlLongInfo;
      var p : longint) : TCurlCode;  overload;  inline;

function curl_easy_getinfo(
      curl : HCurl;
      info : TCurlDoubleInfo;
      var p : double) : TCurlCode;  overload;  inline;

function curl_easy_getinfo(
      curl : HCurl;
      info : TCurlDoubleInfoDeprecated;
      var p : double) : TCurlCode;  overload;  inline;  deprecated 'Use version for TCurlOffInfo';

function curl_easy_getinfo(
      curl : HCurl;
      info : TCurlSListInfo;
      var p : PCurlSList) : TCurlCode;  overload;  inline;

function curl_easy_getinfo(
      curl : HCurl;
      info : TCurlOffInfo;
      var p : TCurlOff) : TCurlCode;  overload;  inline;

function curl_easy_getinfo(
      curl : HCurl;
      info : TCurlSocketInfo;
      var p : TCurlSocket) : TCurlCode;  overload;  inline;

function curl_easy_getinfo(
      curl : HCurl;
      info : TCurlPtrInfo;
      var p : pointer) : TCurlCode;  overload;  inline;


// NAME curl_easy_duphandle()
//
// DESCRIPTION
//
// Creates a new curl session handle with the same options set for the handle
// passed in. Duplicating a handle could only be a matter of cloning data and
// options, internal state info and things like persistent connections cannot
// be transferred. It is useful in multithreaded applications when you can run
// curl_easy_duphandle() for each new thread to avoid a series of identical
// curl_easy_setopt() invokes in every thread.
//
function curl_easy_duphandle(
      curl : HCurl) : HCurl;
          cdecl;  external 'libcurl.dll';


          // NAME curl_easy_reset()
//
// DESCRIPTION
//
// Re-initializes a CURL handle to the default values. This puts back the
// handle to the same state as it was in when it was just created.
//
// It does keep: live connections, the Session ID cache, the DNS cache and the
// cookies.
//
procedure curl_easy_reset(curl : HCurl);
          cdecl;  external 'libcurl.dll';


// NAME curl_easy_recv()
//
// DESCRIPTION
//
// Receives data from the connected socket. Use after successful
// curl_easy_perform() with CURLOPT_CONNECT_ONLY option.
//
function curl_easy_recv(
        curl : HCurl;
        var buffer;
        buflen : NativeUInt;
        out n : NativeUInt) : TCurlCode;
          cdecl;  external 'libcurl.dll';


// NAME curl_easy_send()
//
// DESCRIPTION
//
// Sends data over the connected socket. Use after successful
// curl_easy_perform() with CURLOPT_CONNECT_ONLY option.
//
function curl_easy_send(
        curl : HCurl;
        var buffer;
        buflen : NativeUint;
        out n : NativeUInt) : TCurlCode;
          cdecl;  external 'libcurl.dll';

//#define curl_share_setopt(share,opt,param) curl_share_setopt(share,opt,param)
//#define curl_multi_setopt(handle,opt,param) curl_multi_setopt(handle,opt,param)

implementation

function curl_formadd(
        var httppost, last_post : PCurlHttpPost;
        option1 : TCurlFormOption; data1 : PAnsiChar;
        optend : TCurlFormOption = CURLFORM_END) : TCurlFormCode;
begin
  Result := curl_formadd_initial(httppost, last_post, option1, data1, optend);
end;

function curl_formadd(
        var httppost, last_post : PCurlHttpPost;
        option1 : TCurlFormOption; data1 : PAnsiChar;
        option2 : TCurlFormOption; data2 : PAnsiChar;
        optend : TCurlFormOption = CURLFORM_END) : TCurlFormCode;
begin
  Result := curl_formadd_initial(httppost, last_post,
            option1, data1, option2, data2, optend);
end;

function curl_formadd(
        var httppost, last_post : PCurlHttpPost;
        option1 : TCurlFormOption; data1 : PAnsiChar;
        option2 : TCurlFormOption; data2 : PAnsiChar;
        option3 : TCurlFormOption; data3 : PAnsiChar;
        optend : TCurlFormOption = CURLFORM_END) : TCurlFormCode;
begin
  Result := curl_formadd_initial(httppost, last_post,
            option1, data1, option2, data2, option3, data3, optend);
end;

function curl_formadd(
        var httppost, last_post : PCurlHttpPost;
        option1 : TCurlFormOption; data1 : PAnsiChar;
        option2 : TCurlFormOption; data2 : PAnsiChar;
        option3 : TCurlFormOption; data3 : PAnsiChar;
        option4 : TCurlFormOption; data4 : PAnsiChar;
        optend : TCurlFormOption = CURLFORM_END) : TCurlFormCode;
begin
  Result := curl_formadd_initial(httppost, last_post,
        option1, data1, option2, data2, option3, data3, option4, data4,
        optend);
end;

function curl_formadd(
        var httppost, last_post : PCurlHttpPost;
        option1 : TCurlFormOption; data1 : PAnsiChar;
        option2 : TCurlFormOption; data2 : PAnsiChar;
        option3 : TCurlFormOption; data3 : PAnsiChar;
        option4 : TCurlFormOption; data4 : PAnsiChar;
        option5 : TCurlFormOption; data5 : PAnsiChar;
        optend : TCurlFormOption = CURLFORM_END) : TCurlFormCode;
begin
  Result := curl_formadd_initial(httppost, last_post,
        option1, data1, option2, data2, option3, data3, option4, data4,
        option5, data5, optend);
end;

function curl_formadd(
        var httppost, last_post : PCurlHttpPost;
        option1 : TCurlFormOption; data1 : PAnsiChar;
        option2 : TCurlFormOption; data2 : PAnsiChar;
        option3 : TCurlFormOption; data3 : PAnsiChar;
        option4 : TCurlFormOption; data4 : PAnsiChar;
        option5 : TCurlFormOption; data5 : PAnsiChar;
        option6 : TCurlFormOption; data6 : PAnsiChar;
        optend : TCurlFormOption = CURLFORM_END) : TCurlFormCode;
begin
  Result := curl_formadd_initial(httppost, last_post,
        option1, data1, option2, data2, option3, data3, option4, data4,
        option5, data5, option6, data6, optend);
end;

function curl_formadd(
        var httppost, last_post : PCurlHttpPost;
        option1 : TCurlFormOption; data1 : PAnsiChar;
        option2 : TCurlFormOption; data2 : PAnsiChar;
        option3 : TCurlFormOption; data3 : PAnsiChar;
        option4 : TCurlFormOption; data4 : PAnsiChar;
        option5 : TCurlFormOption; data5 : PAnsiChar;
        option6 : TCurlFormOption; data6 : PAnsiChar;
        option7 : TCurlFormOption; data7 : PAnsiChar;
        optend : TCurlFormOption = CURLFORM_END) : TCurlFormCode;
begin
  Result := curl_formadd_initial(httppost, last_post,
        option1, data1, option2, data2, option3, data3, option4, data4,
        option5, data5, option6, data6, option7, data7, optend);
end;


function curl_formadd(
        var httppost, last_post : PCurlHttpPost;
        option1 : TCurlFormOption; data1 : PAnsiChar;
        option2 : TCurlFormOption; data2 : PAnsiChar;
        option3 : TCurlFormOption; data3 : PAnsiChar;
        option4 : TCurlFormOption; data4 : PAnsiChar;
        option5 : TCurlFormOption; data5 : PAnsiChar;
        option6 : TCurlFormOption; data6 : PAnsiChar;
        option7 : TCurlFormOption; data7 : PAnsiChar;
        option8 : TCurlFormOption; data8 : PAnsiChar;
        optend : TCurlFormOption = CURLFORM_END) : TCurlFormCode;
begin
  Result := curl_formadd_initial(httppost, last_post,
        option1, data1, option2, data2, option3, data3, option4, data4,
        option5, data5, option6, data6, option7, data7, option8, data8,
        optend);
end;

function curl_formadd(
        var httppost, last_post : PCurlHttpPost;
        option1 : TCurlFormOption; data1 : PAnsiChar;
        option2 : TCurlFormOption; data2 : PAnsiChar;
        option3 : TCurlFormOption; data3 : PAnsiChar;
        option4 : TCurlFormOption; data4 : PAnsiChar;
        option5 : TCurlFormOption; data5 : PAnsiChar;
        option6 : TCurlFormOption; data6 : PAnsiChar;
        option7 : TCurlFormOption; data7 : PAnsiChar;
        option8 : TCurlFormOption; data8 : PAnsiChar;
        option9 : TCurlFormOption; data9 : PAnsiChar;
        optend : TCurlFormOption = CURLFORM_END) : TCurlFormCode;
begin
  Result := curl_formadd_initial(httppost, last_post,
        option1, data1, option2, data2, option3, data3, option4, data4,
        option5, data5, option6, data6, option7, data7, option8, data8,
        option9, data9, optend);
end;

function curl_formadd(
        var httppost, last_post : PCurlHttpPost;
        option1 : TCurlFormOption; data1 : PAnsiChar;
        option2 : TCurlFormOption; data2 : PAnsiChar;
        option3 : TCurlFormOption; data3 : PAnsiChar;
        option4 : TCurlFormOption; data4 : PAnsiChar;
        option5 : TCurlFormOption; data5 : PAnsiChar;
        option6 : TCurlFormOption; data6 : PAnsiChar;
        option7 : TCurlFormOption; data7 : PAnsiChar;
        option8 : TCurlFormOption; data8 : PAnsiChar;
        option9 : TCurlFormOption; data9 : PAnsiChar;
        option10 : TCurlFormOption; data10 : PAnsiChar;
        optend : TCurlFormOption) : TCurlFormCode;
begin
  Result := curl_formadd_initial(httppost, last_post,
        option1, data1, option2, data2, option3, data3, option4, data4,
        option5, data5, option6, data6, option7, data7, option8, data8,
        option9, data9, option10, data10, optend);
end;

function curl_easy_setopt(
        curl : HCurl;
        option : TCurlStringOption;
        data : PAnsiChar) : TCurlCode;
begin
  Result := curl_easy_setopt_initial(curl, option, data);
end;

function curl_easy_setopt(
        curl : HCurl;
        option : TCurlOption;
        data : pointer) : TCurlCode;
begin
  Result := curl_easy_setopt_initial(curl, option, data);
end;

function curl_easy_setopt(
        curl : HCurl;
        option : TCurlIntOption;
        data : NativeUInt) : TCurlCode;
begin
  Result := curl_easy_setopt_initial(curl, option, data);
end;

function curl_easy_setopt(
        curl : HCurl;
        option : TCurlSlistOption;
        data : PCurlSList) : TCurlCode;
begin
  Result := curl_easy_setopt_initial(curl, option, data);
end;

function curl_easy_setopt(
        curl : HCurl;
        option : TCurlPostOption;
        data : PCurlHttpPost) : TCurlCode;
begin
  Result := curl_easy_setopt_initial(curl, option, data);
end;

function curl_easy_setopt(
        curl : HCurl;
        option : TCurlIntOption;
        data : boolean) : TCurlCode;
begin
  Result := curl_easy_setopt(curl, option, NativeUInt(data));
end;

function curl_easy_setopt(
        curl : HCurl;
        option : TCurlStringOption;
        data : RawByteString) : TCurlCode;
begin
  Result := curl_easy_setopt_initial(curl, option, PAnsiChar(data));
end;

function curl_easy_setopt(
        curl : HCurl;
        option : TCurlOffOption;
        data : TCurlOff) : TCurlCode;
begin
  Result := curl_easy_setopt_initial(curl, option, data);
end;

function curl_easy_setopt(
        curl : HCurl;
        option : TCurlProxyTypeOption;
        data : TCurlProxyType) : TCurlCode;
begin
  Result := curl_easy_setopt_initial(curl, option, NativeUInt(data));
end;

function curl_easy_setopt(
        curl : HCurl;
        option : TCurlUseSslOption;
        data : TCurlUseSsl) : TCurlCode;
begin
  Result := curl_easy_setopt_initial(curl, option, NativeUInt(data));
end;

function curl_easy_setopt(
        curl : HCurl;
        option : TCurlFtpMethodOption;
        data : TCurlFtpMethod) : TCurlCode;
begin
  Result := curl_easy_setopt_initial(curl, option, NativeUInt(data));
end;

function curl_easy_setopt(
        curl : HCurl;
        option : TCurlIpResolveOption;
        data : TCurlIpResolve) : TCurlCode;
begin
  Result := curl_easy_setopt_initial(curl, option, NativeUInt(data));
end;

function curl_easy_setopt(
        curl : HCurl;
        option : TCurlRtspSeqOption;
        data : TCurlRtspSeq) : TCurlCode;
begin
  Result := curl_easy_setopt_initial(curl, option, NativeUInt(data));
end;

function curl_easy_setopt(
        curl : HCurl;
        option : TCurlNetRcOption;
        data : TCurlNetrc) : TCurlCode;
begin
  Result := curl_easy_setopt_initial(curl, option, NativeUInt(data));
end;

function curl_easy_setopt(
        curl : HCurl;
        option : TCurlSslVersionOption;
        data : TCurlSslVersion) : TCurlCode;
begin
  Result := curl_easy_setopt_initial(curl, option, NativeUInt(data));
end;

function curl_easy_getinfo(
      curl : HCurl;
      info : TCurlStringInfo;
      var p : PAnsiChar) : TCurlCode;
begin
  Result := curl_easy_getinfo_initial(curl, info, @p);
end;

function curl_easy_getinfo(
      curl : HCurl;
      info : TCurlLongInfo;
      var p : longint) : TCurlCode;
begin
  Result := curl_easy_getinfo_initial(curl, info, @p);
end;

function curl_easy_getinfo(
      curl : HCurl;
      info : TCurlDoubleInfo;
      var p : double) : TCurlCode;
begin
  Result := curl_easy_getinfo_initial(curl, info, @p);
end;

function curl_easy_getinfo(
      curl : HCurl;
      info : TCurlSListInfo;
      var p : PCurlSList) : TCurlCode;
begin
  Result := curl_easy_getinfo_initial(curl, info, @p);
end;

function curl_easy_getinfo(
      curl : HCurl;
      info : TCurlDoubleInfoDeprecated;
      var p : double) : TCurlCode;
begin
  Result := curl_easy_getinfo_initial(curl, info, @p);
end;

function curl_easy_getinfo(
      curl : HCurl;
      info : TCurlOffInfo;
      var p : TCurlOff) : TCurlCode;
begin
  Result := curl_easy_getinfo_initial(curl, info, @p);
end;

function curl_easy_getinfo(
      curl : HCurl;
      info : TCurlSocketInfo;
      var p : TCurlSocket) : TCurlCode;
begin
  Result := curl_easy_getinfo_initial(curl, info, @p);
end;

function curl_easy_getinfo(
      curl : HCurl;
      info : TCurlPtrInfo;
      var p : pointer) : TCurlCode;
begin
  Result := curl_easy_getinfo_initial(curl, info, @p);
end;

end.

