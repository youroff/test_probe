defmodule TestProbe do
  import MonEx.{Option, Result}
  alias TestProbe.Message

  def start(opts \\ []) do
    GenServer.start(TestProbe.Server, [], opts)
  end

  def stop(probe) do
    Agent.stop(probe)
  end

  def receive(probe, message, timeout \\ 1000) do
    GenServer.call(probe, {:probe_receive, message, timeout}, 2 * timeout)
  end

  def all_received(probe) do
    GenServer.call(probe, :probe_dump)
  end

  def last_received(probe) do
    all_received(probe) |> List.first |> to_option
  end

  def times_received(probe, message) do
    all_received(probe)
    |> Enum.reduce(0, fn msg, count ->
      if Message.match(message, msg), do: count + 1, else: count
    end)
  end
  #
  # def last_received?(probe, data, opts \\ []) do
  #   last_received(probe)
  #   |> MonEx.map(& message_match(&1, data, opts))
  #   |> get_or_else(false)
  # end
  #
  # def received?(probe, data, opts \\ []) do
  #   times_received(probe, data, opts) > 0
  # end

  def reply(probe, msg, reply) do
    GenServer.call(probe, {:probe_reply, msg, reply})
  end

  def run(probe, fun) do
    GenServer.call(probe, {:probe_run, fun})
  end

  def cast(probe, pid, message) do
    run probe, fn ->
      GenServer.cast(pid, message)
    end
  end

  def call(probe, pid, message) do
    run probe, fn ->
      GenServer.call(pid, message)
    end
  end

  def send(probe, pid, message) do
    run probe, fn ->
      send pid, message
    end
  end
end
