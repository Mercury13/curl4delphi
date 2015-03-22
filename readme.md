About curl4delphi
=================

curl4delphi is a simple Delphi XE2+ binding for libcURL.

© 2015 Mikhail Merkuryev

Right now it is incomplete, but already works in one of my projects.

My initial version will support “easy” interface only.


Quick start
===========

1. Add to project files `Curl.Lib`, `Curl.Easy`, `Curl.Interfaces`.
1. Write such a piece of code.

```
var
  curl : ICurl;
  stream : TStream;

curl := CurlGet;
stream := TFileStream.Create('curl.out', fmCreate);
try
  curl.SetUrl('http://example.com');
  curl.SetRecvStream(stream);
  curl.Perform;
finally
  stream.Free;
end;
```

Examples
========

### Misc\Version

Shows version

### RawHttp\Simple, EasyHttp\Simple

Redirection, basic HTTP GET, GetInfo

### RawHttp\Https, EasyHttp\Https

Redirection, basic HTTPS support, CA files, Unicode in file names.

**Warning:** download a CA file such as cacert.pem.

### EasyHttp\StreamedDl

Downloading to Delphi TStream’s.

### EasyHttp\ProgressBar

A GUI file downloader. This example is rather complex because of multithreading and `Content-Disposition`. We do as most browsers do: request headers, then start writing to temporary file and simultaneously ask where to save it on HDD.

Inter-thread communication, transfer function, quick-and-dirty header parsing.

### RawHttp\AplusB_Post, EasyHttp\AplusB_Post

A simple form demo. Please copy `php_curl` directory to a PHP-capable web server.

Forms (one field is set in a simple way, the other in more complex one).
