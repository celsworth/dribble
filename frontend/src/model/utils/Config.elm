module Model.Utils.Config exposing (..)

import List.Extra
import Model exposing (..)


toggleTorrentAttributeVisibility : TorrentAttribute -> Config -> Config
toggleTorrentAttributeVisibility attr config =
    let
        newVTA =
            if List.member attr config.visibleTorrentAttributes then
                List.Extra.remove attr config.visibleTorrentAttributes

            else
                -- inserts at beginning
                attr :: config.visibleTorrentAttributes
    in
    { config | visibleTorrentAttributes = newVTA }


setSortBy : TorrentAttribute -> Config -> Config
setSortBy attr config =
    let
        (SortBy currentAttr currentDirection) =
            config.sortBy

        currentSortMatchesAttr =
            currentAttr == attr

        newSort =
            if currentSortMatchesAttr then
                case currentDirection of
                    Asc ->
                        SortBy attr Desc

                    Desc ->
                        SortBy attr Asc

            else
                SortBy attr currentDirection
    in
    { config | sortBy = newSort }
