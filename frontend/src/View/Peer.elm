module View.Peer exposing (attributeAccessor)

import Html exposing (..)
import Html.Attributes exposing (..)
import Model exposing (..)
import Model.Config
import Model.Peer exposing (Peer)
import Round
import Utils.Filesize
import View.Utils.LocalTimeNode


attributeAccessor : Peer -> Model.Peer.Attribute -> Html Msg
attributeAccessor peer attribute =
    text ""
