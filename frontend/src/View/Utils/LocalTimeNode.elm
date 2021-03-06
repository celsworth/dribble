module View.Utils.LocalTimeNode exposing (nonZeroView, view)

import Html exposing (Html, node, text)
import Html.Attributes exposing (attribute)


view : Int -> Html msg
view time =
    {- these get replaced with local time in the browser by Intl.DateTimeFormat,
       so they have no content here.

       Also it might seem preferable to pass in a Time.Posix, but Posix is not
       comparable, and a big part of this app is sorting the Torrents table.
       It's just easier to leave times as ints without converting back and forth
       from Posix to pass into methods like this one.
    -}
    node "local-time"
        [ attribute "posix" (String.fromInt time) ]
        []


nonZeroView : Int -> Html msg
nonZeroView time =
    if time == 0 then
        text ""

    else
        view time
