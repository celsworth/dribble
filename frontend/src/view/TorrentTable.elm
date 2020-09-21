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
import Round
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
    th (headerCellAttributes model attribute)
        [ div (headerCellContentDivAttributes model attribute)
            [ div [ class "content" ] [ text <| attrString ] ]
        , div (headerCellDragBarAttributes model attribute)
            []
        ]


headerCellAttributes : Model -> TorrentAttribute -> List (Attribute Msg)
headerCellAttributes model attribute =
    List.filterMap identity <|
        [ headerCellIdAttribute attribute
        , cellTextAlign attribute
        , headerCellSortClass model attribute
        ]


headerCellIdAttribute : TorrentAttribute -> Maybe (Attribute Msg)
headerCellIdAttribute attribute =
    Just <|
        id <|
            Model.Utils.TorrentAttribute.attributeToTableHeaderId attribute


headerCellContentDivAttributes : Model -> TorrentAttribute -> List (Attribute Msg)
headerCellContentDivAttributes model attribute =
    List.filterMap identity <|
        [ Just <| class "size"
        , thWidthAttribute model.config.columnWidths attribute
        , Just <| onClick (SetSortBy attribute)
        ]


headerCellDragBarAttributes : Model -> TorrentAttribute -> List (Attribute Msg)
headerCellDragBarAttributes _ attribute =
    [ class "dragbar"
    , Html.Events.Extra.Mouse.onDown
        (\event -> MouseDownMsg attribute event.clientPos event.keys)
    ]


headerCellSortClass : Model -> TorrentAttribute -> Maybe (Attribute Msg)
headerCellSortClass { config } attribute =
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
    {- just pass in what the row actually needs so lazy can look at
       as little as possible. this will help when some config changes,
       but not the config related to rendering the row, eg sortBy is
       not relevant here and would make resorting slower
    -}
    Html.Lazy.lazy5 row
        config.visibleTorrentAttributes
        config.torrentAttributeOrder
        config.columnWidths
        config.filesizeSettings
        torrent


row : List TorrentAttribute -> List TorrentAttribute -> ColumnWidths -> Utils.Filesize.Settings -> Torrent -> Html Msg
row visibleTorrentAttributes torrentAttributeOrder columnWidths filesizeSettings torrent =
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
        (List.map (cell columnWidths filesizeSettings torrent) visibleOrder)


isVisible : List TorrentAttribute -> TorrentAttribute -> Bool
isVisible visibleTorrentAttributes attribute =
    List.member attribute visibleTorrentAttributes


cell : ColumnWidths -> Utils.Filesize.Settings -> Torrent -> TorrentAttribute -> Html Msg
cell columnWidths filesizeSettings torrent attribute =
    td []
        [ div (cellAttributes columnWidths attribute)
            [ cellContent filesizeSettings torrent attribute
            ]
        ]


cellAttributes : ColumnWidths -> TorrentAttribute -> List (Attribute Msg)
cellAttributes columnWidths attribute =
    List.filterMap identity <|
        [ tdWidthAttribute columnWidths attribute
        , cellTextAlign attribute
        ]


cellTextAlign : TorrentAttribute -> Maybe (Attribute Msg)
cellTextAlign attribute =
    case Model.Utils.TorrentAttribute.textAlignment attribute of
        Just str ->
            Just <| class "text-right"

        Nothing ->
            Nothing


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



{-
   WIDTH HELPERS

   this complication is because the width stored in columnWidths
   includes padding and borders.

   For th columns, that amounts to 10px (4px padding, 1px border)

   For td, there are no borders, so its just 4px padding to remove
-}


thWidthAttribute : ColumnWidths -> TorrentAttribute -> Maybe (Attribute Msg)
thWidthAttribute columnWidths attribute =
    widthAttribute columnWidths attribute 10


tdWidthAttribute : ColumnWidths -> TorrentAttribute -> Maybe (Attribute Msg)
tdWidthAttribute columnWidths attribute =
    widthAttribute columnWidths attribute 8


widthAttribute : ColumnWidths -> TorrentAttribute -> Float -> Maybe (Attribute Msg)
widthAttribute columnWidths attribute subtract =
    let
        width =
            Model.Shared.getColumnWidth columnWidths attribute

        { auto, px } =
            width
    in
    if auto then
        Nothing

    else
        Just <| style "width" (String.fromFloat (px - subtract) ++ "px")
