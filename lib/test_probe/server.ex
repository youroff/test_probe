defmodule TestProbe.Server do
  use GenServer
  import MonEx.{Option, Result}
  alias TestProbe.Message

  def init(_) do
    ok(%{messages: [], expectations: []})
  end

  def handle_call(:probe_dump, _, state) do
    {:reply, state.messages, state}
  end

  def handle_call({:probe_reply, %Message{type: :call} = msg, reply}, _, state) do
    res = if Enum.member? state.messages, msg do
      GenServer.reply(msg.from, reply)
      ok("Reply sent to #{inspect(msg.from)}")
    else
      error("Cannot reply to message never received")
    end
    {:reply, res, state}
  end

  def handle_call({:probe_reply, _, _}, _, state) do
    {:reply, error("Can only reply to call message"), state}
  end

  def handle_call({:probe_run, fun}, _, state) do
    {:reply, fun.(), state}
  end

  def handle_call({:probe_receive, message, timeout}, asker, state) do
    if match = Enum.find(state.messages, &Message.match(&1, message)) do
      {:reply, some(match), state}
    else
      Process.send_after(self(), {:clear_expectation, {message, asker}}, timeout)
      {:noreply, %{state | expectations: [{message, asker} | state.expectations]}}
    end
  end

  def handle_call(data, from, state) do
    struct(Message, type: :call, data: data, from: from) |> wrap_up(state)
  end

  def handle_cast(data, state) do
    struct(Message, type: :cast, data: data, from: nil) |> wrap_up(state)
  end

  def handle_info({:clear_expectation, {_, asker} = exp}, state) do
    if Enum.member?(state.expectations, exp) do
      GenServer.reply(asker, none())
      exps = Enum.reject(state.expectations, & &1 == exp)
      {:noreply, %{state | expectations: exps}}
    else
      {:noreply, state}
    end
  end

  def handle_info(data, state) do
    struct(Message, type: :info, data: data, from: nil) |> wrap_up(state)
  end

  defp wrap_up(message, state) do
    messages = [message | state.messages]
    expectations = reply_if_expected(message, state.expectations)
    {:noreply, %{state | messages: messages, expectations: expectations}}
  end

  defp reply_if_expected(message, expectations) do
    case Enum.find(expectations, fn {m, _} -> Message.match(m, message) end) do
      {_, asker} = exp ->
        GenServer.reply(asker, some(message))
        List.delete(expectations, exp)
      _ ->
        expectations
    end
  end
end
