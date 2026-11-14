defmodule Persona do
  defstruct [
    :codigo,
    :nombre,
    :edad,
    :zona,
    estado: "afectada",
    albergue: nil,
    historial: []
  ]
end
