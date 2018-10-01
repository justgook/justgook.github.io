module Main exposing (main)

import Browser exposing (Document, UrlRequest(..))
import Browser.Navigation as Nav exposing (Key)
import Global exposing (fonts, reset)
import Html
import Html.Attributes exposing (src)
import Html.Events exposing (onClick)
import Http
import Page exposing (Page)
import Task
import Url exposing (Url)
import Url.Parser


main : Program () Model Msg
main =
    Browser.application
        { init =
            \_ url key ->
                let
                    ( page, task ) =
                        Page.fromUrl url key
                in
                ( { key = key
                  , url = url
                  , page = page
                  , prevPage = Nothing
                  }
                , wrap task
                )
        , view = view
        , update = update
        , subscriptions = \_ -> Sub.none
        , onUrlChange = UrlChanged
        , onUrlRequest = LinkClicked
        }


wrap =
    Task.attempt
        (\r ->
            case r of
                Ok data ->
                    Page data

                Err e ->
                    Error e
        )


type alias Model =
    { key : Nav.Key
    , url : Url
    , page : Page
    , prevPage : Maybe Page
    }


type Msg
    = LinkClicked Browser.UrlRequest
    | UrlChanged Url
    | Page Page
    | Error Http.Error


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        LinkClicked urlRequest ->
            case urlRequest of
                Browser.Internal url ->
                    if url /= model.url then
                        let
                            ( page, task ) =
                                Page.fromUrl url model.key
                        in
                        ( { model | url = url, page = page }
                        , Cmd.batch [ wrap task, Nav.pushUrl model.key (Url.toString url) ]
                        )

                    else
                        ( model, Cmd.none )

                Browser.External href ->
                    ( model, Nav.load href )

        UrlChanged url ->
            if url /= model.url then
                let
                    ( page, task ) =
                        Page.fromUrl url model.key
                in
                ( { model | url = url, page = page }, wrap task )

            else
                ( model, Cmd.none )

        Page page ->
            ( { model | page = page }, Cmd.none )

        Error err ->
            let
                _ =
                    Debug.log "Main.Update GOT ERROR" err
            in
            ( model, Cmd.none )


view : Model -> Document Msg
view { page } =
    { title = "Easy Path"
    , body =
        fonts
            ++ [ reset
               , Page.view page
               ]
    }
