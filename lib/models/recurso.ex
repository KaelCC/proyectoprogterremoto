defmodule Recurso do
  defstruct [
    :codigo,
    :nombre,
    :categoria,
    :cantidad,
    :unidad,
    :ubicacion,
    historial: []
  ]
end
