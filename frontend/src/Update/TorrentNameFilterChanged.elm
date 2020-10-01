module Update.TorrentNameFilterChanged exposing (update)

import Model exposing (..)
import Model.TorrentFilter exposing (TorrentFilter)


update : String -> Model -> ( Model, Cmd Msg )
update value model =
    let
        filter =
            model.torrentFilter

        newFilter =
            filter |> Model.TorrentFilter.setName (Just value)
    in
    model
        |> setTorrentFilter newFilter
        |> addCmd Cmd.none
