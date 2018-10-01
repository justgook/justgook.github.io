module Page.Home.View exposing (view)

import Css exposing (..)
import Html.Styled as Html exposing (Html, styled)
import Html.Styled.Attributes exposing (href)
import MmediaQueries exposing (aspectLandscape, desctopPortrait, desktop, landscape, phone, portrait, tablet)



-- https://blog.udemy.com/best-programming-language/


theme =
    { front = rgb 240 240 238
    , back1 = rgb 22 48 59
    , back2 = rgb 41 93 114
    , back3 = rgb 61 138 166
    , back4 = rgb 113 172 193
    }


page : List (Html.Attribute msg) -> List (Html msg) -> Html msg
page =
    styled Html.div
        [ color theme.front
        , desktop
            [ width (em 60)
            , left (em 30)
            , top (em 10)
            , position absolute
            , display block
            , backgroundColor theme.back2
            , (", 0 0 0 2em " ++ theme.back2.value)
                |> (++) (",0 0 0 1.1em " ++ theme.back1.value)
                |> (++) ("0 0 0 1em " ++ theme.back2.value)
                |> property "box-shadow"
            , transformStyle preserve3d
            , transforms [ rotateY (deg -0.5) ]
            , property "backface-visibility" "hidden"
            , after
                [ property "content" "''"
                , display block
                , position absolute
                , top (em -2)
                , bottom (em -2)
                , right (em -4)
                , backgroundColor (rgb 0 0 0)
                , width (em 2)
                , transforms [ rotateY (deg -90), translateZ (em 1), translateX (em -1) ]
                ]
            ]
        ]


title : List (Html.Attribute msg) -> List (Html msg) -> Html msg
title =
    styled Html.header
        [ textAlign right
        , position relative
        , backgroundColor theme.back3
        , fontSize <| em <| 4
        , padding (em 0.5)
        ]


body : List (Html.Attribute msg) -> List (Html msg) -> Html msg
body =
    styled Html.section
        [ backgroundColor theme.back1
        , position relative
        , paddingTop (em 1)
        , desktop
            [ displayFlex
            , justifyContent flexStart
            , flexFlow2 row wrap
            ]
        ]


menu t items =
    styled Html.ul
        [ marginBottom (em 0.9)
        , desktop
            [ flexBasis (em 44)
            , marginLeft (em 4)
            , flexGrow zero
            , displayFlex
            , flexFlow2 column wrap
            , justifyContent flexStart
            ]
        ]
        []
        ([ styled Html.li
            [ backgroundColor theme.front
            , color theme.back1
            , padding (em 0.5)
            ]
            []
            [ Html.text t ]
         ]
            ++ List.map subMenu items
        )


subMenu ( item, url ) =
    Html.li []
        [ styled Html.a
            [ position relative
            , display block
            , padding4 (em 0.5) zero (em 0.5) (em 2)
            , desktop
                [ cursor pointer
                , transforms [ translateZ (em 0.0000001) ]
                , hover [ color theme.back1, backgroundColor theme.front ]
                ]
            , before
                [ property "content" "''"
                , display block
                , boxSizing contentBox
                , borderLeft3 (em 0.1) solid theme.front
                , borderBottom3 (em 0.1) solid theme.front
                , position absolute
                , top zero
                , top (em -1)
                , left zero
                , width (em 2)
                , height (em 2)
                ]
            ]
            [ href url ]
            [ styled Html.span
                [ display inlineBlock
                , width (em 0.5)
                , height (em 0.5)
                , borderRadius (em 0.25)
                , backgroundColor theme.front
                , marginRight (em 0.5)
                ]
                []
                []
            , Html.text item
            ]
        ]


view mockData =
    page
        []
        [ title [] [ Html.text "Easy Way" ]
        , body []
            --Generate from Markdown titles
            (List.map (\data -> menu data.title data.items) mockData)
        ]



-- mockData =
--     [ { title = "Projects"
--       , items =
--             [ ( "WebDriver in Elm", "#/webdriver" )
--             , ( "Tiled Platformer", "/elm-platformer" )
--             , ( "Bomberman in Elm", "" )
--             , ( "React Sokoban", "" )
--             ]
--       }
--     , { title = "Research"
--       , items =
--             [ ( "Lamda WebAssembly", "" )
--             , ( "TiledMap parser", "" )
--             , ( "Full Text search https://lunrjs.com", "" )
--             ]
--       }
--     , { title = "Tutorials"
--       , items =
--             [ ( "Game Development Setup", "" )
--             , ( "Entity Component System (JavaScript(TypeScript) / Elm / Haskell / WebAssambly[walt])", "" )
--             , ( "Render Sprite (HTML, Canvas, WebGL, OpenGL)", "" )
--             , ( "Render Map (HTML, Canvas, WebGL, OpenGL)", "" )
--             , ( "Particles system (HTML, Canvas, WebGL, OpenGL)", "" )
--             , ( "Collision Detection (broad phase)", "" ) ---http://buildnewgames.com/broad-phase-collision-detection/
--             , ( "Collision Detection (SAT)", "" )
--             , ( "Multiplayer - prfotocols / encoding / bites..", "" )
--             , ( "Packaging - binary, electronjs.org", "" )
--             , ( "Publishing - github-pages, itch.io", "" )
--             , ( "Testing - unit, WebDriver, Fuzz/Quick", "" )
--             ]
--       }
--     ]
