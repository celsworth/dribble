module View.Utils.TorrentAttributeMethods exposing (..)

import Model exposing (..)


textAlignment : TorrentAttribute -> Maybe String
textAlignment attribute =
    case attribute of
        Size ->
            Just "right"

        _ ->
            Nothing
