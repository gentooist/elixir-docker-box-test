defmodule Router do
  use Plug.Router
  use Witchcraft
  import Witchcraft.Chain
  import Algae.Maybe

  plug Plug.Logger
  plug :match
  plug :dispatch

  def init(options) do
    # initialize options

    options
  end

  def get_response_body(response) do
    case response do
      {:ok, %Tesla.Env{ body: body }} -> from_nillable(body)
      _ -> Algae.Maybe.Nothing.new()
    end
  end

  def get_users() do
    Box.client() |> Box.users() |> get_response_body()
  end

  def get_user_ids(users) do
    Enum.map(users["entries"], fn entry -> entry["id"] end)
  end

  get "/" do
    page_contents = EEx.eval_file(Path.join([__DIR__, "..", "..", "templates", "index.eex"]))
    conn
    |> put_resp_content_type("text/html")
    |> send_resp(200, page_contents)
  end

  get "/token" do
    token = BoxClient.Managed.get_access_token()
    {:ok, json} = Poison.encode(%{access_token: token[:access_token], expires: token[:expires]})
    conn
    |> put_resp_content_type("text/json")
    |> send_resp(200, json)
  end

  get "/token/:user_id" do
    token = BoxClient.Managed.get_access_token(user_id)
    {:ok, json} = Poison.encode(%{access_token: token[:access_token], expires: token[:expires]})
    conn
    |> put_resp_content_type("text/json")
    |> send_resp(200, json)
  end

  get "/users" do
    {:ok, %Tesla.Env{ body: body }} = Box.client() |> Box.users()
    {:ok, json} = Poison.encode(body)
    conn
    |> put_resp_content_type("text/json")
    |> send_resp(200, json)
  end

  get "/hello/:name" do
    {:ok, json} = Poison.encode(%{"hello" => name})
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, json)
  end

  get "/hello" do
    {:ok, json} = Poison.encode(%{"hello" => "world"})
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, json)
  end

  match _ do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(404, Poison.encode!(%{"error" => "not_found"}))
  end
end
