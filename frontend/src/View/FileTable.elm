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
import Model.ContextMenu exposing (ContextMenu, For(..))
import Model.File exposing (File, FilesByKey)
import Model.FileTable exposing (Column, Config)
import Model.MousePosition
import Model.Sort
import Model.Table
import View.DragBar
import View.File
import View.Table
import View.Utils.ContextMenu


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
            , Html.Lazy.lazy2 maybeHeaderContextMenu
                model.config.fileTable
                model.contextMenu
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


maybeHeaderContextMenu : Config -> Maybe ContextMenu -> Html Msg
maybeHeaderContextMenu tableConfig contextMenu =
    Maybe.withDefault (text "") <|
        Maybe.map (headerContextMenu tableConfig) contextMenu


headerContextMenu : Config -> ContextMenu -> Html Msg
headerContextMenu tableConfig contextMenu =
    case contextMenu.for of
        FileTableColumn column ->
            View.Utils.ContextMenu.view contextMenu
                [ ul [] <|
                    [ headerContextMenuAutoWidth column, hr [] [] ]
                        ++ List.map headerContextMenuColumnRow tableConfig.columns
                ]

        _ ->
            text ""


headerContextMenuAutoWidth : Column -> Html Msg
headerContextMenuAutoWidth column =
    View.Table.headerContextMenuAutoWidth
        (Model.Attribute.FileAttribute column.attribute)
        ("Auto-Fit " ++ Model.File.attributeToString column.attribute)


headerContextMenuColumnRow : Column -> Html Msg
headerContextMenuColumnRow column =
    View.Table.headerContextMenuToggleVisibility
        column
        (Model.Attribute.FileAttribute column.attribute)
        (Model.File.attributeToString column.attribute)


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
    in
    th (headerCellAttributes config tableConfig column)
        (List.filterMap identity
            [ Just <|
                div (headerCellContentDivAttributes tableConfig column)
                    [ text attrString ]
            , maybeResizeDiv
            ]
        )


headerCellAttributes : Model.Config.Config -> Config -> Column -> List (Attribute Msg)
headerCellAttributes config tableConfig column =
    let
        contextMenuHandler =
            if config.enableContextMenus then
                Just <|
                    Mouse.onContextMenu
                        (\e ->
                            DisplayContextMenu
                                (Model.ContextMenu.FileTableColumn column)
                                (Model.MousePosition.reconstructClientPos e)
                                e.button
                                e.keys
                        )

            else
                Nothing
    in
    List.filterMap identity
        [ headerCellIdAttribute column
        , cellTextAlign column
        , headerCellSortClass tableConfig.sortBy column
        , contextMenuHandler
        ]


headerCellIdAttribute : Column -> Maybe (Attribute Msg)
headerCellIdAttribute column =
    Just <| id (Model.File.attributeToTableHeaderId column.attribute)


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
                    View.Table.thWidthAttribute column

                Model.Table.Fluid ->
                    Nothing
    in
    List.filterMap identity
        [ maybeWidthAttr
        , Just <| onClick (SetSortBy (Model.Attribute.FileAttribute column.attribute))
        ]


headerCellResizeHandleAttributes : Column -> List (Attribute Msg)
headerCellResizeHandleAttributes column =
    [ class "resize-handle"
    , Mouse.onDown (\e -> MouseDown (Model.Attribute.FileAttribute column.attribute) (Model.MousePosition.reconstructClientPos e) e.button e.keys)
    ]



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
                    View.Table.tdWidthAttribute column

                Model.Table.Fluid ->
                    Nothing
    in
    List.filterMap identity [ maybeWidthAttr, cellTextAlign column ]


cellTextAlign : Column -> Maybe (Attribute Msg)
cellTextAlign column =
    Maybe.map class (View.File.attributeTextAlignment column.attribute)
