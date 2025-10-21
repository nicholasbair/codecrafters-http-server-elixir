defmodule Server.Connection do

  defstruct [
    :client,
    :request,
    raw_request: []
  ]

  def new(client) do
    %__MODULE__{
      client: client
    }
  end
end
