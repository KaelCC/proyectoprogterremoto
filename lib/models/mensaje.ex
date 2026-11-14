
defmodule Mensaje do

  defstruct [
    :codigo,
    :fecha,
    :remitente,
    :destinatario,
    :contenido,
    estado: "pendiente"
  ]

end
