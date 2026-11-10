defmodule Usuario do
  defstruct [
    :nombreUsuario,
    :contraseña,
    :nombre,
    :categoria,
    :ubicacion,
    estado: :desconectado
  ]
end
