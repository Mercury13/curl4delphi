About curl4delphi
=================

curl4delphi is a simple Delphi XE2+ binding for libcURL.

© 2015 Mikhail Merkuryev

My initial version supports “easy” interface only.


Quick start
===========

1. Add files `Curl.Lib`, `Curl.Easy`, `Curl.Interfaces` to your project.
2. Write such a piece of code.

```
var
  curl : ICurl;

curl := CurlGet;
curl.SetUrl('http://example.com')
	.SetProxyFromIe
	.SetUserAgent(ChromeUserAgent)
	.SwitchRecvToString
	.Perform;
Writeln(curl.ResponseBody);
```

[To use streams for receiving, check `EasyHttp\StreamedDl`].

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

### EasyHttp\FileDownloader

A GUI file downloader. This example is rather complex because of multithreading and `Content-Disposition`. We do as most browsers do: request headers, then start writing to temporary file and simultaneously ask where to save it on HDD.

Inter-thread communication, transfer function, quick-and-dirty header parsing.

### RawHttp\AplusB_Post, EasyHttp\AplusB_Post

A simple form demo. Please copy `php_curl` directory to a PHP-capable web server.

Forms (one field is set in a simple way, the other in more complex one).

### EasyHttp\PhotoInfo

File uploading: disk file (2 ways), memory buffer, stream.

ICurl cloning demo (not particularly good, it is more an illustration that Clone works).

Please copy `php_curl` directory to a PHP-capable web server.

### EasyHttp\AplusB_Get

Using ICurlGetBuilder to build a GET URL. Please copy `php_curl` directory to a PHP-capable web server.

License
=======
MIT for library, public domain for examples.
