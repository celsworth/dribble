module Update.ToggleTorrentAttributeVisibility exposing (update)

import List
import List.Extra
import Model exposing (..)


update : TorrentAttribute -> Model -> ( Model, Cmd Msg )
update attr model =
    let
        newVTA =
            if List.member attr model.config.visibleTorrentAttributes then
                List.Extra.remove attr model.config.visibleTorrentAttributes

            else
                -- inserts at beginning
                attr :: model.config.visibleTorrentAttributes

        config =
            model.config |> setVisibleTorrentAttributes newVTA
    in
    model
        |> setConfig config
        |> addCmd Cmd.none
