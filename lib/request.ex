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

  @type action :: :continue | :continue_body | :complete
  @type state :: :request_line_complete | :headers_complete

  defstruct [
    :method,
    :request_target,
    :protocol,
    :state,
    body: "",
    headers: %{}
  ]

  @spec handle_request(Conn.t(), String.t()) :: {Conn.t(), action()}
  def handle_request(%Conn{request: req} = conn, new_line) do
    {updated_req, action} = parse_line(req, new_line)
    {%{conn | request: updated_req}, action}
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
      _ -> {%{req | state: :headers_complete}, :continue_body}
    end
  end

  def parse_line(%__MODULE__{state: :request_line_complete} = req, new_line) do
    {k, v} = parse_header(new_line)
    {%{req | headers: Map.put(req.headers, k, v)}, :continue}
  end

  def parse_line(%__MODULE__{method: method, state: :headers_complete} = req, new_line) when method in ["POST", "PUT", "PATCH"] do
    content_length = Map.get(req.headers, "Content-Length")
    updated_body = req.body <> new_line

    case String.length(updated_body) >= content_length do
      true ->
        {%{req | body: updated_body}, :complete}
      false ->
        {%{req | body: updated_body, state: :headers_complete}, :continue_body}
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
end
