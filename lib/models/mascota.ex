defmodule Mascota do
  defstruct [
    :codigo,
    :tipo_reporte,
    :especie,
    :nombre,
    :caracteristicas,
    :color,
    :tamano,
    :zona,
    :contacto,
    estado: "activa",
    coincidencia: nil
  ]
end
