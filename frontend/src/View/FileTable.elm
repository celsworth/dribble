module View.FileTable exposing (view)

import Dict
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Html.Events.Extra.Mouse as Mouse
import Html.Keyed as Keyed
import Html.Lazy
import List
import Model exposing (..)
import Model.Attribute
import Model.Config
import Model.File exposing (File, FilesByKey)
import Model.FileTable exposing (Column, Config)
import Model.Sort
import Model.Table
import View.DragBar
import View.File
import View.Table


view : Model -> Html Msg
view model =
    if List.isEmpty model.sortedFiles then
        section [ class "details-table loading" ]
            [ i [ class "fas fa-spinner fa-pulse" ] [] ]

    else
        section [ class "details-table" ]
            [ table []
                [ Html.Lazy.lazy View.DragBar.view model.resizeOp
                , Html.Lazy.lazy2 header model.config model.config.fileTable
                , Html.Lazy.lazy4 body
                    model.config.fileTable
                    model.config.humanise
                    model.keyedFiles
                    model.sortedFiles
                ]
            ]



-- HEADER


header : Model.Config.Config -> Config -> Html Msg
header config tableConfig =
    let
        visibleOrder =
            List.filter .visible tableConfig.columns
    in
    thead []
        [ tr []
            (List.map (headerCell config tableConfig) visibleOrder)
        ]


headerCell : Model.Config.Config -> Config -> Column -> Html Msg
headerCell config tableConfig column =
    let
        attrString =
            Model.File.attributeToTableHeaderString column.attribute

        maybeResizeDiv =
            case tableConfig.layout of
                Model.Table.Fixed ->
                    Just <| div (headerCellResizeHandleAttributes column) []

                Model.Table.Fluid ->
                    Nothing

        sortBy =
            tableConfig.sortBy
    in
    th (headerCellAttributes sortBy column)
        (List.filterMap identity
            [ Just <|
                div (headerCellContentDivAttributes tableConfig column)
                    [ div [ class "content" ] [ text attrString ] ]
            , maybeResizeDiv
            ]
        )


headerCellAttributes : Model.File.Sort -> Column -> List (Attribute Msg)
headerCellAttributes sortBy column =
    List.filterMap identity
        [ headerCellIdAttribute column
        , cellTextAlign column
        , headerCellSortClass sortBy column
        ]


headerCellSortClass : Model.File.Sort -> Column -> Maybe (Attribute Msg)
headerCellSortClass sortBy column =
    let
        (Model.File.SortBy currentSortAttribute currentSortDirection) =
            sortBy
    in
    if currentSortAttribute == column.attribute then
        case currentSortDirection of
            Model.Sort.Asc ->
                Just <| class "sorted ascending"

            Model.Sort.Desc ->
                Just <| class "sorted descending"

    else
        Nothing


headerCellContentDivAttributes : Config -> Column -> List (Attribute Msg)
headerCellContentDivAttributes tableConfig column =
    let
        maybeWidthAttr =
            case tableConfig.layout of
                Model.Table.Fixed ->
                    thWidthAttribute tableConfig column

                Model.Table.Fluid ->
                    Nothing
    in
    List.filterMap identity
        [ maybeWidthAttr
        , Just <| onClick (SetSortBy (Model.Attribute.FileAttribute column.attribute))
        ]


headerCellResizeHandleAttributes : Column -> List (Attribute Msg)
headerCellResizeHandleAttributes column =
    let
        {- this mess converts (x, y) to { x: x, y: y } -}
        reconstructClientPos =
            \event ->
                let
                    ( x, y ) =
                        event.clientPos
                in
                { x = x, y = y }
    in
    [ class "resize-handle"
    , Mouse.onDown (\e -> MouseDown (Model.Attribute.FileAttribute column.attribute) (reconstructClientPos e) e.button e.keys)
    ]


headerCellIdAttribute : Column -> Maybe (Attribute Msg)
headerCellIdAttribute column =
    Just <| id (Model.File.attributeToTableHeaderId column.attribute)



--BODY


body : Config -> Model.Config.Humanise -> FilesByKey -> List String -> Html Msg
body tableConfig humanise keyedFiles sortedFiles =
    Keyed.node "tbody" [] <|
        List.filterMap identity
            (List.map (keyedRow tableConfig humanise keyedFiles) sortedFiles)


keyedRow : Config -> Model.Config.Humanise -> FilesByKey -> String -> Maybe ( String, Html Msg )
keyedRow tableConfig humanise keyedFiles key =
    Maybe.map (\file -> ( key, row tableConfig humanise file ))
        (Dict.get key keyedFiles)


row : Config -> Model.Config.Humanise -> File -> Html Msg
row tableConfig humanise file =
    let
        visibleColumns =
            List.filter .visible tableConfig.columns
    in
    tr []
        (List.map (cell tableConfig humanise file) visibleColumns)


cell : Config -> Model.Config.Humanise -> File -> Model.FileTable.Column -> Html Msg
cell tableConfig humanise file column =
    td []
        [ div (cellAttributes tableConfig column)
            [ cellContent humanise file column ]
        ]


cellContent : Model.Config.Humanise -> File -> Column -> Html Msg
cellContent humanise file column =
    case column.attribute of
        Model.File.DonePercent ->
            View.Table.donePercentCell file.donePercent

        fileAttribute ->
            View.File.attributeAccessor humanise file fileAttribute


cellAttributes : Config -> Column -> List (Attribute Msg)
cellAttributes tableConfig column =
    let
        maybeWidthAttr =
            case tableConfig.layout of
                Model.Table.Fixed ->
                    tdWidthAttribute tableConfig column

                Model.Table.Fluid ->
                    Nothing
    in
    List.filterMap identity [ maybeWidthAttr, cellTextAlign column ]


cellTextAlign : Column -> Maybe (Attribute Msg)
cellTextAlign column =
    Maybe.map class (View.File.attributeTextAlignment column.attribute)


thWidthAttribute : Config -> Column -> Maybe (Attribute Msg)
thWidthAttribute tableConfig column =
    widthAttribute tableConfig column 10


tdWidthAttribute : Config -> Column -> Maybe (Attribute Msg)
tdWidthAttribute tableConfig column =
    widthAttribute tableConfig column 8


widthAttribute : Config -> Column -> Float -> Maybe (Attribute Msg)
widthAttribute tableConfig column subtract =
    if column.auto then
        Nothing

    else
        Just <| style "width" (String.fromFloat (column.width - subtract) ++ "px")
