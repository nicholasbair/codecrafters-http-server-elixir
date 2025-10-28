defmodule Server.Response do

  alias Server.Connection, as: Conn

  @status %{
    ok: {200, "OK"},
    created: {201, "Created"},
    not_found: {404, "Not Found"},
    server_error: {500, "Internal Server Error"}
  }

  @supported_encoding "gzip"

  @spec send(Conn.t(), atom()) :: Conn.t()
  def send(%Conn{client: client} = conn, status) do
    :ok =
      conn
      |> build_response(status)
      |> then(&:gen_tcp.send(client, &1))

    conn
  end

  @spec send(Conn.t(), atom(), String.t(), String.t()) :: Conn.t()
  def send(%Conn{client: client} = conn, status, body, content_type \\ "text/plain") do
    :ok =
      conn
      |> build_response(status, body, content_type)
      |> then(&:gen_tcp.send(client, &1))

    conn
  end

  @spec build_response(Conn.t(), atom()) :: String.t()
  defp build_response(%Conn{}, status) do
    build_response_line(status) <> "\r\n"
  end

  @spec build_response(Conn.t(), atom(), String.t(), String.t()) :: String.t()
  defp build_response(%Conn{request: %{headers: headers}}, status, body, content_type) do
    accepted_encodings = Map.get(headers, "Accept-Encoding", [])

    case should_encode_body?(accepted_encodings) do
      true ->
        encoded_body = :zlib.gzip(body)
        build_response_line(status) <> build_headers(content_type, String.length(encoded_body), [{"Content-Encoding", @supported_encoding}]) <> "\r\n#{encoded_body}"

      false ->
        build_response_line(status) <> build_headers(content_type, String.length(body)) <> "\r\n#{body}"
    end
  end

  @spec build_response_line(atom()) :: String.t()
  defp build_response_line(status) do
    {code, desc} = Map.fetch!(@status, status)
    "HTTP/1.1 #{code} #{desc}\r\n"
  end

  @spec build_headers(String.t(), integer(), [{String.t(), String.t()}]) :: String.t()
  defp build_headers(content_type, content_length, additional \\ []) do
    Enum.reduce(
      additional,
      "Content-Type: #{content_type}\r\nContent-Length: #{content_length}\r\n",
      fn {k, v}, acc ->
        acc <> "#{k}: #{v}\r\n"
      end
    )
  end

  @spec should_encode_body?([String.t()]) :: boolean()
  defp should_encode_body?(accepted_encodings) do
    @supported_encoding in accepted_encodings
  end
end
