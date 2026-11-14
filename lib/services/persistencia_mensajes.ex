
defmodule PersistenciaMensajes do

  # Ruta del archivo de mensajes.
  @ruta Path.expand("../../priv/data/mensajes.txt", __DIR__)

  @estados ["pendiente", "entregado"]

  # --------------------------------------------------
  # GUARDAR MENSAJES
  # --------------------------------------------------

  def guardar(mensajes) do

    with :ok <- File.mkdir_p(Path.dirname(@ruta)),
         contenido <- serializar(mensajes),
         :ok <- File.write(@ruta, contenido) do

      {:ok, "Mensajes guardados correctamente."}

    else
      {:error, razon} ->
        {:error, "No se pudieron guardar los mensajes: #{inspect(razon)}"}
    end

  end

  # --------------------------------------------------
  # CARGAR MENSAJES
  # --------------------------------------------------

  def cargar do

    with :ok <- File.mkdir_p(Path.dirname(@ruta)),
         :ok <- crear_archivo(),
         {:ok, contenido} <- File.read(@ruta) do

      lineas =
        contenido
        |> String.split(~r/\r\n|\n|\r/, trim: true)

      resultado =
        Enum.reduce_while(lineas, {:ok, []}, fn linea, {:ok, mensajes} ->

          case procesar_linea(linea, mensajes) do

            {:ok, mensaje} ->
              {:cont, {:ok, [mensaje | mensajes]}}

            {:error, razon} ->
              {:halt, {:error, razon}}

          end

        end)

      case resultado do
        {:ok, mensajes} ->
          {:ok, Enum.reverse(mensajes)}

        {:error, razon} ->
          {:error, razon}
      end

    else
      {:error, razon} ->
        {:error, "No se pudieron cargar los mensajes: #{inspect(razon)}"}
    end

  end

  # --------------------------------------------------
  # CREAR ARCHIVO SI NO EXISTE
  # --------------------------------------------------

  defp crear_archivo do

    unless File.exists?(@ruta) do
      File.write(@ruta, "")
    else
      :ok
    end

  end

  # --------------------------------------------------
  # SERIALIZAR MENSAJES
  # --------------------------------------------------

  defp serializar(mensajes) do

    mensajes
    |> Enum.map(fn mensaje ->

      campos = [
        mensaje.codigo,
        mensaje.fecha,
        mensaje.remitente,
        mensaje.destinatario,
        mensaje.contenido,
        mensaje.estado
      ]

      campos_codificados =
        Enum.map(campos, fn campo ->
          Base.encode64(campo)
        end)

      "M|" <> Enum.join(campos_codificados, "|")

    end)
    |> Enum.join("\n")
    |> agregar_salto_final()

  end

  defp agregar_salto_final(""), do: ""
  defp agregar_salto_final(contenido), do: contenido <> "\n"

  # --------------------------------------------------
  # PROCESAR LINEA
  # --------------------------------------------------

  defp procesar_linea(linea, mensajes) do

    with ["M", codigo, fecha, remitente, destinatario, contenido, estado] <-
           String.split(linea, "|", trim: false),

         {:ok, codigo} <- Base.decode64(codigo),
         {:ok, fecha} <- Base.decode64(fecha),
         {:ok, remitente} <- Base.decode64(remitente),
         {:ok, destinatario} <- Base.decode64(destinatario),
         {:ok, contenido} <- Base.decode64(contenido),
         {:ok, estado} <- Base.decode64(estado),

         true <- Enum.all?(
           [codigo, fecha, remitente, destinatario, contenido],
           &(String.trim(&1) != "")
         ),

         true <- estado in @estados,

         false <- Enum.any?(mensajes, fn mensaje ->
           mensaje.codigo == codigo
         end) do

      mensaje = %Mensaje{
        codigo: codigo,
        fecha: fecha,
        remitente: remitente,
        destinatario: destinatario,
        contenido: contenido,
        estado: estado
      }

      {:ok, mensaje}

    else
      true ->
        {:error, "El mensaje tiene campos vacios, un estado invalido o un codigo duplicado."}

      false ->
        {:error, "El mensaje contiene un codigo duplicado."}

      {:error, razon} ->
        {:error, "No se pudo decodificar un mensaje: #{inspect(razon)}"}

      _ ->
        {:error, "El formato de una linea de mensajes es incorrecto."}
    end

  end

end
