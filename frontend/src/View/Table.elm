module View.Table exposing (..)

import DnDList
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Model exposing (..)
import Model.Attribute
import Model.Config
import Model.ContextMenu
import Model.Table exposing (Column)
import Round
import Utils.Mouse as Mouse
import View.Utils.Events


layoutToClass : Model.Table.Layout -> String
layoutToClass layout =
    case layout of
        Model.Table.Fluid ->
            "fluid"

        Model.Table.Fixed ->
            "fixed"



-- HEADER CELL HELPERS


maybeHeaderContextMenuHandler : Model.Config.Config -> Model.ContextMenu.For -> Maybe (Attribute Msg)
maybeHeaderContextMenuHandler config for =
    if config.enableContextMenus then
        Just <| Mouse.onContextMenu (\e -> DisplayContextMenu for e)

    else
        Nothing


headerContextMenuAutoWidth : Model.Attribute.Attribute -> String -> Html Msg
headerContextMenuAutoWidth attribute content =
    li [ onClick <| SetColumnAutoWidth attribute ] [ text content ]


headerContextMenuAttributeRow :
    DnDList.System c Msg
    -> DnDList.Model
    -> Int
    -> String
    -> Column c
    -> Model.Attribute.Attribute
    -> String
    -> Html Msg
headerContextMenuAttributeRow dndSystem dnd index itemId column attribute content =
    case dndSystem.info dnd of
        Just { dragIndex } ->
            if dragIndex /= index then
                headerContextMenuAttributeRowLi
                    (Just itemId)
                    column
                    attribute
                    content
                    (Just <| dndSystem.dropEvents index itemId)
                    Nothing

            else
                -- basically empty space to occupy the previous slot
                li [ id itemId ] [ text "\u{00A0}" ]

        Nothing ->
            headerContextMenuAttributeRowLi
                (Just itemId)
                column
                attribute
                content
                (Just <| dndSystem.dragEvents index itemId)
                Nothing


headerContextMenuAttributeRowLi :
    Maybe String
    -> Column c
    -> Model.Attribute.Attribute
    -> String
    -> Maybe (List (Attribute Msg))
    -> Maybe (List (Attribute Msg))
    -> Html Msg
headerContextMenuAttributeRowLi itemId column attribute content dndEvents dndStyles =
    let
        ( iClass, liClass ) =
            if column.visible then
                ( "fa-check", "" )

            else
                ( "", "disabled" )

        liAttributes =
            List.filterMap identity
                [ Just <| onClick <| ToggleAttributeVisibility attribute
                , Just <| class liClass
                , Maybe.map id itemId
                ]
                ++ Maybe.withDefault [] dndStyles
                ++ Maybe.withDefault [] dndEvents
    in
    li liAttributes
        [ div [ class "wide", View.Utils.Events.stopPropagation ]
            [ i [ class <| "icon-left fa-fw fas " ++ iClass ] []
            , text content
            ]
        , i [ class "ns-draggable icon-right fa-fw fas fa-grip-lines" ] []
        ]



-- BODY HELPERS


cellHeight : Int
cellHeight =
    21


spacerRow : String -> Int -> Maybe ( String, Html Msg )
spacerRow key px =
    if px > 0 then
        Just ( key, tr [ style "height" (String.fromInt px ++ "px") ] [] )

    else
        Nothing


headerCellRightPadding : Int
headerCellRightPadding =
    -- extra space for sort icons
    10


cellLrPadding : Int
cellLrPadding =
    4



-- CONTENT CELL HELPERS


donePercentCell : Float -> Html Msg
donePercentCell donePercent =
    let
        dp =
            if donePercent == 100 then
                0

            else
                1
    in
    div [ class "progress-container" ]
        [ progress
            [ class "progress"
            , Html.Attributes.max "100"
            , Html.Attributes.value <| Round.round 0 donePercent
            ]
            []
        , span [ class "progress-text" ]
            [ text (Round.round dp donePercent ++ "%") ]
        ]



{- WIDTH HELPERS -}


thWidthAttribute : Column c -> Maybe (Attribute Msg)
thWidthAttribute column =
    -- 2px extra for left/right border
    widthAttribute column (2 + cellLrPadding + headerCellRightPadding)


tdWidthAttribute : Column c -> Maybe (Attribute Msg)
tdWidthAttribute column =
    widthAttribute column (cellLrPadding * 2)


widthAttribute : Column c -> Int -> Maybe (Attribute Msg)
widthAttribute column subtract =
    if column.auto then
        Nothing

    else
        Just <| style "width" (Round.round 1 (column.width - toFloat subtract) ++ "px")
