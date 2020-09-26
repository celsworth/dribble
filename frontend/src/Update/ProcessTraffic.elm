module Update.ProcessTraffic exposing (update)

import List.Extra
import Model exposing (..)


update : Traffic -> Model -> Model
update traffic model =
    let
        {- get diffs from firstTraffic if it exists. If it doesn't, store this as firstTraffic only -}
        ( firstTraffic, newTraffic ) =
            case model.firstTraffic of
                Nothing ->
                    ( traffic, [] )

                Just ft ->
                    ( ft, List.append model.traffic [ trafficDiff model traffic ] )
    in
    { model | firstTraffic = Just firstTraffic, traffic = newTraffic }


trafficDiff : Model -> Traffic -> Traffic
trafficDiff model traffic =
    let
        firstTraffic =
            Maybe.withDefault { time = 0, upDiff = 0, downDiff = 0, upTotal = 0, downTotal = 0 }
                model.firstTraffic

        prevTraffic =
            Maybe.withDefault firstTraffic (List.Extra.last model.traffic)

        timeDiff =
            traffic.time - prevTraffic.time
    in
    { traffic
        | upDiff = (traffic.upTotal - prevTraffic.upTotal) // timeDiff
        , downDiff = (traffic.downTotal - prevTraffic.downTotal) // timeDiff
    }
