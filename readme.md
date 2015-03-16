About curl4delphi
=================

curl4delphi is a simple Delphi XE2+ binding for libcURL.

© 2015 Mikhail Merkuryev

Right now it is incomplete, but already works in one of my projects.

My initial version will support “easy” interface only.


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

A GUI file downloader. This example is rather complex because of multithreading and @Content-Disposition@.

Inter-thread communication, transfer function, quick-and-dirty header parsing.