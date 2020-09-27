module Model.ResizeOp exposing (..)

import Model.Torrent


type Attribute
    = TorrentAttribute Model.Torrent.Attribute


type alias ResizeOp =
    { attribute : Attribute
    , startPosition : MousePosition
    , currentPosition : MousePosition
    }


type alias MousePosition =
    { x : Float
    , y : Float
    }
