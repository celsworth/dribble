module View.SpeedChart exposing (view)

import DateFormat
import Html exposing (..)
import Html.Attributes exposing (..)
import LineChart
import LineChart.Area
import LineChart.Axis
import LineChart.Axis.Intersection
import LineChart.Axis.Line
import LineChart.Axis.Range
import LineChart.Axis.Tick
import LineChart.Axis.Ticks
import LineChart.Axis.Title
import LineChart.Axis.Values
import LineChart.Colors
import LineChart.Container
import LineChart.Coordinate
import LineChart.Dots
import LineChart.Events
import LineChart.Grid
import LineChart.Interpolation
import LineChart.Junk
import LineChart.Legends
import LineChart.Line
import List.Extra
import Model exposing (..)
import Time
import Utils.Filesize


view : Model -> Html Msg
view model =
    aside [ class "speed-chart" ] [ chart model ]


chart : Model -> Html Msg
chart model =
    let
        filteredTraffic =
            filterTraffic model.traffic

        upload =
            List.map (toDataSeries .upDiff) filteredTraffic

        download =
            List.map (toDataSeries .downDiff) filteredTraffic
    in
    LineChart.viewCustom (config model)
        [ LineChart.line LineChart.Colors.green LineChart.Dots.none "Upload" upload
        , LineChart.line LineChart.Colors.blue LineChart.Dots.none "Download" download
        ]


filterTraffic : List Traffic -> List Traffic
filterTraffic traffic =
    let
        {- bodge: use last traffic time as current time.
           ideally we'd get Time.now from elm
        -}
        now =
            List.Extra.last traffic
                |> Maybe.andThen (Just << .time)
                |> Maybe.withDefault 0

        limit =
            {- keep 10 minutes for now -}
            now - 600
    in
    List.filterMap (newerThan limit) traffic


newerThan : Int -> Traffic -> Maybe Traffic
newerThan limit traffic =
    if traffic.time > limit then
        Just traffic

    else
        Nothing


toDataSeries : (Traffic -> Int) -> Traffic -> DataSeries
toDataSeries method traffic =
    { speed = method traffic

    {- time needs to be in millis -}
    , time = traffic.time * 1000
    }


filesizeSettings : Model -> Utils.Filesize.Settings
filesizeSettings model =
    let
        f =
            model.config.filesizeSettings
    in
    -- always use Base10 for transfer speeds
    { f | units = Utils.Filesize.Base10, decimalPlaces = 1 }


config : Model -> LineChart.Config DataSeries Msg
config model =
    { y = yAxisConfig model
    , x = xAxisConfig model
    , container = containerConfig
    , interpolation = LineChart.Interpolation.monotone
    , intersection = LineChart.Axis.Intersection.atOrigin
    , legends = LineChart.Legends.grouped .max .min -120 -70
    , events = LineChart.Events.hoverMany SpeedChartHover
    , junk = LineChart.Junk.hoverMany model.speedChartHover (formatX model) (formatY model)
    , grid = LineChart.Grid.default
    , area = LineChart.Area.default
    , line = LineChart.Line.wider 3
    , dots = LineChart.Dots.default
    }


formatX : Model -> DataSeries -> String
formatX model ds =
    formatTime model (Time.millisToPosix ds.time)


formatY : Model -> DataSeries -> String
formatY model ds =
    Utils.Filesize.formatWith (filesizeSettings model) ds.speed ++ "/s"


containerConfig : LineChart.Container.Config msg
containerConfig =
    LineChart.Container.custom
        { attributesHtml = []
        , attributesSvg = []
        , size = LineChart.Container.relative
        , margin = LineChart.Container.Margin 25 20 20 80
        , id = "speed-chart"
        }


yAxisConfig : Model -> LineChart.Axis.Config DataSeries msg
yAxisConfig model =
    LineChart.Axis.custom
        { title = LineChart.Axis.Title.default ""
        , variable = Just << toFloat << .speed
        , pixels = 500

        --, range = LineChart.Axis.Range.default
        , range = LineChart.Axis.Range.custom customYRange
        , axisLine = LineChart.Axis.Line.default
        , ticks = yTicksConfig model
        }


customYRange : LineChart.Coordinate.Range -> LineChart.Coordinate.Range
customYRange { min, max } =
    {-
       {-
          Doesn't work very well, ticks drawn do not account for the updated
          range, and working out tick spacing manually looks difficult.
          One to try later.
       -}
       let
           max2 =
               if max < 5000 then
                   5000

               else
                   max
       in
    -}
    { min = min, max = max * 1.04 }


yTicksConfig : Model -> LineChart.Axis.Ticks.Config msg
yTicksConfig model =
    LineChart.Axis.Ticks.intCustom 5 (yTickConfig model)


yTickConfig : Model -> Int -> LineChart.Axis.Tick.Config msg
yTickConfig model speed =
    let
        humanSpeed =
            Utils.Filesize.formatWith (filesizeSettings model) speed ++ "/s"

        label =
            LineChart.Junk.label LineChart.Colors.black humanSpeed
    in
    LineChart.Axis.Tick.custom
        { position = toFloat speed
        , color = LineChart.Colors.gray
        , width = 1
        , length = 2
        , grid = True
        , direction = LineChart.Axis.Tick.negative
        , label = Just label
        }


xAxisConfig : Model -> LineChart.Axis.Config DataSeries msg
xAxisConfig model =
    LineChart.Axis.custom
        { title = LineChart.Axis.Title.default ""
        , variable = Just << toFloat << .time
        , pixels = 1200
        , range = LineChart.Axis.Range.default
        , axisLine = LineChart.Axis.Line.default
        , ticks = xTicksConfig model
        }


xTicksConfig : Model -> LineChart.Axis.Ticks.Config msg
xTicksConfig model =
    -- not actually sure this model.timezone does anything..
    LineChart.Axis.Ticks.timeCustom model.timezone 8 (xTickConfig model)


xTickConfig : Model -> LineChart.Axis.Tick.Time -> LineChart.Axis.Tick.Config msg
xTickConfig model time =
    let
        label =
            LineChart.Junk.label LineChart.Colors.black <|
                formatTime model time.timestamp
    in
    LineChart.Axis.Tick.custom
        { position = toFloat (Time.posixToMillis time.timestamp)
        , color = LineChart.Colors.gray
        , width = 1
        , length = 2
        , grid = True
        , direction = LineChart.Axis.Tick.negative
        , label = Just label
        }


formatter : Time.Zone -> Time.Posix -> String
formatter =
    DateFormat.format
        [ DateFormat.hourMilitaryFixed
        , DateFormat.text ":"
        , DateFormat.minuteFixed
        , DateFormat.text ":"
        , DateFormat.secondFixed
        ]


formatTime : Model -> Time.Posix -> String
formatTime model time =
    formatter model.timezone time
