module Torrent exposing (..)

import Dict exposing (Dict)
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



-- Given a Torrent and TorrentAttribute, return that attribute as a String.
-- This is what we need to render the data in HTML tables.


torrentAttributeAccessor : Torrent -> TorrentAttribute -> String
torrentAttributeAccessor torrent attribute =
    case attribute of
        Name ->
            torrent.name

        Size ->
            String.fromInt torrent.size
