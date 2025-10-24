defmodule Server.Connection do

  alias Server.Request

  @type t :: %__MODULE__{
    client: port(),
    request: Request.t(),
    raw_request: [String.t()]
  }

  defstruct [
    :client,
    :request,
    raw_request: []
  ]

  @spec new(port()) :: t()
  def new(client) do
    %__MODULE__{
      client: client
    }
  end

  @spec close(t()) :: :ok
  def close(conn), do: :gen_tcp.close(conn.client)
end
