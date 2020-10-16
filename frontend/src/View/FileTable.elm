module View.FileTable exposing (view)

import Dict
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Keyed as Keyed
import Html.Lazy
import List
import Model exposing (..)
import Model.Attribute
import Model.Config
import Model.File exposing (File, FilesByKey)
import Model.Table
import View.DragBar
import View.File
import View.Table


view : Model -> Html Msg
view model =
    if List.isEmpty model.sortedFiles then
        section [ class "files loading" ]
            [ i [ class "fas fa-spinner fa-pulse" ] [] ]

    else
        section [ class "files" ]
            [ table []
                [ Html.Lazy.lazy View.DragBar.view model.resizeOp
                , Html.Lazy.lazy2 View.Table.header model.config model.config.fileTable
                , Html.Lazy.lazy4 body
                    model.config.fileTable
                    model.config.humanise
                    model.keyedFiles
                    model.sortedFiles
                ]
            ]


body : Model.Table.Config -> Model.Config.Humanise -> FilesByKey -> List String -> Html Msg
body tableConfig humanise keyedFiles sortedFiles =
    Keyed.node "tbody" [] <|
        List.filterMap identity
            (List.map (keyedRow tableConfig humanise keyedFiles) sortedFiles)


keyedRow : Model.Table.Config -> Model.Config.Humanise -> FilesByKey -> String -> Maybe ( String, Html Msg )
keyedRow tableConfig humanise keyedFiles key =
    Maybe.map (\file -> ( key, row tableConfig humanise file ))
        (Dict.get key keyedFiles)


row : Model.Table.Config -> Model.Config.Humanise -> File -> Html Msg
row tableConfig humanise file =
    let
        visibleColumns =
            List.filter .visible tableConfig.columns
    in
    tr []
        (List.map (cell tableConfig humanise file) visibleColumns)


cell : Model.Table.Config -> Model.Config.Humanise -> File -> Model.Table.Column -> Html Msg
cell tableConfig humanise file column =
    td []
        [ div (View.Table.cellAttributes tableConfig column)
            [ cellContent humanise file column ]
        ]


cellContent : Model.Config.Humanise -> File -> Model.Table.Column -> Html Msg
cellContent humanise file column =
    case column.attribute of
        Model.Attribute.FileAttribute Model.File.DonePercent ->
            View.Table.donePercentCell file.donePercent

        Model.Attribute.FileAttribute fileAttribute ->
            View.File.attributeAccessor humanise file fileAttribute

        _ ->
            Debug.todo "not reachable, can we remove this?"
