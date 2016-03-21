Secure Delete Variable in Memory
================================

```
pass = ""
$stdin.sysread(256, pass) # assuming a line-buffered terminal
io = StringIO.new("\0" * pass.bytesize)
io.read(pass.bytesize, pass)
```

_Must_ use sysread as userspace buffering will likely leak one or more additional copies of the string.
