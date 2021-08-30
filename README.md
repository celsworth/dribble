# dribble

Part learning exercise, part frontend GUI for rtorrent.

---
> **IMPORTANT SECURITY WARNING**
>
> The Ruby appserver opens an endpoint (at `/ws`) that is a WebSocket proxy to your rtorrent SCGI interface. This endpoint must *never* be exposed to the Internet or you *will* get pwned via remote execution.
>
> There is also a proxy endpoint (`/proxy`) that Elm uses to fetch favicons of trackers. This is an open proxy and will be abused if you expose it to the Internet.
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
bundle exec iodine -b 127.0.0.1 -p 3000 -www public -v
```

### Hints

Populating the "AddedTime" column needs an .rtorrent.rc adjustment. Add this:

```
method.set_key = event.download.inserted_new, loaded_time, "d.custom.set=addtime,$cat=$system.time=;d.save_full_session="
```

This uses the same custom key as rutorrent so your added times should work in both frontends.


### Limitations

The entire app is view-only at the moment. Ability to change things coming soonish.

Redrawing the main torrent table can get a bit sluggish with more than a few hundred torrents, particularly re-ordering or clearing filters, because every single row has to be re-rendered.

Torrents that are deleted in the client elsewhere will continue to be rendered as a row until you restart Dribble. This may be fixed in future.

The speed chart in the bottom left doesn't render binary unit (KiB/s) ticks on the y-axis very well. They work but you can get some odd looking divisions at times. Fortunately I prefer network speeds measured in metric (kB/s) so this is a minor problem (for me).

Dribble is very front-end focused and most of the logic is in Elm, which is only running when your browser is looking at the app. Therefore this project cannot replicate certain things ruTorrent does, like daily/weekly/monthly traffic stats, because it cannot count transferred data in the background. See Hints above for a workaround on maintaining the "AddedTime" column though.


### Known Bugs

* Safari refuses to let you make a resizeable element smaller than its initial size, which becomes apparent when resizing Preferences/Logs. Silly Safari, other browsers get it right.
* The column resizing orange drag bar would look better if it only used the relevant table height, not the full viewport height. This is a styling bug I haven't worked out how to fix yet.
