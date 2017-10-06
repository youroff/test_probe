defmodule TestProbe.Message do

  defstruct type: :any, data: :any, from: :any

  def match(m1, m2) do
    comp(m1.data, m2.data) && comp(m1.type, m2.type) && comp(m1.from, m2.from)
  end

  defp comp(:any, _), do: true
  defp comp(_, :any), do: true
  defp comp(x, y), do: x == y
end
