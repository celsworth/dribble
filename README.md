# dribble

Part learning exercise, part frontend GUI for rtorrent.

May never do anything useful.

## Getting Started

The easy way is to use docker-compose.

If you want to run it natively, you'll need Ruby with bundler, and elm.

To compile the elm into JavaScript:

```
rake elm:build
```

Install the Ruby packages:

```
bundle install
```

Start the webserver on port 3000:

```
thin start
```

---
> **IMPORTANT SECURITY WARNING**: The thin server opens an endpoint (at `/ws`) that is a WebSocket proxy to your rtorrent SCGI interface. This endpoint must *never* be exposed to the Internet or you *will* get pwned via remote execution.
---


### Limitations

The entire app is view-only at the moment.

Torrents that are deleted in the client elsewhere will continue to be rendered as a row until you restart Dribble. This may be fixed in future.

The speed chart in the bottom right stops updating shortly after you switch away from a tab. This is because the entire thing is done in Javascript and a modern browser optimisation is to pause/deprioritise Javascript in background tabs. Not sure what I can do about this if anything.  It also doesn't render binary unit (KiB/s) ticks on the y-axis very well. They work but you can get some odd looking divisions at times. Fortunately I prefer network speeds measured in metric (kB/s) so this is a minor problem.
