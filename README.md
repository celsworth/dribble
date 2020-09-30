# dribble

Part learning exercise, part frontend GUI for rtorrent.

May never do anything useful.

---
> **IMPORTANT SECURITY WARNING**: The thin server opens an endpoint (at `/ws`) that is a WebSocket proxy to your rtorrent SCGI interface. This endpoint must *never* be exposed to the Internet or you *will* get pwned via remote execution.
---

## Running

Via Docker:

```
# only pre tag is available for now (built on each commit), no stable release yet
docker pull celsworth/dribble:pre
docker run --rm -it -p 127.0.0.1:3000:3000 celsworth/dribble:pre
```

This will expose the webserver that runs on port 3000 to localhost only.

You'll need to give it some access to an rtorrent socket to be useful. UNIX sockets are recommended as they're easier to get access to inside a Docker container, as follows:

```
# assuming rtorrent is listening at /var/run/rtorrent.sock
docker run --rm -it -p 127.0.0.1:3000:3000 \
  -e RTORRENT=/var/run/rtorrent.sock
  -v /var/run/rtorrent.sock:/var/run/rtorrent.sock
  celsworth/dribble:pre
```

The `RTORRENT` environment variable tells the app where the socket is, and `-v` bind-mounts your socket into the container. Note that `RTORRENT` must start with a slash or a dot to be recognised as a path rather than a host/IP.

There is support for talking to rtorrent over TCP, but you'll need to work out a way to give the container access to the host/port. Use `-e` to set`RTORRENT` to set the host or IP rtorrent is at, and `RTORRENT_PORT` to the port (defaults to 5000).

## Development

### Docker

The easy way is to use docker-compose which will start a Ruby webserver and elm compiler which should pick up changes and rebuild automatically:

```
docker-compose up
```

### Native

If you want to run it natively, you'll need Ruby with bundler, and elm.


Install the Ruby packages:

```
bundle install
```

Compile the elm into JavaScript:

```
bundle exec rake elm:build
```

Start the webserver on localhost port 3000:

```
bundle exec thin start -a 127.0.0.1 -p 3000
```


### Limitations

The entire app is view-only at the moment.

Torrents that are deleted in the client elsewhere will continue to be rendered as a row until you restart Dribble. This may be fixed in future.

The speed chart in the bottom right stops updating shortly after you switch away from a tab. This is because the entire thing is done in Javascript and a modern browser optimisation is to pause/deprioritise Javascript in background tabs. Not sure what I can do about this if anything.  It also doesn't render binary unit (KiB/s) ticks on the y-axis very well. They work but you can get some odd looking divisions at times. Fortunately I prefer network speeds measured in metric (kB/s) so this is a minor problem.
