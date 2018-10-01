module Page exposing (Page, fromUrl, view)

import Browser.Navigation as Nav exposing (Key)
import Html
import Http
import Page.Home as Home
import Page.Topic as Topic
import Task
import Url exposing (Url)
import Url.Parser exposing ((</>), Parser, custom, int, map, oneOf, s, string, top)


type Page
    = Home (Maybe Home.Data)
    | Topic (Maybe Topic.Data)
    | NotFound


fromUrl url key =
    if url.path == "/" then
        ( Home Nothing, Http.toTask Home.request |> Task.map (Home << Just) )

    else
        ( Topic Nothing, Topic.request url.path |> Http.toTask |> Task.map (Topic << Just) )


view page =
    case page of
        Home data ->
            Home.view data

        Topic data ->
            Topic.view data

        _ ->
            Html.text "Unknown page"
