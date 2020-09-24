module Update.SetSortBy exposing (update)

import Coders.Base
import Dict
import Model exposing (..)
import Model.TorrentSorter exposing (sort)


update : TorrentAttribute -> Model -> ( Model, Cmd Msg )
update attribute model =
    let
        newConfig =
            updateConfig attribute model.config

        sortedTorrents =
            Model.TorrentSorter.sort newConfig.sortBy
                (Dict.values model.torrentsByHash)
    in
    model
        |> setConfig newConfig
        |> setSortedTorrents sortedTorrents
        |> addCmd Cmd.none


updateConfig : TorrentAttribute -> Config -> Config
updateConfig attr config =
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
    config |> setSortBy newSort
