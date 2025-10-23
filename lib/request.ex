defmodule Server.Request do

  alias Server.Connection

  @type t :: %__MODULE__{
    method: String.t(),
    request_target: String.t(),
    protocol: String.t(),
    headers: headers()
  }

  @type header :: String.t()
  @type headers :: [header()]

  defstruct [
    :method,
    :request_target,
    :protocol,
    headers: []
  ]

  @spec parse_request(Connection.t()) :: Connection.t()
  def parse_request(%Connection{raw_request: lines} = conn) do
    [method, target, _] =
      lines
      |> Enum.reverse()
      |> List.first()
      |> String.split(" ")

    req =
      %__MODULE__{
        method: method,
        request_target: target
      }

    %{conn | request: req}
  end
end
