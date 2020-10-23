module Update.SetSortBy exposing (update)

import Dict
import Model exposing (..)
import Model.Attribute
import Model.Config
import Model.File
import Model.Sort exposing (SortDirection(..))
import Model.Sort.File
import Model.Sort.Torrent
import Model.Table
import Model.Torrent


update : Model.Attribute.Attribute -> Model -> ( Model, Cmd Msg )
update attribute model =
    case attribute of
        Model.Attribute.TorrentAttribute a ->
            model |> sortTorrents a

        Model.Attribute.FileAttribute a ->
            model |> sortFiles a

        Model.Attribute.PeerAttribute _ ->
            Debug.todo "support peer sorting"


sortTorrents : Model.Torrent.Attribute -> Model -> ( Model, Cmd Msg )
sortTorrents attribute model =
    let
        config =
            model.config

        (Model.Torrent.SortBy currentAttr currentDirection) =
            config.sortBy

        currentSortMatchesAttr =
            currentAttr == attribute

        newSort =
            if currentSortMatchesAttr then
                case currentDirection of
                    Asc ->
                        Model.Torrent.SortBy attribute Desc

                    Desc ->
                        Model.Torrent.SortBy attribute Asc

            else
                Model.Torrent.SortBy attribute currentDirection

        newSortedTorrents =
            Model.Sort.Torrent.sort newSort (Dict.values model.torrentsByHash)

        newConfig =
            config |> Model.Config.setSortBy newSort
    in
    model
        |> setConfig newConfig
        |> setSortedTorrents newSortedTorrents
        |> noCmd


sortFiles : Model.File.Attribute -> Model -> ( Model, Cmd Msg )
sortFiles attribute model =
    let
        config =
            model.config

        (Model.File.SortBy currentAttr currentDirection) =
            config.fileTable.sortBy

        currentSortMatchesAttr =
            currentAttr == attribute

        newSort =
            if currentSortMatchesAttr then
                case currentDirection of
                    Asc ->
                        Model.File.SortBy attribute Desc

                    Desc ->
                        Model.File.SortBy attribute Asc

            else
                Model.File.SortBy attribute currentDirection

        newSortedFiles =
            Model.Sort.File.sort newSort (Dict.values model.keyedFiles)

        newTableConfig =
            config.fileTable |> Model.Table.setSortBy newSort

        newConfig =
            config |> Model.Config.setFileTable newTableConfig
    in
    model
        |> setConfig newConfig
        |> setSortedFiles newSortedFiles
        |> noCmd
