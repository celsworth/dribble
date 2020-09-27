module View.TorrentTable exposing (..)

import Dict
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Html.Events.Extra.Mouse
import Html.Keyed as Keyed
import Html.Lazy
import List
import Model exposing (..)
import Model.Config exposing (ColumnWidths, Config)
import Model.ResizeOp
import Model.Shared
import Model.Table
import Model.Torrent exposing (Torrent)
import Round
import Time
import View.DragBar
import View.Torrent


view : Model -> Html Msg
view model =
    if List.isEmpty model.sortedTorrents then
        section [ class "torrents loading" ]
            [ i [ class "fas fa-spinner fa-pulse" ] [] ]

    else
        section [ class "torrents" ]
            [ Html.table []
                [ View.DragBar.view model
                , header model
                , body model
                ]
            ]


fixedOrFluid : Config -> Model.Table.Layout
fixedOrFluid config =
    config.torrentTable.layout


header : Model -> Html Msg
header model =
    let
        visibleOrder =
            List.filter (isVisible model.config.visibleTorrentAttributes)
                model.config.torrentAttributeOrder
    in
    thead []
        [ tr []
            (List.map (headerCell model) visibleOrder)
        ]


headerCell : Model -> Model.Torrent.Attribute -> Html Msg
headerCell model attribute =
    let
        attrString =
            View.Torrent.attributeToTableHeaderString
                attribute

        maybeResizeDiv =
            case fixedOrFluid model.config of
                Model.Table.Fixed ->
                    Just <| div (headerCellResizeHandleAttributes model attribute) []

                Model.Table.Fluid ->
                    Nothing
    in
    th (headerCellAttributes model attribute)
        (List.filterMap identity <|
            [ Just <|
                div (headerCellContentDivAttributes model attribute)
                    [ div [ class "content" ] [ text <| attrString ] ]
            , maybeResizeDiv
            ]
        )


headerCellAttributes : Model -> Model.Torrent.Attribute -> List (Attribute Msg)
headerCellAttributes model attribute =
    List.filterMap identity <|
        [ headerCellIdAttribute attribute
        , cellTextAlign attribute
        , headerCellSortClass model attribute
        ]


headerCellIdAttribute : Model.Torrent.Attribute -> Maybe (Attribute Msg)
headerCellIdAttribute attribute =
    Just <|
        id <|
            View.Torrent.attributeToTableHeaderId attribute


headerCellContentDivAttributes : Model -> Model.Torrent.Attribute -> List (Attribute Msg)
headerCellContentDivAttributes model attribute =
    let
        maybeWidthAttr =
            case fixedOrFluid model.config of
                Model.Table.Fixed ->
                    thWidthAttribute model.config.columnWidths attribute

                Model.Table.Fluid ->
                    Nothing
    in
    List.filterMap identity <|
        [ maybeWidthAttr
        , Just <| onClick (SetSortBy attribute)
        ]


headerCellResizeHandleAttributes : Model -> Model.Torrent.Attribute -> List (Attribute Msg)
headerCellResizeHandleAttributes _ attribute =
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
            TorrentAttributeResizeStarted
                (Model.ResizeOp.TorrentAttribute attribute)
                (reconstructClientPos e)
                e.button
                e.keys
        )
    ]


headerCellSortClass : Model -> Model.Torrent.Attribute -> Maybe (Attribute Msg)
headerCellSortClass { config } attribute =
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


body : Model -> Html Msg
body model =
    Keyed.node "tbody" [] <|
        List.filterMap
            identity
            (List.map (keyedRow model) model.sortedTorrents)


keyedRow : Model -> String -> Maybe ( String, Html Msg )
keyedRow model hash =
    case Dict.get hash model.torrentsByHash of
        Just torrent ->
            Just
                ( torrent.hash
                , lazyRow model.config model.timezone torrent
                )

        Nothing ->
            Nothing


lazyRow : Config -> Time.Zone -> Torrent -> Html Msg
lazyRow config timezone torrent =
    Html.Lazy.lazy3 row
        config
        timezone
        torrent


row : Config -> Time.Zone -> Torrent -> Html Msg
row config timezone torrent =
    let
        {--
        _ =
            Debug.log "rendering:" torrent
        --}
        visibleOrder =
            List.filter (isVisible config.visibleTorrentAttributes)
                config.torrentAttributeOrder
    in
    tr
        []
        (List.map (cell config timezone torrent) visibleOrder)


isVisible : List Model.Torrent.Attribute -> Model.Torrent.Attribute -> Bool
isVisible visibleTorrentAttributes attribute =
    List.member attribute visibleTorrentAttributes


cell : Config -> Time.Zone -> Torrent -> Model.Torrent.Attribute -> Html Msg
cell config timezone torrent attribute =
    td []
        [ div (cellAttributes config attribute)
            [ cellContent config timezone torrent attribute
            ]
        ]


cellAttributes : Config -> Model.Torrent.Attribute -> List (Attribute Msg)
cellAttributes config attribute =
    let
        maybeWidthAttr =
            case fixedOrFluid config of
                Model.Table.Fixed ->
                    tdWidthAttribute config.columnWidths attribute

                Model.Table.Fluid ->
                    Nothing
    in
    List.filterMap identity <|
        [ maybeWidthAttr
        , cellTextAlign attribute
        ]


cellTextAlign : Model.Torrent.Attribute -> Maybe (Attribute Msg)
cellTextAlign attribute =
    case View.Torrent.textAlignment attribute of
        Just _ ->
            Just <| class "text-right"

        Nothing ->
            Nothing


cellContent : Config -> Time.Zone -> Torrent -> Model.Torrent.Attribute -> Html Msg
cellContent config timezone torrent attribute =
    case attribute of
        Model.Torrent.Status ->
            torrentStatusCell torrent

        Model.Torrent.DonePercent ->
            donePercentCell torrent

        _ ->
            text <|
                View.Torrent.attributeAccessor
                    config
                    timezone
                    torrent
                    attribute


torrentStatusCell : Torrent -> Html Msg
torrentStatusCell torrent =
    case torrent.status of
        Model.Torrent.Seeding ->
            torrentStatusIcon "seeding" "fa-arrow-up"

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


thWidthAttribute : ColumnWidths -> Model.Torrent.Attribute -> Maybe (Attribute Msg)
thWidthAttribute columnWidths attribute =
    widthAttribute columnWidths attribute 10


tdWidthAttribute : ColumnWidths -> Model.Torrent.Attribute -> Maybe (Attribute Msg)
tdWidthAttribute columnWidths attribute =
    widthAttribute columnWidths attribute 8


widthAttribute : ColumnWidths -> Model.Torrent.Attribute -> Float -> Maybe (Attribute Msg)
widthAttribute columnWidths attribute subtract =
    let
        width =
            Model.Shared.getColumnWidth columnWidths
                (Model.ResizeOp.TorrentAttribute attribute)

        { auto, px } =
            width
    in
    if auto then
        Nothing

    else
        Just <| style "width" (String.fromFloat (px - subtract) ++ "px")
