module View.TorrentTable exposing (view)

import Dict exposing (Dict)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Html.Events.Extra.Mouse
import Html.Keyed as Keyed
import Html.Lazy
import List
import Model exposing (..)
import Model.Config exposing (Config)
import Model.Table
import Model.Torrent exposing (Torrent)
import Model.TorrentFilter exposing (TorrentFilter)
import Round
import View.DragBar
import View.Torrent


view : Model -> Html Msg
view model =
    if List.isEmpty model.sortedTorrents then
        section [ class "torrents loading" ]
            [ i [ class "fas fa-spinner fa-pulse" ] [] ]

    else
        section [ class "torrents" ]
            [ table []
                [ Html.Lazy.lazy View.DragBar.view model.resizeOp
                , Html.Lazy.lazy header model.config
                , Html.Lazy.lazy4 body
                    model.torrentFilter
                    model.torrentsByHash
                    model.sortedTorrents
                    model.config
                ]
            ]


fixedOrFluid : Model.Table.Config -> Model.Table.Layout
fixedOrFluid tableConfig =
    tableConfig.layout


header : Config -> Html Msg
header config =
    let
        visibleOrder =
            List.filter (isVisible config.visibleTorrentAttributes)
                config.torrentAttributeOrder
    in
    thead []
        [ tr []
            (List.map (headerCell config) visibleOrder)
        ]


headerCell : Config -> Model.Torrent.Attribute -> Html Msg
headerCell config attribute =
    let
        attrString =
            View.Torrent.attributeToTableHeaderString
                attribute

        maybeResizeDiv =
            case fixedOrFluid config.torrentTable of
                Model.Table.Fixed ->
                    Just <| div (headerCellResizeHandleAttributes attribute) []

                Model.Table.Fluid ->
                    Nothing
    in
    th (headerCellAttributes config attribute)
        (List.filterMap identity
            [ Just <|
                div (headerCellContentDivAttributes config attribute)
                    [ div [ class "content" ] [ text attrString ] ]
            , maybeResizeDiv
            ]
        )


headerCellAttributes : Config -> Model.Torrent.Attribute -> List (Attribute Msg)
headerCellAttributes config attribute =
    List.filterMap identity
        [ headerCellIdAttribute attribute
        , cellTextAlign attribute
        , headerCellSortClass config attribute
        ]


headerCellIdAttribute : Model.Torrent.Attribute -> Maybe (Attribute Msg)
headerCellIdAttribute attribute =
    Just <| id (View.Torrent.attributeToTableHeaderId attribute)


headerCellContentDivAttributes : Config -> Model.Torrent.Attribute -> List (Attribute Msg)
headerCellContentDivAttributes config attribute =
    let
        maybeWidthAttr =
            case fixedOrFluid config.torrentTable of
                Model.Table.Fixed ->
                    thWidthAttribute config.torrentTable.columnWidths attribute

                Model.Table.Fluid ->
                    Nothing
    in
    List.filterMap identity
        [ maybeWidthAttr
        , Just <| onClick (SetSortBy attribute)
        ]


headerCellResizeHandleAttributes : Model.Torrent.Attribute -> List (Attribute Msg)
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
                (Model.Table.TorrentAttribute attribute)
                (reconstructClientPos e)
                e.button
                e.keys
        )
    ]


headerCellSortClass : Config -> Model.Torrent.Attribute -> Maybe (Attribute Msg)
headerCellSortClass config attribute =
    let
        (Model.Torrent.SortBy currentSortAttribute currentSortDirection) =
            config.sortBy
    in
    if currentSortAttribute == attribute then
        case currentSortDirection of
            Model.Torrent.Asc ->
                Just <| class "sorted ascending"

            Model.Torrent.Desc ->
                Just <| class "sorted descending"

    else
        Nothing


body : TorrentFilter -> Dict String Torrent -> List String -> Config -> Html Msg
body torrentFilter torrentsByHash sortedTorrents config =
    Keyed.node "tbody" [] <|
        List.filterMap identity
            (List.map (keyedRow torrentFilter torrentsByHash config) sortedTorrents)


keyedRow : TorrentFilter -> Dict String Torrent -> Config -> String -> Maybe ( String, Html Msg )
keyedRow torrentFilter torrentsByHash config hash =
    Maybe.map
        (\t -> ( t.hash, lazyRow torrentFilter config t ))
        (Dict.get hash torrentsByHash)


lazyRow : TorrentFilter -> Config -> Torrent -> Html Msg
lazyRow torrentFilter config torrent =
    if Model.TorrentFilter.torrentMatches torrentFilter torrent then
        Html.Lazy.lazy2 row config torrent

    else
        text ""


