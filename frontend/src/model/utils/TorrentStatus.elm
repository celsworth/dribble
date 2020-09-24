module Model.Utils.TorrentStatus exposing (..)

import Model exposing (..)


toInt : TorrentStatus -> Int
toInt torrentStatus =
    {- convert TorrentStatus to a comparable value for sorting -}
    case torrentStatus of
        Seeding ->
            0

        Downloading ->
            1

        Paused ->
            2

        Stopped ->
            3

        Hashing ->
            4
