module Model.Sort exposing (..)

import Model.Torrent


type Direction
    = Asc
    | Desc


type Sort
    = TorrentAttribute Model.Torrent.Attribute Direction
