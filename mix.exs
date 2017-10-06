defmodule TestProbe.Mixfile do
  use Mix.Project

  def project, do: [
    app: :test_probe,
    version: "0.0.1",
    elixir: "~> 1.5",
    deps: deps(),
    description: description(),
    package: package()
  ]

  def application, do: []

  defp deps, do: [
    {:monex, "~> 0.1.10"}
  ]

  defp description do
    """
    TestProbe for mocking Elixir processes
    """
  end

  defp package, do: [
    files: ["lib", "mix.exs", "README*", "LICENSE*"],
    maintainers: ["Ivan Yurov"],
    licenses: ["MIT"],
    links: %{"GitHub" => "https://github.com/youroff/test_probe"}
  ]
end
