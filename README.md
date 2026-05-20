# zig-X11-client
> An incomplete, proof of concept client implementation of the X11 protocol in zig.
> The goal is to create a **zero dependency** X11 client implementation.
> Because it bothers me to see all these dynamic libraries just to write some gui.
> The most weird part is libbsd.so.0,
> which is required by xcb library due to things way back thirty years ago.
> also I would like no libc. Just personal preferences.

```
linux-vdso.so.1
libm.so.6 => /lib/x86_64-linux-gnu/libm.so.6
libc.so.6 => /lib/x86_64-linux-gnu/libc.so.6
/lib64/ld-linux-x86-64.so.2
libxcb.so.1 => /lib/x86_64-linux-gnu/libxcb.so.1
libxcb-icccm.so.4 => /lib/x86_64-linux-gnu/libxcb-icccm.so.4
libXau.so.6 => /lib/x86_64-linux-gnu/libXau.so.6
libXdmcp.so.6 => /lib/x86_64-linux-gnu/libXdmcp.so.6
libbsd.so.0 => /lib/x86_64-linux-gnu/libbsd.so.0
libmd.so.0 => /lib/x86_64-linux-gnu/libmd.so.0
```

### References

[X11 Protocol](https://www.x.org/releases/current/doc/xproto/x11protocol.html)
> not always match the actual code/behavior.

[xcb-proto-1.17.0.tar.xz](https://www.x.org/releases/individual/xcb/xcb-proto-1.17.0.tar.xz)
> not always match the actual code/behavior.
