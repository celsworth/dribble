module View.TorrentTable exposing (..)

import Dict
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick, onMouseDown)
import Html.Events.Extra.Mouse
import Html.Keyed as Keyed
import Html.Lazy
import Model exposing (..)
import Model.Shared
import Model.Utils.TorrentAttribute
import Utils.Filesize


view : Model -> Html Msg
view model =
    table []
        (List.concat
            [ [ header model ]
            , [ body model ]
            ]
        )


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


headerCell : Model -> TorrentAttribute -> Html Msg
headerCell model attribute =
    let
        attrString =
            Model.Utils.TorrentAttribute.attributeToTableHeaderString
                attribute
    in
    th (headerCellAttributes model.config attribute)
        [ span (headerCellSpanAttributes model attribute)
            [ text <| attrString ]
        , div
            [ Html.Events.Extra.Mouse.onDown
                (\event -> MouseDownMsg attribute event.clientPos)
            ]
            []
        ]


headerCellSpanAttributes : Model -> TorrentAttribute -> List (Attribute Msg)
headerCellSpanAttributes model attribute =
    [ onClick (SetSortBy attribute)
    ]


headerCellWidth : Model -> TorrentAttribute -> Attribute Msg
headerCellWidth model attribute =
    let
        width =
            Model.Shared.getColumnWidth model attribute
    in
    style "width" (String.fromFloat width ++ "px")


headerCellAttributes : Config -> TorrentAttribute -> List (Attribute Msg)
headerCellAttributes config attribute =
    List.filterMap identity <|
        [ cellTextAlign attribute
        , headerCellSortClass config attribute
        ]


headerCellSortClass : Config -> TorrentAttribute -> Maybe (Attribute Msg)
headerCellSortClass config attribute =
    let
        (SortBy currentSortAttribute currentSortDirection) =
            config.sortBy
    in
    if currentSortAttribute == attribute then
        case currentSortDirection of
            Asc ->
                Just <| class "sorted ascending"

            Desc ->
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
                , lazyRow model.config torrent
                )

        Nothing ->
            Nothing


lazyRow : Config -> Torrent -> Html Msg
lazyRow config torrent =
    -- just pass in what the row actually needs so lazy can look at
    -- as little as possible. this will help when some config changes,
    -- but not the config related to rendering the row.
    Html.Lazy.lazy5 row
        config.columnWidths
        config.visibleTorrentAttributes
        config.torrentAttributeOrder
        config.filesizeSettings
        torrent


row : ColumnWidths -> List TorrentAttribute -> List TorrentAttribute -> Utils.Filesize.Settings -> Torrent -> Html Msg
row columnWidths visibleTorrentAttributes torrentAttributeOrder filesizeSettings torrent =
    let
        {--
        x =
            Debug.log "rendering:" torrent

        --}
        visibleOrder =
            List.filter (isVisible visibleTorrentAttributes)
                torrentAttributeOrder
    in
    tr
        []
        (List.map (cell filesizeSettings torrent) visibleOrder)


isVisible : List TorrentAttribute -> TorrentAttribute -> Bool
isVisible visibleTorrentAttributes attribute =
    List.member attribute visibleTorrentAttributes


cell : Utils.Filesize.Settings -> Torrent -> TorrentAttribute -> Html Msg
cell filesizeSettings torrent attribute =
    td (cellAttributes attribute)
        [ cellContent filesizeSettings torrent attribute
        ]


cellContent : Utils.Filesize.Settings -> Torrent -> TorrentAttribute -> Html Msg
cellContent filesizeSettings torrent attribute =
    if attribute == DonePercent then
        donePercentCell torrent

    else
        text <|
            Model.Utils.TorrentAttribute.attributeAccessor
                filesizeSettings
                torrent
                attribute


donePercentCell : Torrent -> Html Msg
donePercentCell torrent =
    progress
        [ Html.Attributes.max "100"
        , Html.Attributes.value <| String.fromFloat torrent.donePercent
        ]
        [ text (String.fromFloat torrent.donePercent ++ "%") ]


cellAttributes : TorrentAttribute -> List (Attribute Msg)
cellAttributes attribute =
    List.filterMap identity <|
        [ cellTextAlign attribute
        ]


cellTextAlign : TorrentAttribute -> Maybe (Attribute Msg)
cellTextAlign attribute =
    case Model.Utils.TorrentAttribute.textAlignment attribute of
        Just str ->
            Just <| class "text-right"

        Nothing ->
            Nothing
