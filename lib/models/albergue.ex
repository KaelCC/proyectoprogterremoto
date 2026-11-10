defmodule Albergue do
  defstruct [
    :codigo,
    :nombre,
    :zona,
    :capacidad_maxima,
    ocupacion_actual: 0,
    personas: [],
    recursos: [],
    necesidades: []
  ]
end
