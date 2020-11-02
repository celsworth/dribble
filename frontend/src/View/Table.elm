module View.Table exposing (..)

import DnDList
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Html.Events.Extra.Mouse as Mouse
import Json.Decode as D
import Model exposing (..)
import Model.Attribute
import Model.Config
import Model.ContextMenu
import Model.MousePosition
import Model.Table exposing (Column)
import Round
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
        Just <|
            Mouse.onContextMenu
                (\e ->
                    DisplayContextMenu
                        for
                        (Model.MousePosition.reconstructClientPos e)
                        e.button
                        e.keys
                )

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
        [ div [ class "flex-grow", View.Utils.Events.stopPropagation ]
            [ i [ class <| "check fa-fw fas " ++ iClass ] []
            , text content
            ]
        , i [ class "ns-draggable fa-fw fas fa-grip-lines" ] []
        ]



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



{-
   WIDTH HELPERS

   this complication is because the width stored in columnWidths
   includes padding and borders. To set the proper size for the
   internal div, we need to subtract some:

   For th columns, that amounts to 16px:
     1 + 1px borders
     4px left padding
     10px right padding

   For td, there are no borders, so its just 2*4px padding to remove
-}


thWidthAttribute : Column c -> Maybe (Attribute Msg)
thWidthAttribute column =
    widthAttribute column 16


tdWidthAttribute : Column c -> Maybe (Attribute Msg)
tdWidthAttribute column =
    widthAttribute column 8


widthAttribute : Column c -> Float -> Maybe (Attribute Msg)
widthAttribute column subtract =
    if column.auto then
        Nothing

    else
        Just <| style "width" (Round.round 1 (column.width - subtract) ++ "px")
