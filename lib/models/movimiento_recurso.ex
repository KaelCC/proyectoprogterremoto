defmodule MovimientoRecurso do
  defstruct [
    :id,
    :codigo_recurso,
    :tipo,
    :cantidad,
    :origen,
    :destino,
    :fecha,
    :responsable
  ]
end
