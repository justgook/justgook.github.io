module MmediaQueries exposing (aspectLandscape, desctopPortrait, desktop, landscape, phone, portrait, tablet)

import Css exposing (..)
import Css.Media as Q
import Html.Styled exposing (div)


landscape : List Style -> Style
landscape =
    Q.withMedia [ Q.only Q.screen [ Q.orientation Q.landscape ] ]


portrait : List Style -> Style
portrait =
    Q.withMedia [ Q.only Q.screen [ Q.orientation Q.portrait ] ]


aspectLandscape =
    Q.withMedia [ Q.only Q.screen [ Q.minWidth (vh 177.778) ] ]


desktop : List Style -> Style
desktop =
    Q.withMedia [ Q.only Q.screen [ Q.minWidth (px 1024) ] ]


desctopPortrait : List Style -> Style
desctopPortrait =
    Q.withMedia [ Q.only Q.screen [ Q.minWidth (px 1024), Q.minWidth (vh (16 / 9 * 100)) ] ]


tablet : List Style -> Style
tablet =
    Q.withMedia
        [ Q.only Q.screen
            [ Q.minWidth (px 768)
            , Q.maxWidth (px 1024)

            {- , Q.orientation Q.portrait -}
            ]
        ]


phone : List Style -> Style
phone =
    Q.withMedia
        [ Q.only Q.screen
            [ Q.maxWidth (px 768)

            {- , Q.orientation Q.portrait -}
            ]
        ]



-- /* iPads (portrait) ----------- */
-- @media only screen and (min-device-width : 768px) and (max-device-width : 1024px) and (orientation : portrait) {
-- /* Styles */
-- }
-- @media only screen  and (min-width : 1224px) {
-- /* Styles */
-- }
