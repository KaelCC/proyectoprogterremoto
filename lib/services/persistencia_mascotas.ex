defmodule PersistenciaMascotas do
  @ruta Path.expand("../../priv/data/mascotas.txt", __DIR__)

  @estados ["activa", "posible coincidencia", "resuelta"]
  @tipos ["perdida", "encontrada"]

  # --------------------------------------------------
  # GUARDAR MASCOTAS
  # --------------------------------------------------

  def guardar(mascotas) do
    with :ok <- File.mkdir_p(Path.dirname(@ruta)),
         contenido <- serializar(mascotas),
         :ok <- File.write(@ruta, contenido) do
      {:ok, "Reportes de mascotas guardados correctamente."}
    else
      {:error, razon} ->
        {:error, "No se pudieron guardar los reportes: #{inspect(razon)}"}
    end
  end

  # --------------------------------------------------
  # CARGAR MASCOTAS
  # --------------------------------------------------

  def cargar do
    with :ok <- File.mkdir_p(Path.dirname(@ruta)),
         :ok <- crear_archivo(),
         {:ok, contenido} <- File.read(@ruta) do
      contenido
      |> String.split(~r/\r\n|\n|\r/, trim: true)
      |> Enum.reduce_while({:ok, []}, fn linea, {:ok, mascotas} ->
        case procesar_linea(linea, mascotas) do
          {:ok, mascota} ->
            {:cont, {:ok, [mascota | mascotas]}}

          {:error, razon} ->
            {:halt, {:error, razon}}
        end
      end)
      |> case do
        {:ok, mascotas} -> {:ok, Enum.reverse(mascotas)}
        {:error, razon} -> {:error, razon}
      end
    else
      {:error, razon} ->
        {:error, "No se pudieron cargar los reportes: #{inspect(razon)}"}
    end
  end

  # --------------------------------------------------
  # CREAR ARCHIVO SI NO EXISTE
  # --------------------------------------------------

  defp crear_archivo do
    if File.exists?(@ruta) do
      :ok
    else
      File.write(@ruta, "")
    end
  end

  # --------------------------------------------------
  # SERIALIZAR
  # --------------------------------------------------

  defp serializar(mascotas) do
    mascotas
    |> Enum.map(fn mascota ->
      campos = [
        mascota.codigo,
        mascota.tipo_reporte,
        mascota.especie,
        mascota.nombre,
        mascota.caracteristicas,
        mascota.color,
        mascota.tamano,
        mascota.zona,
        mascota.contacto,
        mascota.estado,
        mascota.coincidencia || ""
      ]

      campos_codificados =
        Enum.map(campos, &Base.encode64/1)

      "M|" <> Enum.join(campos_codificados, "|")
    end)
    |> Enum.join("\n")
    |> agregar_salto_final(mascotas)
  end

  defp agregar_salto_final(contenido, []), do: contenido
  defp agregar_salto_final(contenido, _mascotas), do: contenido <> "\n"

  # --------------------------------------------------
  # PROCESAR LINEA
  # --------------------------------------------------

  defp procesar_linea(linea, mascotas) do
    with [
           "M",
           codigo,
           tipo,
           especie,
           nombre,
           caracteristicas,
           color,
           tamano,
           zona,
           contacto,
           estado,
           coincidencia
         ] <- String.split(linea, "|", trim: false),
         {:ok, codigo} <- Base.decode64(codigo),
         {:ok, tipo} <- Base.decode64(tipo),
         {:ok, especie} <- Base.decode64(especie),
         {:ok, nombre} <- Base.decode64(nombre),
         {:ok, caracteristicas} <- Base.decode64(caracteristicas),
         {:ok, color} <- Base.decode64(color),
         {:ok, tamano} <- Base.decode64(tamano),
         {:ok, zona} <- Base.decode64(zona),
         {:ok, contacto} <- Base.decode64(contacto),
         {:ok, estado} <- Base.decode64(estado),
         {:ok, coincidencia} <- Base.decode64(coincidencia),
         true <- Enum.all?(
           [codigo, tipo, especie, caracteristicas, color, tamano, zona, contacto],
           &(String.trim(&1) != "")
         ),
         true <- tipo in @tipos,
         true <- estado in @estados,
         false <- Enum.any?(mascotas, fn mascota -> mascota.codigo == codigo end) do
      mascota = %Mascota{
        codigo: codigo,
        tipo_reporte: tipo,
        especie: especie,
        nombre: nombre,
        caracteristicas: caracteristicas,
        color: color,
        tamano: tamano,
        zona: zona,
        contacto: contacto,
        estado: estado,
        coincidencia: if(coincidencia == "", do: nil, else: coincidencia)
      }

      {:ok, mascota}
    else
      true ->
        {:error, "El archivo contiene un código de mascota duplicado."}

      false ->
        {:error, "El reporte contiene campos vacíos o valores inválidos."}

      {:error, razon} ->
        {:error, "No se pudo decodificar un reporte: #{inspect(razon)}"}

      _ ->
        {:error, "El formato de una línea de mascotas es incorrecto."}
    end
  end
end
