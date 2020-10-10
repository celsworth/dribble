module Update.SetSortBy exposing (update)

import Dict
import Model exposing (..)
import Model.Attribute
import Model.Config exposing (Config)
import Model.Sort.Torrent
import Model.Torrent


update : Model.Attribute.Attribute -> Model -> ( Model, Cmd Msg )
update attribute model =
    let
        newConfig =
            model.config |> updateConfig attribute

        (Model.Attribute.SortBy sortByAttribute sortByDir) =
            newConfig.sortBy
    in
    model
        |> setConfig newConfig
        |> applyNewSort sortByAttribute sortByDir
        |> noCmd


applyNewSort : Model.Attribute.Attribute -> Model.Attribute.SortDirection -> Model -> Model
applyNewSort sortByAttribute sortByDir model =
    case sortByAttribute of
        Model.Attribute.TorrentAttribute torrentAttribute ->
            model
                |> setSortedTorrents
                    (Model.Sort.Torrent.sort
                        torrentAttribute
                        sortByDir
                        (Dict.values model.torrentsByHash)
                    )


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
