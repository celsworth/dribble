module Update.ResetTorrentFilter exposing (update)

import Model exposing (..)
import Model.Config
import Model.TorrentFilter


update : Model -> ( Model, Cmd Msg )
update model =
    let
        newFilterConfig =
            Model.TorrentFilter.default

        newConfig =
            model.config |> Model.Config.setFilter newFilterConfig

        -- split into another Update?
        newFilter =
            Model.TorrentFilter.filterFromConfig newFilterConfig
    in
    model
        |> setConfig newConfig
        |> setTorrentFilter newFilter
        |> noCmd
