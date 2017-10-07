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
    {:monex, "~> 0.1.10"},
    {:ex_doc, ">= 0.0.0", only: :dev, runtime: false},
    {:dialyxir, "~> 0.5.1", only: :dev, runtime: false}
  ]

  defp description do
    """
    TestProbe is a tiny wrapper around GenServer, that puts testing of actor
    interactions under control.
    """
  end

  defp package, do: [
    files: ["lib", "mix.exs", "README*", "LICENSE*"],
    maintainers: ["Ivan Yurov"],
    licenses: ["MIT"],
    links: %{"GitHub" => "https://github.com/youroff/test_probe"}
  ]
end
