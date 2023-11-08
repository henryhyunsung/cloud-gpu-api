defmodule Fluidstack.MixProject do
  use Mix.Project

  def project do
    [
      app: :fluidstack,
      version: "0.1.0",
      elixir: "~> 1.15",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [      
      {:tesla, "~> 1.7"},
      {:jason, "~> 1.4.1"},
      {:mimic, "~> 1.7", only: :test},
      {:doctor, "~> 0.21.0", only: :dev},
      {:credo, "~> 1.6", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.27", only: :dev, runtime: false},
      {:earmark_parser, "~> 1.4.37"}
    ]
  end
end
