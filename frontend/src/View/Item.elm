module View.Item exposing (attributeAccessor)

import Html exposing (..)
import Html.Attributes exposing (..)
import Model exposing (..)
import Model.Attribute
import Model.Item exposing (Item)
import View.Peer


attributeAccessor : Item -> Model.Attribute.Attribute -> Html Msg
attributeAccessor item attribute =
    case ( item, attribute ) of
        ( Model.Item.Peer peer, Model.Attribute.PeerAttribute peerAttribute ) ->
            View.Peer.attributeAccessor peer peerAttribute

        ( _, _ ) ->
            -- unsupported combination
            text ""
