module Update.SetSortBy exposing (update)

import Dict
import Model exposing (..)
import Model.Config exposing (Config)
import Model.Torrent


update : Model.Torrent.Attribute -> Model -> ( Model, Cmd Msg )
update attribute model =
    let
        newConfig =
            updateConfig attribute model.config

        sortedTorrents =
            Model.Torrent.sort newConfig.sortBy
                (Dict.values model.torrentsByHash)
    in
    model
        |> setConfig newConfig
        |> setSortedTorrents sortedTorrents
        |> noCmd


updateConfig : Model.Torrent.Attribute -> Config -> Config
updateConfig attr config =
    let
        (Model.Torrent.SortBy currentAttr currentDirection) =
            config.sortBy

        currentSortMatchesAttr =
            currentAttr == attr

        newSort =
            if currentSortMatchesAttr then
                case currentDirection of
                    Model.Torrent.Asc ->
                        Model.Torrent.SortBy attr Model.Torrent.Desc

                    Model.Torrent.Desc ->
                        Model.Torrent.SortBy attr Model.Torrent.Asc

            else
                Model.Torrent.SortBy attr currentDirection
    in
    config |> Model.Config.setSortBy newSort
