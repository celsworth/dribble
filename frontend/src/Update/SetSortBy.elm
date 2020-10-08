module Update.SetSortBy exposing (update)

import Dict
import Model exposing (..)
import Model.Attribute
import Model.Config exposing (Config)
import Model.Sort.Torrent


update : Model.Attribute.Attribute -> Model -> ( Model, Cmd Msg )
update attribute model =
    let
        newConfig =
            model.config |> updateConfig attribute

        (Model.Attribute.SortBy sortByAttribute sortByDir) =
            newConfig.sortBy

        applyNewSort =
            case sortByAttribute of
                Model.Attribute.TorrentAttribute torrentAttribute ->
                    setSortedTorrents <|
                        Model.Sort.Torrent.sort
                            torrentAttribute
                            sortByDir
                            (Dict.values model.torrentsByHash)
    in
    model
        |> setConfig newConfig
        |> applyNewSort
        |> noCmd


updateConfig : Model.Attribute.Attribute -> Config -> Config
updateConfig attr config =
    let
        (Model.Attribute.SortBy currentAttr currentDirection) =
            config.sortBy

        currentSortMatchesAttr =
            currentAttr == attr

        newSort =
            if currentSortMatchesAttr then
                case currentDirection of
                    Model.Attribute.Asc ->
                        Model.Attribute.SortBy attr Model.Attribute.Desc

                    Model.Attribute.Desc ->
                        Model.Attribute.SortBy attr Model.Attribute.Asc

            else
                Model.Attribute.SortBy attr currentDirection
    in
    config |> Model.Config.setSortBy newSort
