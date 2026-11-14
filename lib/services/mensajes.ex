
defmodule Mensajes do

  @estados ["pendiente", "entregado"]

  # --------------------------------------------------
  # VALIDACIONES
  # --------------------------------------------------

  def texto_valido?(texto) do
    is_binary(texto) and String.trim(texto) != ""
  end

  def validar_estado(estado) do
    if estado in @estados do
      :ok
    else
      {:error, "El estado del mensaje no es valido."}
    end
  end

  def codigo_existe?(mensajes, codigo) do
    Enum.any?(mensajes, fn mensaje ->
      mensaje.codigo == codigo
    end)
  end

  # --------------------------------------------------
  # BUSCAR MENSAJE
  # --------------------------------------------------

  def buscar_mensaje(mensajes, codigo) do
    Enum.find(mensajes, fn mensaje ->
      mensaje.codigo == codigo
    end)
  end

  # --------------------------------------------------
  # REGISTRAR MENSAJE
  # --------------------------------------------------

  def registrar_mensaje(
        mensajes,
        codigo,
        remitente,
        destinatario,
        contenido
      ) do

    with true <- texto_valido?(codigo),
         true <- texto_valido?(remitente),
         true <- texto_valido?(destinatario),
         true <- texto_valido?(contenido),
         false <- codigo_existe?(mensajes, String.trim(codigo)) do

      nuevo_mensaje = %Mensaje{
        codigo: String.trim(codigo),
        fecha: DateTime.utc_now() |> DateTime.to_iso8601(),
        remitente: String.trim(remitente),
        destinatario: String.trim(destinatario),
        contenido: String.trim(contenido),
        estado: "pendiente"
      }

      guardar_cambios([nuevo_mensaje | mensajes])

    else
      true ->
        {:error, "El codigo del mensaje ya existe."}

      false ->
        {:error, "Todos los campos del mensaje son obligatorios."}

      _ ->
        {:error, "No se pudo registrar el mensaje."}
    end

  end

  # --------------------------------------------------
  # LISTAR MENSAJES
  # --------------------------------------------------

  def listar_mensajes(mensajes) do
    mensajes
  end

  # --------------------------------------------------
  # BUSCAR MENSAJES POR DESTINATARIO
  # --------------------------------------------------

  def buscar_por_destinatario(mensajes, destinatario) do

    Enum.filter(mensajes, fn mensaje ->
      mensaje.destinatario == destinatario
    end)

  end

  # --------------------------------------------------
  # BUSCAR MENSAJES POR REMITENTE
  # --------------------------------------------------

  def buscar_por_remitente(mensajes, remitente) do

    Enum.filter(mensajes, fn mensaje ->
      mensaje.remitente == remitente
    end)

  end

  # --------------------------------------------------
  # FILTRAR MENSAJES POR ESTADO
  # --------------------------------------------------

  def filtrar_por_estado(mensajes, estado) do

    case validar_estado(estado) do

      :ok ->
        Enum.filter(mensajes, fn mensaje ->
          mensaje.estado == estado
        end)

      {:error, razon} ->
        {:error, razon}

    end

  end

  # --------------------------------------------------
  # ACTUALIZAR ESTADO DEL MENSAJE
  # --------------------------------------------------

  def actualizar_estado(mensajes, codigo, nuevo_estado) do

    mensaje = buscar_mensaje(mensajes, codigo)

    cond do
      is_nil(mensaje) ->
        {:error, "El mensaje no existe."}

      true ->

        with :ok <- validar_estado(nuevo_estado),
             true <- mensaje.estado == "pendiente" and
                     nuevo_estado == "entregado" do

          mensaje_actualizado = %{
            mensaje |
            estado: nuevo_estado
          }

          nuevos_mensajes =
            Enum.map(mensajes, fn actual ->
              if actual.codigo == codigo do
                mensaje_actualizado
              else
                actual
              end
            end)

          guardar_cambios(nuevos_mensajes)

        else
          false ->
            {:error, "El mensaje ya fue entregado o la transicion no es valida."}

          {:error, razon} ->
            {:error, razon}
        end

    end

  end

  # --------------------------------------------------
  # PERSISTENCIA
  # --------------------------------------------------

  defp guardar_cambios(mensajes) do

    case PersistenciaMensajes.guardar(mensajes) do

      {:ok, _mensaje} ->
        {:ok, mensajes}

      {:error, razon} ->
        {:error, razon}

    end

  end

end
