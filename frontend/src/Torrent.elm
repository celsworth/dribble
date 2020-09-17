module Torrent exposing (..)

import Model exposing (..)



--- unused but kept for reference for a while


attributeStringToTorrentAttribute : String -> TorrentAttribute -> TorrentAttribute
attributeStringToTorrentAttribute name default =
    case name of
        "name" ->
            Name

        "size" ->
            Size

        _ ->
            default
