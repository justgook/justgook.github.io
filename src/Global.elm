module Global exposing (fonts, reset)

-- import Css.Elements exposing (..)
--exposing (..)

import Css as Css
import Css.Global exposing (..)
import Html exposing (Html, node)
import Html.Attributes exposing (href, rel)
import Html.Styled as Html exposing (toUnstyled)


fonts : List (Html msg)
fonts =
    [ node "link" [ href "https://fonts.googleapis.com/css?family=Roboto:400,700&amp;subset=cyrillic", rel "stylesheet" ] []
    , node "link" [ href "https://cdnjs.cloudflare.com/ajax/libs/github-markdown-css/2.10.0/github-markdown.css", rel "stylesheet" ] []
    ]


reset =
    global
        (snippets
            ++ [ selector "html, body"
                    [ Css.padding Css.zero
                    , Css.margin Css.zero
                    , Css.backgroundColor (Css.rgb 66 66 66)
                    , Css.property "overscroll-behavior-y" "none"
                    , Css.width (Css.pct 100)
                    , Css.minHeight (Css.pct 100)
                    , Css.fontSize (Css.vw 1)
                    ]
               , selector "body"
                    [ Css.property "perspective" "250px"
                    , Css.property "perspective-origin" "right center"
                    , Css.backgroundImage (Css.url "/images/1.png")
                    , Css.backgroundRepeat Css.noRepeat
                    , Css.property "background-position" "left bottom"
                    , Css.backgroundAttachment Css.fixed
                    ]
               ]
            ++ markdown
        )
        |> toUnstyled


markdown =
    [ selector "body"
        [ Css.fontFamilies
            [ "Roboto"
            , .value Css.sansSerif
            ]
        ]
    ]


snippets : List Snippet
snippets =
    [ each
        [ html
        , body
        , div
        , span
        , selector "object"
        , selector "iframe"
        , h1
        , h2
        , h3
        , h4
        , h5
        , h6
        , p
        , selector "blockquote"
        , pre
        , a
        , selector "abbr"
        , selector "acronym"
        , selector "address"
        , selector "big"
        , selector "cite"
        , selector "code"
        , selector "del"
        , selector "dfn"
        , selector "em"
        , img
        , selector "ins"
        , selector "kbd"
        , selector "q"
        , selector "s"
        , selector "samp"
        , selector "small"
        , selector "strike"
        , strong
        , selector "sub"
        , selector "sup"
        , selector "tt"
        , selector "var"
        , selector "b"
        , selector "u"
        , selector "i"
        , selector "center"
        , selector "dl"
        , selector "dt"
        , selector "dd"
        , ol
        , ul
        , li
        , fieldset
        , form
        , label
        , legend
        , table
        , caption
        , tbody
        , tfoot
        , thead
        , tr
        , th
        , td
        , article
        , selector "aside"
        , canvas
        , selector "details"
        , selector "embed"
        , selector "figure"
        , selector "figcaption"
        , footer
        , header
        , selector "menu"
        , nav
        , selector "output"
        , selector "ruby"
        , section
        , selector "summary"
        , selector "time"
        , selector "mark"
        , selector "button"
        , audio
        , video
        ]
        [ Css.margin Css.zero
        , Css.padding Css.zero
        , Css.border Css.zero
        , Css.fontSize (Css.pct 100)
        , Css.property "font" "inherit"
        , Css.verticalAlign Css.baseline
        , Css.boxSizing Css.borderBox
        , Css.outline Css.none
        ]
    , each
        [ article
        , selector "aside"
        , selector "details"
        , selector "figcaption"
        , selector "figure"
        , footer
        , header
        , selector "menu"
        , nav
        , section
        ]
        [ Css.display Css.block ]
    , body [ Css.property "line-height" "1" ]
    , a
        [ Css.color Css.inherit
        , Css.textDecoration Css.inherit
        ]
    , each [ ol, ul ] [ Css.property "list-style" "none" ]
    , each [ selector "blockquote", selector "q" ] [ Css.property "quotes" "none" ]
    , selector "blockquote:before, blockquote:after, q:before, q:after"
        [ Css.property "content" "''"
        , Css.property "content" "none"
        ]
    , table
        [ Css.property "border-collapse" "collapse"
        , Css.property "border-spacing" "0"
        ]

    -- , selector "@import" "common.css" screen;
    , selector "@font-face"
        [ Css.property "font-family" "'Material Icons'"
        , Css.property "font-style" "normal"
        , Css.property "font-weight" "400"
        , Css.property "src" " url(https://fonts.gstatic.com/s/materialicons/v41/flUhRq6tzZclQEJ-Vdg-IuiaDsNcIhQ8tQ.woff2) format('woff2')"

        -- src: url(https://example.com/MaterialIcons-Regular.eot); /* For IE6-8 */
        -- src: local('Material Icons'),
        --     local('MaterialIcons-Regular'),
        --     url(https://example.com/MaterialIcons-Regular.woff2) format('woff2'),
        --     url(https://example.com/MaterialIcons-Regular.woff) format('woff'),
        --     url(https://example.com/MaterialIcons-Regular.ttf) format('truetype');
        ]
    ]
