defmodule MeansToAnEnd.Server do
  require Logger

  def listen(port) when is_integer(port) do
    {:ok, socket} =
      :gen_tcp.listen(port, [:binary, :inet, port: port, active: false, reuseaddr: true])

    Logger.info("Listening for connections on port #{port}")

    accept(socket)
  end

  defp accept(socket) do
    {:ok, client} = :gen_tcp.accept(socket)

    {:ok, pid} =
      Task.Supervisor.start_child(MeansToAnEnd.ClientSupervisor, fn ->
        Logger.info("*** #{inspect self()} Starting to serve client")
        serve(client, %{})
      end)

    :gen_tcp.controlling_process(client, pid)

    accept(socket)
  end

  defp serve(socket, state) do
    case :gen_tcp.recv(socket, 9) do
      {:ok, <<?I, timestamp::signed-size(32), price::signed-size(32)>>} ->
        Logger.info("<== #{inspect self()} I #{timestamp} #{price}")

        state = Map.put(state, timestamp, price)
        serve(socket, state)

      {:ok, <<?Q, mintime::signed-size(32), maxtime::signed-size(32)>>} when mintime > maxtime ->
        Logger.info("<== #{inspect self()} Q #{mintime} #{maxtime}")

        respond(socket, 0)
        serve(socket, state)

      {:ok, <<?Q, mintime::signed-size(32), maxtime::signed-size(32)>>} ->
        Logger.info("<== #{inspect self()} Q #{mintime} #{maxtime}")

        prices = for {time, price} <- state, time in mintime..maxtime, do: price

        response =
          case prices do
            [] -> 0
            _ -> div(Enum.sum(prices), Enum.count(prices))
          end

        respond(socket, response)
        serve(socket, state)
    end
  end

  defp respond(socket, number) do
    Logger.info("==> #{number}")
    :gen_tcp.send(socket, <<number::signed-size(32)>>)
  end
end
