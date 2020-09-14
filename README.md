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
