module View.Table exposing (..)

{- generic table rendering from a Model.Table.Config and list of items -}

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Html.Events.Extra.Mouse
import Model exposing (..)
import Model.Attribute
import Model.Config exposing (Config)
import Model.Item exposing (Item)
import Model.Sort exposing (SortDirection(..))
import Model.Table
import Model.Torrent
import View.Item


view : Config -> Model.Table.Config -> List Item -> Html Msg
view config tableConfig items =
    section []
        [ table []
            [ header config tableConfig
            , body tableConfig items
            ]
        ]



-- HEADER


header : Config -> Model.Table.Config -> Html Msg
header config tableConfig =
    let
        visibleOrder =
            List.filter .visible tableConfig.columns
    in
    thead []
        [ tr []
            (List.map (headerCell config tableConfig) visibleOrder)
        ]


headerCell : Config -> Model.Table.Config -> Model.Table.Column -> Html Msg
headerCell config tableConfig column =
    let
        attrString =
            Model.Attribute.attributeToTableHeaderString column.attribute

        maybeResizeDiv =
            case tableConfig.layout of
                Model.Table.Fixed ->
                    Just <| div (headerCellResizeHandleAttributes column) []

                Model.Table.Fluid ->
                    Nothing

        {- torrentTable is a special case here -}
        sortBy =
            case tableConfig.tableType of
                Model.Table.Torrents ->
                    let
                        (Model.Torrent.SortBy attr dir) =
                            config.sortBy
                    in
                    Model.Attribute.SortBy (Model.Attribute.TorrentAttribute attr) dir

                _ ->
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


headerCellAttributes : Model.Attribute.Sort -> Model.Table.Column -> List (Attribute Msg)
headerCellAttributes sortBy column =
    List.filterMap identity
        [ headerCellIdAttribute column
        , cellTextAlign column
        , headerCellSortClass sortBy column
        ]


headerCellIdAttribute : Model.Table.Column -> Maybe (Attribute Msg)
headerCellIdAttribute column =
    Just <| id (Model.Attribute.attributeToTableHeaderId column.attribute)


headerCellSortClass : Model.Attribute.Sort -> Model.Table.Column -> Maybe (Attribute Msg)
headerCellSortClass sortBy column =
    let
        (Model.Attribute.SortBy currentSortAttribute currentSortDirection) =
            sortBy
    in
    if currentSortAttribute == column.attribute then
        case currentSortDirection of
            Asc ->
                Just <| class "sorted ascending"

            Desc ->
                Just <| class "sorted descending"

    else
        Nothing


headerCellContentDivAttributes : Model.Table.Config -> Model.Table.Column -> List (Attribute Msg)
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
        , Just <| onClick (SetSortBy column.attribute)
        ]


headerCellResizeHandleAttributes : Model.Table.Column -> List (Attribute Msg)
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
    , Html.Events.Extra.Mouse.onDown
        (\e -> MouseDown column.attribute (reconstructClientPos e) e.button e.keys)
    ]



-- BODY


body : Model.Table.Config -> List Item -> Html Msg
body tableConfig items =
    tbody [] <| List.map (row tableConfig) items


row : Model.Table.Config -> Item -> Html Msg
row tableConfig item =
    let
        visibleColumns =
            List.filter .visible tableConfig.columns
    in
    tr [] (List.map (cell tableConfig item) visibleColumns)


cell : Model.Table.Config -> Item -> Model.Table.Column -> Html Msg
cell tableConfig item column =
    td []
        [ div (cellAttributes tableConfig column)
            [ cellContent item column ]
        ]


cellAttributes : Model.Table.Config -> Model.Table.Column -> List (Attribute Msg)
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


cellTextAlign : Model.Table.Column -> Maybe (Attribute Msg)
cellTextAlign column =
    Maybe.map class (Model.Attribute.textAlignment column.attribute)


cellContent : Item -> Model.Table.Column -> Html Msg
cellContent item column =
    View.Item.attributeAccessor item column.attribute



{-
   WIDTH HELPERS

   this complication is because the width stored in columnWidths
   includes padding and borders. To set the proper size for the
   internal div, we need to subtract some:

   For th columns, that amounts to 10px (2*4px padding, 2*1px border)

   For td, there are no borders, so its just 2*4px padding to remove
-}


thWidthAttribute : Model.Table.Config -> Model.Table.Column -> Maybe (Attribute Msg)
thWidthAttribute tableConfig column =
    widthAttribute tableConfig column 10


tdWidthAttribute : Model.Table.Config -> Model.Table.Column -> Maybe (Attribute Msg)
tdWidthAttribute tableConfig column =
    widthAttribute tableConfig column 8


widthAttribute : Model.Table.Config -> Model.Table.Column -> Float -> Maybe (Attribute Msg)
widthAttribute tableConfig column subtract =
    if column.auto then
        Nothing

    else
        Just <| style "width" (String.fromFloat (column.width - subtract) ++ "px")
