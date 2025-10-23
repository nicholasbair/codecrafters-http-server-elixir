defmodule Server do
  use Application

  alias Server.{
    Connection,
    Request,
    Router
  }

  def start(_type, _args) do
    Supervisor.start_link([{Task, fn -> Server.listen() end}], strategy: :one_for_one)
  end

  def listen() do
    # You can use print statements as follows for debugging, they'll be visible when running tests.
    IO.puts("Logs from your program will appear here!")

    # Since the tester restarts your program quite often, setting SO_REUSEADDR
    # ensures that we don't run into 'Address already in use' errors
    {:ok, listen_socket} = :gen_tcp.listen(4221, [:binary, packet: :line, active: false, reuseaddr: true])
    loop_acceptor(listen_socket)
  end

  defp loop_acceptor(socket) do
    {:ok, client} = :gen_tcp.accept(socket)

    client
    |> Connection.new()
    |> serve()
    |> Request.parse_request()
    |> Router.route()

    :gen_tcp.close(client)

    loop_acceptor(socket)
  end

  defp serve(%Connection{client: socket, raw_request: lines} = conn) do
    new_line = read_line(socket)
    conn = %{conn | raw_request: [new_line | lines]}

    case new_line do
      "\r\n" -> conn
      _ -> serve(conn)
    end
  end

  # Note: passing length=0 (2nd arg) to recv means all available bytes are returned
  defp read_line(socket) do
    {:ok, data} = :gen_tcp.recv(socket, 0)
    data
  end
end

defmodule CLI do
  def main(_args) do
    # Start the Server application
    {:ok, _pid} = Application.ensure_all_started(:codecrafters_http_server)

    # Run forever
    Process.sleep(:infinity)
  end
end