row : Config -> Torrent -> Html Msg
row config torrent =
    let
        {-
           _ =
               Debug.log "rendering:" torrent
        -}
        visibleOrder =
            List.filter (isVisible config.visibleTorrentAttributes)
                config.torrentAttributeOrder
    in
    tr
        []
        (List.map (cell config torrent) visibleOrder)


isVisible : List Model.Torrent.Attribute -> Model.Torrent.Attribute -> Bool
isVisible visibleTorrentAttributes attribute =
    List.member attribute visibleTorrentAttributes


cell : Config -> Torrent -> Model.Torrent.Attribute -> Html Msg
cell config torrent attribute =
    td []
        [ div (cellAttributes config.torrentTable attribute)
            [ cellContent config torrent attribute
            ]
        ]


cellAttributes : Model.Table.Config -> Model.Torrent.Attribute -> List (Attribute Msg)
cellAttributes tableConfig attribute =
    let
        maybeWidthAttr =
            case fixedOrFluid tableConfig of
                Model.Table.Fixed ->
                    tdWidthAttribute tableConfig.columnWidths attribute

                Model.Table.Fluid ->
                    Nothing
    in
    List.filterMap identity
        [ maybeWidthAttr
        , cellTextAlign attribute
        ]


cellTextAlign : Model.Torrent.Attribute -> Maybe (Attribute Msg)
cellTextAlign attribute =
    Maybe.map class (View.Torrent.textAlignment attribute)


cellContent : Config -> Torrent -> Model.Torrent.Attribute -> Html Msg
cellContent config torrent attribute =
    case attribute of
        Model.Torrent.Status ->
            torrentStatusCell torrent

        Model.Torrent.DonePercent ->
            donePercentCell torrent

        _ ->
            View.Torrent.attributeAccessor
                config
                torrent
                attribute


torrentStatusCell : Torrent -> Html Msg
torrentStatusCell torrent =
    case torrent.status of
        Model.Torrent.Seeding ->
            torrentStatusIcon "seeding" "fa-arrow-up"

        Model.Torrent.Errored ->
            torrentStatusIcon "errored" "fa-times"

        Model.Torrent.Downloading ->
            torrentStatusIcon "downloading" "fa-arrow-down"

        Model.Torrent.Paused ->
            torrentStatusIcon "paused" "fa-pause"

        Model.Torrent.Stopped ->
            torrentStatusIcon "stopped" ""

        Model.Torrent.Hashing ->
            torrentStatusIcon "hashing" "fa-sync"


torrentStatusIcon : String -> String -> Html Msg
torrentStatusIcon kls icon =
    span [ class ("torrent-status " ++ kls ++ " fa-stack") ]
        [ i [ class "fas fa-square fa-stack-2x" ] []
        , i [ class ("fas " ++ icon ++ " fa-inverse fa-stack-1x") ] []
        ]


donePercentCell : Torrent -> Html Msg
donePercentCell torrent =
    let
        dp =
            if torrent.donePercent == 100 then
                0

            else
                1
    in
    div [ class "progress-container" ]
        [ progress
            [ Html.Attributes.max "100"
            , Html.Attributes.value <| Round.round 0 torrent.donePercent
            ]
            []
        , span []
            [ text (Round.round dp torrent.donePercent ++ "%") ]
        ]



{-
   WIDTH HELPERS

   this complication is because the width stored in columnWidths
   includes padding and borders. To set the proper size for the
   internal div, we need to subtract some:

   For th columns, that amounts to 10px (2*4px padding, 2*1px border)

   For td, there are no borders, so its just 2*4px padding to remove
-}


thWidthAttribute : Model.Table.ColumnWidths -> Model.Torrent.Attribute -> Maybe (Attribute Msg)
thWidthAttribute columnWidths attribute =
    widthAttribute columnWidths attribute 10


tdWidthAttribute : Model.Table.ColumnWidths -> Model.Torrent.Attribute -> Maybe (Attribute Msg)
tdWidthAttribute columnWidths attribute =
    widthAttribute columnWidths attribute 8


widthAttribute : Model.Table.ColumnWidths -> Model.Torrent.Attribute -> Float -> Maybe (Attribute Msg)
widthAttribute columnWidths attribute subtract =
    let
        width =
            Model.Table.getColumnWidth columnWidths
                (Model.Table.TorrentAttribute attribute)

        { auto, px } =
            width
    in
    if auto then
        Nothing

    else
        Just <| style "width" (String.fromFloat (px - subtract) ++ "px")
