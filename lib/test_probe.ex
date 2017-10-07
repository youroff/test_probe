defmodule TestProbe do
  @moduledoc ~S"""
  `TestProbe` is a tiny wrapper around `GenServer`, that puts testing of actor
  interactions under control.

  The probe, once started, will accept any message (`call`, `cast`, `info`) and
  put it into the queue, where it can be accessed using Probe API.
  After retrieving a message you can tell the probe to respond (in case of call).
  You can also send messages or execute arbitrary code on behalf of the probe.

  In the docs and examples we'll use MonEx macros, you can easily choose not to use
  it. `ok(x)` and `error(e)` stand for `{:ok, x}` and `{:error, e}` respectively.
  Optional `some(x)` and `none()` would be `{:some, x}` and `{:none}`. Check
  [monex docs](https://hexdocs.pm/monex/api-reference.html) for details.

  ## Examples

      import MonEx.{Result, Option} # to support ok() some() etc...
      ok(probe) = Probe.start()
      task = Task.async(fn -> GenServer.call(probe, :hey) end)

      # Here we wait for the message matching the pattern:
      assert some(msg) = Probe.receive(probe, %Message{data: :hey})

      IO.inspect(msg)
      # %TestProbe.Message{
      #   data: :hey,
      #   from: {#PID<0.193.0>, #Reference<0.2208989138.2906914819.164457>},
      #   type: :call
      # }

      # Now you can use msg to respond:
      Probe.reply(msg, :sup)
      response = Task.await(task)

      assert response == :sup
  """

  import MonEx.Option
  alias TestProbe.Message

  @doc """
  Starts the probe with optionals parameters.

  Parameters passed directly to GenServer.
  `name` can be useful, if you're testing some code accessing another process by
  name.

  Returns: `ok(pid)`
  """
  @spec start(Keyword.t) :: MonEx.Result.t
  def start(opts \\ []) do
    GenServer.start(TestProbe.Server, [], opts)
  end

  @doc """
  Stops the probe.
  """
  @spec stop(pid) :: atom
  def stop(probe) do
    Agent.stop(probe)
  end

  @doc """
  Polls the probe to check if there is a message matching pattern provided.

  If message is not in a queue yet, will wait for a `timeout` time. When timeout has
  passed, a `none()` will be returned.

  Returns: `some(message)` or `none()`
  """
  @spec receive(pid, TestProbe.Message.t, integer) :: MonEx.Option.t
  def receive(probe, message, timeout \\ 1000) do
    GenServer.call(probe, {:probe_receive, message, timeout}, 2 * timeout)
  end

  @doc """
  Pulls all messages from the probe.

  Be careful, if you call this right after sending a message from some other
  process, there's no guarantee that this message will be there. To provide
  that guarantee, confirm reception with `receive` first.

  Returns: `[message, ...]`
  """
  @spec all_received(pid) :: list(TestProbe.Message.t)
  def all_received(probe) do
    GenServer.call(probe, :probe_dump)
  end

  @doc """
  Returns last message received by the probe.

  Just like with `all_received`, the very last message can not be there yet at
  the time of calling. Consider using `receive`.

  Returns: `some(message)` or `none()`
  """
  @spec last_received(pid) :: MonEx.Option.t
  def last_received(probe) do
    all_received(probe) |> List.first |> to_option
  end

  @doc """
  Returns how many times the message matching the pattern was received.

  Returns: `amount`
  """
  @spec times_received(pid, TestProbe.Message.t) :: integer
  def times_received(probe, message) do
    all_received(probe)
    |> Enum.reduce(0, fn msg, count ->
      if Message.match(message, msg), do: count + 1, else: count
    end)
  end

  @doc """
  Sends a response to provided message.

  Returns: `ok(message)` or `error(message)` if operation failed
  """
  @spec reply(pid, TestProbe.Message.t, term) :: term
  def reply(probe, message, response) do
    GenServer.call(probe, {:probe_reply, message, response})
  end

  @doc """
  Runs arbitrary lambda in the context of probe.

  This in particular is used to implement sending messages on behalf of the probe.

      run probe, fn ->
        GenServer.cast(pid, message)
      end

  Returns: `ok(message)` or `error(message)` if operation failed
  """
  @spec run(pid, (() -> term)) :: term
  def run(probe, fun) do
    GenServer.call(probe, {:probe_run, fun})
  end

  @doc """
  Sends `cast` on behalf of the probe.
  """
  @spec cast(pid, pid, term) :: term
  def cast(probe, pid, message) do
    run probe, fn ->
      GenServer.cast(pid, message)
    end
  end

  @doc """
  Sends `call` on behalf of the probe and returns the result.
  """
  @spec call(pid, pid, term) :: term
  def call(probe, pid, message) do
    run probe, fn ->
      GenServer.call(pid, message)
    end
  end

  @doc """
  Sends `info` on behalf of the probe.
  """
  @spec send(pid, pid, term) :: term
  def send(probe, pid, message) do
    run probe, fn ->
      send pid, message
    end
  end
end
