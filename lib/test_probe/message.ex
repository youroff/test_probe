defmodule TestProbe.Message do
  @moduledoc ~S"""
  The `%Message{}` struct is used to wrap incoming messages.
  Along with payload it stores type of the message and sender reference if applicable.

      %Message{
        type: :any | :call | :cast | :info,   # type of the message
        data: :any | payload,                 # message body
        from: :any | {pid, ref} | nil         # set in case of call
      }

  It is also used as a pattern when you need to match message.

      %Message{}                    # an absolute wildcard, matches any message
      %Message{type: :call}         # matches any 'call' message
      %Message{data: :hello}        # matches any message with payload == :hello
  """

  @type t :: %TestProbe.Message{type: atom, data: term, from: term}
  defstruct type: :any, data: :any, from: :any

  @doc """
  Matches two messages. You may use a wildcard `:any` to specify that any value
  under a particular key would be considered a match.

  ## Examples
  If you're expecting message by payload, but don't really care of where it came from:

      m = %Message{type: :call, data: "hey", from: {pid, ref}}
      match(m, %Message{data: "hey"}) == true
  """
  @spec match(t, t) :: boolean
  def match(m1, m2) do
    comp(m1.data, m2.data) && comp(m1.type, m2.type) && comp(m1.from, m2.from)
  end

  @spec comp(term, term) :: boolean
  defp comp(:any, _), do: true
  defp comp(_, :any), do: true
  defp comp(x, y), do: x == y
end
