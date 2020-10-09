module View.Table exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Html.Events.Extra.Mouse
import Html.Keyed as Keyed
import Html.Lazy
import Model exposing (..)
import Model.Attribute
import Model.Config exposing (Config)
import Model.Table


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



-- HEADER CELLS


headerCell : Config -> Model.Table.Config -> Model.Table.Column -> Html Msg
headerCell config tableConfig column =
    let
        attrString =
            Model.Attribute.attributeToTableHeaderString column.attribute

        maybeResizeDiv =
            case tableConfig.layout of
                Model.Table.Fixed ->
                    Just <| div (headerCellResizeHandleAttributes column.attribute) []

                Model.Table.Fluid ->
                    Nothing
    in
    th (headerCellAttributes config.sortBy column.attribute)
        (List.filterMap identity
            [ Just <|
                div (headerCellContentDivAttributes tableConfig column.attribute)
                    [ div [ class "content" ] [ text attrString ] ]
            , maybeResizeDiv
            ]
        )


headerCellAttributes : Model.Attribute.Sort -> Model.Attribute.Attribute -> List (Attribute Msg)
headerCellAttributes sortBy attribute =
    List.filterMap identity
        [ headerCellIdAttribute attribute
        , cellTextAlign attribute
        , headerCellSortClass sortBy attribute
        ]


headerCellIdAttribute : Model.Attribute.Attribute -> Maybe (Attribute Msg)
headerCellIdAttribute attribute =
    Just <| id (Model.Attribute.attributeToTableHeaderId attribute)


headerCellSortClass : Model.Attribute.Sort -> Model.Attribute.Attribute -> Maybe (Attribute Msg)
headerCellSortClass sortBy attribute =
    let
        (Model.Attribute.SortBy currentSortAttribute currentSortDirection) =
            sortBy
    in
    if currentSortAttribute == attribute then
        case currentSortDirection of
            Model.Attribute.Asc ->
                Just <| class "sorted ascending"

            Model.Attribute.Desc ->
                Just <| class "sorted descending"

    else
        Nothing


headerCellContentDivAttributes : Model.Table.Config -> Model.Attribute.Attribute -> List (Attribute Msg)
headerCellContentDivAttributes tableConfig attribute =
    let
        maybeWidthAttr =
            case tableConfig.layout of
                Model.Table.Fixed ->
                    thWidthAttribute tableConfig attribute

                Model.Table.Fluid ->
                    Nothing
    in
    List.filterMap identity
        [ maybeWidthAttr
        , Just <| onClick (SetSortBy attribute)
        ]


headerCellResizeHandleAttributes : Model.Attribute.Attribute -> List (Attribute Msg)
headerCellResizeHandleAttributes attribute =
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
        (\e ->
            MouseDown
                attribute
                (reconstructClientPos e)
                e.button
                e.keys
        )
    ]



-- BODY CELLS


cell : Model.Table.Config -> Model.Attribute.Attribute -> Html Msg -> Html Msg
cell tableConfig attribute content =
    td [] [ div (cellAttributes tableConfig attribute) [ content ] ]


cellAttributes : Model.Table.Config -> Model.Attribute.Attribute -> List (Attribute Msg)
cellAttributes tableConfig attribute =
    let
        maybeWidthAttr =
            case tableConfig.layout of
                Model.Table.Fixed ->
                    tdWidthAttribute tableConfig attribute

                Model.Table.Fluid ->
                    Nothing
    in
    List.filterMap identity [ maybeWidthAttr, cellTextAlign attribute ]



--


cellTextAlign : Model.Attribute.Attribute -> Maybe (Attribute Msg)
cellTextAlign attribute =
    Maybe.map class (Model.Attribute.textAlignment attribute)



{-
   WIDTH HELPERS

   this complication is because the width stored in columnWidths
   includes padding and borders. To set the proper size for the
   internal div, we need to subtract some:

   For th columns, that amounts to 10px (2*4px padding, 2*1px border)

   For td, there are no borders, so its just 2*4px padding to remove
-}


thWidthAttribute : Model.Table.Config -> Model.Attribute.Attribute -> Maybe (Attribute Msg)
thWidthAttribute tableConfig attribute =
    widthAttribute tableConfig attribute 10


tdWidthAttribute : Model.Table.Config -> Model.Attribute.Attribute -> Maybe (Attribute Msg)
tdWidthAttribute tableConfig attribute =
    widthAttribute tableConfig attribute 8


widthAttribute : Model.Table.Config -> Model.Attribute.Attribute -> Float -> Maybe (Attribute Msg)
widthAttribute tableConfig attribute subtract =
    let
        tableColumn =
            Model.Table.getColumn tableConfig attribute
    in
    if tableColumn.auto then
        Nothing

    else
        Just <| style "width" (String.fromFloat (tableColumn.width - subtract) ++ "px")
