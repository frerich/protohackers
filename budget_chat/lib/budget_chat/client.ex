defmodule BudgetChat.Client do
  use GenServer

  require Logger

  @room_name "room"

  def start(socket) do
    Logger.info("Client connected.")
    GenServer.start(__MODULE__, socket)
  end

  def init(socket) do
    :gen_tcp.send(socket, "Welcome to budgetchat! What shall I call you?\n")
    {:ok, {socket, nil}}
  end

  def handle_info({:tcp, _port, line}, {socket, nil}) do
    user_name = String.trim(line)

    if valid_name?(user_name) do
      {:ok, _} = Registry.register(BudgetChat.ClientRegistry, @room_name, user_name)
      Logger.info("#{user_name} joined")
      broadcast({:user_joined, user_name})

      Registry.dispatch(BudgetChat.ClientRegistry, @room_name, fn users ->
        users = for {pid, user} <- users, pid != self(), do: user
        banner = "* The room contains: #{Enum.join(users, ", ")}"
        :gen_tcp.send(socket, banner <> "\n")
      end)

      {:noreply, {socket, user_name}}
    else
      :gen_tcp.send(socket, "Sorry, this user name is not valid. Goodbye!\n")
      {:stop, :normal, {socket, nil}}
    end
  end

  def handle_info({:tcp, _port, line}, {socket, user_name}) do
    broadcast({:broadcast, user_name, String.trim(line)})
    {:noreply, {socket, user_name}}
  end

  def handle_info({:tcp_closed, _port}, {socket, nil}) do
    {:stop, :normal, {socket, nil}}
  end

  def handle_info({:tcp_closed, _port}, {socket, user_name}) do
    Logger.info("#{user_name} disconnected")
    broadcast({:user_left, user_name})
    {:stop, :normal, {socket, user_name}}
  end

  def handle_info({:broadcast, sender, message}, {socket, user_name}) do
    :gen_tcp.send(socket, "[#{sender}] #{message}\n")
    {:noreply, {socket, user_name}}
  end

  def handle_info({:user_joined, who}, {socket, user_name}) do
    :gen_tcp.send(socket, "* #{who} has entered the room\n")
    {:noreply, {socket, user_name}}
  end

  def handle_info({:user_left, who}, {socket, user_name}) do
    :gen_tcp.send(socket, "* #{who} has left the room\n")
    {:noreply, {socket, user_name}}
  end

  defp broadcast(message) do
    Registry.dispatch(BudgetChat.ClientRegistry, @room_name, fn users ->
      for {pid, _} <- users, pid != self(), do: send(pid, message)
    end)
  end

  defp valid_name?(name) do
    String.match?(name, ~r/^[a-zA-Z0-9]+$/)
  end
end
