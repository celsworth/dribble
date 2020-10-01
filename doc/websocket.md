# Websocket Comms

Elm sends Ruby requests over a websocket. The most basic is:

```json
{
  "name": "torrentList",
  "command": ["d.multicall2", "", "main", "d.hash=", "d.name="],
}
```

This runs a single command in rtorrent, returning the response wrapped in the `name` so Elm can map it to the correct decoder:

```json
{
  "torrentList": [ ["...", "..."] ]
}
```

`command` being an array makes it easy to map directly to rtorrent by splatting it.
This also works for nested multicall commands:

```json
{
  "command":
    ["system.multicall", [
      {"methodName":"system.time_seconds","params":[]},
      {"methodName":"throttle.global_up.total","params":[]},
      {"methodName":"throttle.global_down.total","params":[]}
    ]],
  "name": "trafficRate"
}
```


## Subscriptions

```json
{
  "command": ["d.multicall2", "", "main", "d.hash=", "d.name="],
  "subscribe": "torrentList",
  "interval": 5
}
```

`subscribe` takes the place of `name` and means "I want this data regularly"; `interval` is how many seconds between checks. Each subscription has a unique name (here, torrentList) and re-subscribing with the same name will overwrite the previous one.

Ruby stores this `command` and runs it in a thread at the interval requested, sending the data down the Websocket without further prompting from Elm.

Elm can request only changed data in subscription updates, which makes sense when we might send back large lists (ie torrent lists).

```json
{
  "command": ["d.multicall2", "", "main", "d.hash=", "d.name="],
  "subscribe": "torrentList",
  "interval": 5,
  "diff": true
}

```

Now, only torrents that have been renamed (in this example) will be sent back after the first initial entire list.  This cuts down on traffic over the Websocket. We don't need to send the entire list every time, Elm keeps that state and can apply only changed entries. This only works properly if the first item in each sub-array is something we can key on, ie a torrent hash.


When Elm no longer wants new data from a subscription, it will unsubscribe:

```json
{
  "unsubscribe": "torrentList"
}
```
