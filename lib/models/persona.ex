defmodule Persona do
  defstruct [
    :id,
    :nombre,
    :documento,
    :edad,
    :zona,
    :estado,
    :albergue,
    historial_estados: []
  ]
end
