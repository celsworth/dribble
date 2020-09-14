module Torrent exposing (sort)

import List
import Model exposing (..)


sort : Model -> List Torrent
sort model =
    List.sortBy .size model.torrents
