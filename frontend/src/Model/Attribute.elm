module Model.Attribute exposing (..)

import Model.Torrent



{- attribute abstraction. Map an Attribute into TorrentAttribute or PeerAttribute etc -}


type SortDirection
    = Asc
    | Desc


type Sort
    = SortBy Attribute SortDirection


type Attribute
    = TorrentAttribute Model.Torrent.Attribute


unwrap : Attribute -> Model.Torrent.Attribute
unwrap attribute =
    case attribute of
        TorrentAttribute a ->
            a


attributeToKey : Attribute -> String
attributeToKey attribute =
    case attribute of
        TorrentAttribute torrentAttribute ->
            Model.Torrent.attributeToKey torrentAttribute


attributeToTableHeaderId : Attribute -> String
attributeToTableHeaderId attribute =
    case attribute of
        TorrentAttribute torrentAttribute ->
            Model.Torrent.attributeToTableHeaderId torrentAttribute


attributeToTableHeaderString : Attribute -> String
attributeToTableHeaderString attribute =
    case attribute of
        TorrentAttribute torrentAttribute ->
            Model.Torrent.attributeToTableHeaderString torrentAttribute


textAlignment : Attribute -> Maybe String
textAlignment attribute =
    case attribute of
        TorrentAttribute torrentAttribute ->
            Model.Torrent.attributeTextAlignment torrentAttribute
