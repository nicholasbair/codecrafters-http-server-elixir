defmodule Server.Request do

  alias Server.Connection, as: Conn

  @type t :: %__MODULE__{
    method: String.t(),
    request_target: String.t(),
    protocol: String.t(),
    body: String.t(),
    state: state(),
    headers: headers()
  }

  @type header :: String.t() | [String.t()]
  @type headers :: %{optional(String.t()) => header()}

  @type action :: :continue | :complete
  @type state :: :request_line_complete | :headers_complete | {:headers_complete, non_neg_integer()}

  defstruct [
    :method,
    :request_target,
    :protocol,
    :state,
    body: "",
    headers: %{}
  ]

  @spec handle_request(Conn.t()) :: {Conn.t(), action()}
  def handle_request(%Conn{request: req} = conn) do
    bytes = get_bytes(req.state)
    new_line = read_data(conn.client, bytes)
    {updated_req, action} = parse_line(req, new_line)

    {
      %{conn |
        raw_request: conn.raw_request <> new_line,
        request: updated_req,
        keep_alive?: keep_alive?(updated_req)
      },
      action
    }
  end

  @spec read_data(port(), nil | non_neg_integer()) :: String.t()
  defp read_data(socket, nil), do: read_line(socket)
  defp read_data(socket, bytes), do: read_bytes(socket, bytes)

  @spec read_line(port()) :: String.t()
  defp read_line(socket) do
    {:ok, data} = :gen_tcp.recv(socket, 0)
    data
  end

  @spec read_bytes(port(), non_neg_integer()) :: String.t()
  defp read_bytes(socket, need_bytes) do
    :ok = :inet.setopts(socket, packet: 0)
    {:ok, data} = :gen_tcp.recv(socket, need_bytes, 5_000)
    data
  end

  @spec parse_line(t(), String.t()) :: {t(), action()}
  def parse_line(%__MODULE__{method: nil, request_target: nil, protocol: nil}, new_line) do
    {method, target, protocol} = parse_method_target_protocol(new_line)

    {%__MODULE__{
      method: method,
      request_target: target,
      protocol: protocol,
      state: :request_line_complete
    }, :continue}
  end

  def parse_line(%__MODULE__{method: "GET"} = req, "\r\n") do
    {req, :complete}
  end

  def parse_line(%__MODULE__{method: method, body: ""} = req, "\r\n") when method in ["POST", "PUT", "PATCH"] do
    case Map.get(req.headers, "Content-Length") do
      nil -> {req, :complete}
      need_bytes -> {%{req | state: {:headers_complete, need_bytes}}, :continue}
    end
  end

  def parse_line(%__MODULE__{state: :request_line_complete} = req, new_line) do
    {k, v} = parse_header(new_line)
    {%{req | headers: Map.put(req.headers, k, v)}, :continue}
  end

  def parse_line(%__MODULE__{method: method, state: {:headers_complete, _bytes}} = req, new_line) when method in ["POST", "PUT", "PATCH"] do
    content_length = Map.get(req.headers, "Content-Length")
    updated_body = req.body <> new_line
    curr_bytes = String.length(updated_body)

    case curr_bytes >= content_length do
      true ->
        {%{req | body: updated_body}, :complete}
      false ->
        {%{req | body: updated_body, state: {:headers_complete, content_length - curr_bytes}}, :continue}
    end
  end

  @spec sanitize_line(String.t()) :: String.t()
  defp sanitize_line(line) do
    line
    |> String.replace("\r\n", "")
    |> String.trim()
  end

  @spec parse_method_target_protocol(String.t()) :: {String.t(), String.t(), String.t()}
  defp parse_method_target_protocol(line) do
    line
    |> String.split(" ")
    |> Enum.map(&sanitize_line/1)
    |> List.to_tuple()
  end

  @spec parse_header(String.t()) :: header()
  defp parse_header(line) do
    line
    |> String.split(":", parts: 2)
    |> Enum.map(&sanitize_line/1)
    |> List.to_tuple()
    |> maybe_further_parse()
  end

  @spec maybe_further_parse({String.t(), String.t()}) :: {String.t(), String.t() | [String.t()]}
  defp maybe_further_parse({"Accept-Encoding" = key, val}) do
    parsed_val =
      val
      |> String.split(",", trim: true)
      |> Enum.map(&String.trim/1)

    {key, parsed_val}
  end

  defp maybe_further_parse({"Content-Length" = key, val}) do
    parsed_val = String.to_integer(val)
    {key, parsed_val}
  end
  defp maybe_further_parse(t), do: t

  @spec get_bytes(state()) :: non_neg_integer() | nil
  defp get_bytes({:headers_complete, need_bytes}), do: need_bytes
  defp get_bytes(_), do: nil

  defp keep_alive?(%__MODULE__{headers: %{"Connection" => "close"}}), do: false
  defp keep_alive?(_req), do: true
end
