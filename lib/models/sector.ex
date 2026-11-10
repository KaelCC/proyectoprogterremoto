defmodule Sector do
  defstruct [
    :codigo,
    :nombre,
    :nivel_afectacion,
    :personas_afectadas,
    puntos_atencion: []
  ]
end
