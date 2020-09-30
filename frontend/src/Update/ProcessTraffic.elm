module Update.ProcessTraffic exposing (update)

import Model exposing (..)
import Model.Traffic exposing (Traffic)



{- At app bootup, we get a traffic reading, then another one every 10 seconds.

   Each one we receive is stored in prevTraffic which will be used on the next
   iteration. The first iteration does no diffing.

   Subsequent traffics are then diffed against the previous traffic
   which is then appended to model.traffic.
-}


update : Traffic -> Model -> Model
update traffic model =
    let
        newTraffic =
            Maybe.map (appendTrafficDiff model traffic) model.prevTraffic
                |> Maybe.withDefault []
    in
    { model | prevTraffic = Just traffic, traffic = newTraffic }


appendTrafficDiff : Model -> Traffic -> Traffic -> List Traffic
appendTrafficDiff model traffic prevTraffic =
    List.append model.traffic [ trafficDiff traffic prevTraffic ]


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
