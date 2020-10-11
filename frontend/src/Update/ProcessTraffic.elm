module Update.ProcessTraffic exposing (update)

import Model exposing (..)
import Model.Traffic exposing (Traffic)



{- At app bootup, we get a traffic reading, then another one every 10 seconds.

   Each one we receive is stored in prevTraffic which will be used on the next
   iteration. The first iteration does no diffing.

   Subsequent traffics are then diffed against the previous traffic
   which is then appended to model.traffic.
-}


update : Traffic -> Model -> ( Model, Cmd Msg )
update traffic model =
    let
        prevTraffic =
            Maybe.withDefault traffic model.prevTraffic

        newPrevTraffic =
            trafficDiff traffic prevTraffic

        newTraffic =
            appendTraffic model newPrevTraffic
    in
    { model | prevTraffic = Just newPrevTraffic, traffic = newTraffic } |> noCmd


appendTraffic : Model -> Traffic -> List Traffic
appendTraffic model new =
    List.append model.traffic [ new ]


trafficDiff : Traffic -> Traffic -> Traffic
trafficDiff traffic prevTraffic =
    let
        timeDiff =
            traffic.time - prevTraffic.time
    in
    { traffic
        | upDiff = (traffic.upTotal - prevTraffic.upTotal) // timeDiff
        , downDiff = (traffic.downTotal - prevTraffic.downTotal) // timeDiff
    }
