defmodule Server.Connection do

  alias Server.Request

  @type t :: %__MODULE__{
    client: port(),
    raw_request: String.t(),
    request: Request.t()
  }

  defstruct [
    :client,
    raw_request: "",
    request: %Request{}
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
