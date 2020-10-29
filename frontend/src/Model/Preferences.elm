module Model.Preferences exposing (..)

import Model.Table



-- note this is for messages from the Preferences window.
-- actual app config itself is in Model.Config


type TablePreference
    = Layout Model.Table.Layout


type PreferenceUpdate
    = Table Model.Table.Type TablePreference
    | EnableContextMenus Bool
