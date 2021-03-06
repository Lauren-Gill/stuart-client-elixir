defmodule StuartClientElixir.HttpClient do
  alias StuartClientElixir.{Environment, Authenticator}

  @typep url :: binary()
  @typep body :: map()
  @typep options :: map()
  @typep ok_response :: {:ok, map()}
  @typep error_response :: {:error, binary() | map()}

  @callback get(url, options) :: ok_response | error_response
  @callback post(url, body, options) :: ok_response | error_response

  def get(resource, %{environment: environment, credentials: credentials}) do
    with url <- url(resource, environment),
         {:ok, access_token} <- Authenticator.access_token(environment, credentials),
         headers <- default_headers(access_token) do
      HTTPoison.get(url, headers)
      |> to_api_response()
    else
      {:error, %OAuth2.Response{}} = oauth_error -> to_api_response(oauth_error)
    end
  end

  def post(resource, body, %{environment: environment, credentials: credentials}) do
    with url <- url(resource, environment),
         {:ok, access_token} <- Authenticator.access_token(environment, credentials),
         headers <- default_headers(access_token) do
      HTTPoison.post(url, body, headers)
      |> to_api_response()
    else
      {:error, %OAuth2.Response{}} = oauth_error -> to_api_response(oauth_error)
    end
  end

  #####################
  # Private functions #
  #####################

  defp url(resource, %Environment{base_url: base_url}), do: "#{base_url}#{resource}"

  defp default_headers(access_token) do
    [
      Authorization: "Bearer #{access_token}",
      "User-Agent": "stuart-client-elixir/#{Application.spec(:stuart_client_elixir, :vsn)}",
      "Content-Type": "application/json"
    ]
  end

  defp to_api_response({:ok, %HTTPoison.Response{status_code: status_code, body: body}}) do
    %{status_code: status_code, body: Jason.decode!(body)}
  end

  defp to_api_response({:error, %HTTPoison.Error{} = error}) do
    {:error, error}
  end

  defp to_api_response({:error, %OAuth2.Response{status_code: status_code, body: body}}) do
    %{status_code: status_code, body: body}
  end
end
