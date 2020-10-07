module View.SpeedChart exposing (view)

import DateFormat
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Lazy
import LineChart
import LineChart.Area
import LineChart.Axis
import LineChart.Axis.Intersection
import LineChart.Axis.Line
import LineChart.Axis.Range
import LineChart.Axis.Tick
import LineChart.Axis.Ticks
import LineChart.Axis.Title
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
import Model.SpeedChart exposing (DataSeries)
import Model.Traffic exposing (Traffic)
import Time
import Utils.Filesize


view : Model -> Html Msg
view model =
    aside
        [ class "speed-chart" ]
        [ lazyChart
            model.traffic
            model.speedChartHover
            model.timezone
            model.config.humanise.speed
        ]


lazyChart : List Traffic -> List DataSeries -> Time.Zone -> Utils.Filesize.Settings -> Html Msg
lazyChart traffic hover timezone hSpeedSettings =
    Html.Lazy.lazy4 chart traffic hover timezone hSpeedSettings


chart : List Traffic -> List DataSeries -> Time.Zone -> Utils.Filesize.Settings -> Html Msg
chart traffic hover timezone hSpeedSettings =
    let
        filteredTraffic =
            filterTraffic traffic

        upload =
            List.map (toSpeedChartDataSeries .upDiff) filteredTraffic

        download =
            List.map (toSpeedChartDataSeries .downDiff) filteredTraffic
    in
    LineChart.viewCustom (config hover timezone hSpeedSettings)
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
                |> Maybe.andThen (.time >> Just)
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


toSpeedChartDataSeries : (Traffic -> Int) -> Traffic -> DataSeries
toSpeedChartDataSeries method traffic =
    { speed = method traffic

    {- time needs to be in millis -}
    , time = traffic.time * 1000
    }


config : List DataSeries -> Time.Zone -> Utils.Filesize.Settings -> LineChart.Config DataSeries Msg
config hover timezone hSpeedSettings =
    { y = yAxisConfig hSpeedSettings
    , x = xAxisConfig timezone
    , container = containerConfig
    , interpolation = LineChart.Interpolation.monotone
    , intersection = LineChart.Axis.Intersection.atOrigin
    , legends = LineChart.Legends.grouped .min .min 10 -50
    , events = LineChart.Events.hoverMany SpeedChartHover
    , junk =
        LineChart.Junk.hoverMany
            hover
            (formatHoverX timezone)
            (formatHoverY hSpeedSettings)
    , grid = LineChart.Grid.default
    , area = LineChart.Area.default
    , line = LineChart.Line.wider 3
    , dots = LineChart.Dots.default
    }


formatHoverX : Time.Zone -> DataSeries -> String
formatHoverX timezone ds =
    formatTime timezone (Time.millisToPosix ds.time)


formatHoverY : Utils.Filesize.Settings -> DataSeries -> String
formatHoverY hSpeedSettings ds =
    Utils.Filesize.formatWith hSpeedSettings ds.speed ++ "/s"


containerConfig : LineChart.Container.Config msg
containerConfig =
    LineChart.Container.custom
        { attributesHtml = []
        , attributesSvg = []
        , size = LineChart.Container.relative
        , margin = LineChart.Container.Margin 40 30 20 80
        , id = "speed-chart"
        }



--- Y AXIS


yAxisConfig : Utils.Filesize.Settings -> LineChart.Axis.Config DataSeries msg
yAxisConfig hSpeedSettings =
    LineChart.Axis.custom
        { title = LineChart.Axis.Title.default ""
        , variable = .speed >> toFloat >> Just
        , pixels = 500
        , range = LineChart.Axis.Range.custom (yAxisRange hSpeedSettings)
        , axisLine = LineChart.Axis.Line.default
        , ticks = yTicksConfig hSpeedSettings
        }


yAxisRange : Utils.Filesize.Settings -> LineChart.Coordinate.Range -> LineChart.Coordinate.Range
yAxisRange hSpeedSettings { max } =
    let
        max2 =
            if max < 5000 then
                5000

            else
                max
    in
    { min = 0, max = nextYAxisPoint hSpeedSettings max2 }


yTicksConfig : Utils.Filesize.Settings -> LineChart.Axis.Ticks.Config msg
yTicksConfig hSpeedSettings =
    LineChart.Axis.Ticks.custom <|
        \dataRange _ ->
            List.map (yTickConfig hSpeedSettings) (yTicks hSpeedSettings dataRange)


yTicks : Utils.Filesize.Settings -> LineChart.Coordinate.Range -> List Int
yTicks hSpeedSettings dataRange =
    let
        maxTick =
            nextYAxisPoint hSpeedSettings dataRange.max
    in
    [ 0
    , round (maxTick * 0.2)
    , round (maxTick * 0.4)
    , round (maxTick * 0.6)
    , round (maxTick * 0.8)
    , round maxTick
    ]


nextYAxisPoint : Utils.Filesize.Settings -> Float -> Float
nextYAxisPoint hSpeedSettings int =
    let
        default =
            case hSpeedSettings.units of
                Utils.Filesize.Base2 ->
                    10240

                Utils.Filesize.Base10 ->
                    10000
    in
    List.Extra.find (\n -> int < n) (yTickPoints hSpeedSettings)
        |> Maybe.withDefault default


yTickMultis : Utils.Filesize.Settings -> List Float
yTickMultis hSpeedSettings =
    case hSpeedSettings.units of
        Utils.Filesize.Base2 ->
            [ 1024, 10240, 102400, 1048576, 10485760 ]

        Utils.Filesize.Base10 ->
            [ 1000, 10000, 100000, 1000000, 10000000 ]


yTickPoints : Utils.Filesize.Settings -> List Float
yTickPoints hSpeedSettings =
    yTickMultis hSpeedSettings
        |> List.Extra.andThen
            (\m ->
                [ 10, 15, 20, 25, 30, 40, 50, 60, 80 ]
                    |> List.Extra.andThen (\p -> [ p * m ])
            )


yTickConfig : Utils.Filesize.Settings -> Int -> LineChart.Axis.Tick.Config msg
yTickConfig hSpeedSettings speed =
    let
        humanSpeed =
            Utils.Filesize.formatWith hSpeedSettings speed ++ "/s"

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



--- X AXIS


xAxisConfig : Time.Zone -> LineChart.Axis.Config DataSeries msg
xAxisConfig timezone =
    LineChart.Axis.custom
        { title = LineChart.Axis.Title.default ""
        , variable = .time >> toFloat >> Just
        , pixels = 1200
        , range = LineChart.Axis.Range.default
        , axisLine = LineChart.Axis.Line.default
        , ticks = xTicksConfig timezone
        }


xTicksConfig : Time.Zone -> LineChart.Axis.Ticks.Config msg
xTicksConfig timezone =
    -- not actually sure this model.timezone does anything..
    LineChart.Axis.Ticks.timeCustom timezone 8 (xTickConfig timezone)


xTickConfig : Time.Zone -> LineChart.Axis.Tick.Time -> LineChart.Axis.Tick.Config msg
xTickConfig timezone time =
    let
        label =
            LineChart.Junk.label LineChart.Colors.black <|
                formatTime timezone time.timestamp
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


formatTime : Time.Zone -> Time.Posix -> String
formatTime timezone time =
    formatter timezone time
