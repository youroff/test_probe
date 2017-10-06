defmodule TestProbeTest do
  use ExUnit.Case
  import MonEx.{Option, Result}
  alias TestProbe, as: Probe
  alias TestProbe.Message

  test "wait for receive call and reply" do
    ok(probe) = Probe.start()
    task = Task.async(fn -> GenServer.call(probe, :wtf) end)
    parent = task.pid

    assert some(msg) = Probe.receive(probe, %Message{data: :wtf})
    assert {^parent, _} = msg.from
    assert msg.type == :call
    assert msg.data == :wtf

    assert ok(success) = Probe.reply(probe, msg, :yay)
    assert success =~ "Reply sent to"
    assert Task.await(task) == :yay
    Probe.stop(probe)
  end

  test "receive cast" do
    ok(probe) = Probe.start()
    GenServer.cast(probe, :wtf)

    assert some(msg) = Probe.receive(probe, %Message{data: :wtf})
    assert msg.type == :cast
    Probe.stop(probe)
  end

  test "sending on behalf of probe" do
    ok(probe) = Probe.start()
    Probe.send(probe, self(), :lol)
    assert_receive :lol
    Probe.stop(probe)
  end

  test "times received" do
    ok(probe) = Probe.start()
    GenServer.cast(probe, :sup?)
    GenServer.cast(probe, :lol!)
    GenServer.cast(probe, :lol!)

    assert Probe.times_received(probe, %Message{data: :sup?}) == 1
    assert Probe.times_received(probe, %Message{data: :lol!}) == 2
    Probe.stop(probe)
  end

  test "casting on behalf of probe" do
    ok(sender) = Probe.start()
    ok(receiver) = Probe.start()

    Probe.cast(sender, receiver, :yay)

    assert some(_) = Probe.receive(receiver, %Message{data: :yay, type: :cast})
    Probe.stop(sender)
    Probe.stop(receiver)
  end

  test "calling on behalf of probe" do
    ok(sender) = Probe.start()
    ok(receiver) = Probe.start()
    task = Task.async(fn -> Probe.call(sender, receiver, :yay) end)

    assert some(message) = Probe.receive(receiver, %Message{})

    Probe.reply(receiver, message, :nay)
    assert Task.await(task) == :nay
  end

  test "probe run" do
    ok(probe) = Probe.start()
    result = Probe.run(probe, fn -> {:ran_on, self()} end)
    assert {:ran_on, ^probe} = result
  end

  test "named probe" do
    ok(probe) = Probe.start(name: :some)
    GenServer.cast(:some, :yay)
    assert some(_) = Probe.receive(probe, %Message{data: :yay})
  end
end
