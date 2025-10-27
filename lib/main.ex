defmodule Server do
  use Application

  alias Server.{
    Connection,
    Request,
    Router
  }

  def start(_type, _args) do
    temp_dir = System.argv() |> maybe_get_temp_dir()
    Supervisor.start_link([{Task, fn -> Server.listen(temp_dir) end}], strategy: :one_for_one)
  end

  def listen(temp_dir) do
    # You can use print statements as follows for debugging, they'll be visible when running tests.
    IO.puts("Logs from your program will appear here!")

    # Since the tester restarts your program quite often, setting SO_REUSEADDR
    # ensures that we don't run into 'Address already in use' errors
    # {:ok, listen_socket} = :gen_tcp.listen(4221, [:binary, packet: :line, active: false, reuseaddr: true])
    {:ok, listen_socket} = :gen_tcp.listen(4221, [:binary, active: false, reuseaddr: true])
    loop_acceptor(listen_socket, temp_dir)
  end

  defp loop_acceptor(socket, temp_dir) do
    {:ok, client} = :gen_tcp.accept(socket)

    Task.start(fn ->
      client
      |> Connection.new(temp_dir)
      |> serve()
      |> Request.parse_request()
      |> Router.route()
      |> Connection.close()
    end)

    loop_acceptor(socket, temp_dir)
  end

  @spec serve(Connection.t()) :: Connection.t()
  defp serve(%Connection{client: socket} = conn) do
    # new_line = read_line(socket)
    # conn =
    {:ok, data} = :gen_tcp.recv(socket, 0)
    %{conn | raw_request: data}

    # case new_line do
    #   "\r\n" -> conn
    #   _ -> serve(conn)
    # end
  end

  # @spec read_line(port()) :: String.t()
  # defp read_line(socket) do
  #   {:ok, data} = :gen_tcp.recv(socket, 0)
  #   data
  # end

  defp maybe_get_temp_dir(["--directory", dir]), do: dir
  defp maybe_get_temp_dir(_), do: ""
end

defmodule CLI do
  def main(_args) do
    # Start the Server application
    {:ok, _pid} = Application.ensure_all_started(:codecrafters_http_server)

    # Run forever
    Process.sleep(:infinity)
  end
end
