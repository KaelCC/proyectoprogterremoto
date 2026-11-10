defmodule Proyectoprog.MixProject do
  use Mix.Project

  def project do
    [
      app: :proyectoprog,
      version: "0.1.0",
      elixir: "~> 1.20",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      # Aquí agregaremos dependencias si las necesitamos.
    ]
  end
end
