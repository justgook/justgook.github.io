module Page.Home exposing (Data, request, view)

import Html exposing (Html)
import Html.Styled exposing (toUnstyled)
import Http
import Json.Decode as Decode exposing (Decoder)
import Page.Home.View as View


type alias Data =
    List
        { title : String
        , items : List ( String, String )
        }


decodeData : Decoder Data
decodeData =
    let
        decodePair =
            Decode.map2
                Tuple.pair
                (Decode.index 0 Decode.string)
                (Decode.index 1 Decode.string)

        toRecord a b =
            { title = a, items = b }

        decodeRecord =
            Decode.map2 toRecord (Decode.index 0 Decode.string)
    in
    Decode.list <| decodeRecord <| Decode.index 1 <| Decode.list decodePair


request =
    Http.get "/data/home.json" decodeData


view : Maybe Data -> Html msg
view =
    Maybe.map (View.view >> toUnstyled)
        >> Maybe.withDefault (Html.text "No Data for HOME")
