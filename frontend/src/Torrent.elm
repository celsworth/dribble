module Torrent exposing (Torrent)


type alias Torrent =
    { hash : String
    , name : String
    , size : Int
    }
