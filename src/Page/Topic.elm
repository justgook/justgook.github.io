module Page.Topic exposing (Data, request, view)

-- import Element.Background as Background
-- import Element.Border as Border

import Element exposing (Element, alignRight, el, rgb, row, text)
import Html exposing (Html)
import Html.Attributes exposing (class, style)
import Http
import Json.Decode as Decode exposing (Decoder)
import Mark
import Markdown


type alias Data =
    String


request path =
    Http.getString ("/data/" ++ path ++ ".md")



--decodeData
-- Http.getString "/data/README.md"


decodeData =
    Decode.string


view : Maybe Data -> Html msg
view =
    let
        options =
            { githubFlavored = Just { tables = True, breaks = False }
            , defaultHighlighting = Nothing
            , sanitize = False
            , smartypants = True
            }

        oldStuff =
            Markdown.toHtmlWith options
                [ class "markdown-body"
                , style "background-color" "#FAFAFA"
                , style "width" "60em"
                , style "margin" "0 auto"
                , style "padding" "3em"
                ]
    in
    Maybe.map oldStuff
        >> Maybe.withDefault (Html.text "No Data for Topic")
