defmodule Zona do
  defstruct [
    :codigo,
    :nombre,
    :nivel_afectacion,
    :personas_afectadas,
    sectores: []
  ]
end
