defmodule Albergue do

  defstruct [
    :codigo,
    :nombre,
    :zona,
    :capacidad_maxima,
    personas: [],
    recursos_asignados: []
  ]

end
