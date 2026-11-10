defmodule Mensaje do
  defstruct [
    :id,
    :fecha,
    :remitente,
    :destinatario,
    :contenido,
    estado: :pendiente
  ]
end
