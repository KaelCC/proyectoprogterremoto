defmodule Necesidad do
  defstruct [
    :id,
    :tipo,
    :descripcion,
    :cantidad,
    :zona,
    :prioridad,
    :responsable,
    estado: "pendiente",
    recursos_asignados: []
  ]
end
