defmodule PersistenciaNecesidades do

  @ruta Path.expand("../../priv/data/necesidades.txt", __DIR__)

  # Guardar todas las necesidades
  def guardar(necesidades) do
    try do
      File.mkdir_p!(Path.dirname(@ruta))

      contenido =
        Enum.map(necesidades, fn necesidad ->
          campos = [
            "N",
            necesidad.id,
            necesidad.tipo,
            necesidad.descripcion,
            Integer.to_string(necesidad.cantidad),
            necesidad.zona,
            necesidad.prioridad,
            necesidad.responsable,
            necesidad.estado,
            Enum.join(necesidad.recursos_asignados, ",")
          ]

          campos
          |> Enum.map(&Base.encode64/1)
          |> Enum.join("|")
        end)

      texto = Enum.join(contenido, "\n")

      case File.write(@ruta, texto) do
        :ok ->
          {:ok, "Necesidades guardadas correctamente."}

        {:error, razon} ->
          {:error, "No se pudieron guardar las necesidades: #{inspect(razon)}"}
      end

    rescue
      error ->
        {:error, "Error al guardar las necesidades: #{Exception.message(error)}"}
    end
  end

  # Cargar necesidades desde el archivo
  def cargar do
    try do
      File.mkdir_p!(Path.dirname(@ruta))

      unless File.exists?(@ruta) do
        File.write!(@ruta, "")
      end

      case File.read(@ruta) do
        {:ok, contenido} ->
          lineas = String.split(contenido, "\n", trim: true)

          resultado =
            lineas
            |> Enum.with_index(1)
            |> Enum.reduce_while({:ok, []}, fn {linea, numero}, {:ok, acumuladas} ->

              case procesar_linea(linea) do
                {:ok, necesidad} ->
                  if Enum.any?(acumuladas, fn existente ->
                    existente.id == necesidad.id
                  end) do
                    {:halt, {:error, "Identificador duplicado en la línea #{numero}."}}
                  else
                    {:cont, {:ok, acumuladas ++ [necesidad]}}
                  end

                {:error, razon} ->
                  {:halt, {:error, "Error en la línea #{numero}: #{razon}"}}
              end

            end)

          resultado

        {:error, razon} ->
          {:error, "No se pudo leer el archivo: #{inspect(razon)}"}
      end

    rescue
      error ->
        {:error, "Error al cargar las necesidades: #{Exception.message(error)}"}
    end
  end

  # Procesar una línea del archivo
  defp procesar_linea(linea) do
    campos = String.split(linea, "|")

    with ["N", id, tipo, descripcion, cantidad, zona,
          prioridad, responsable, estado, recursos] <- decodificar_campos(campos),
         {:ok, cantidad} <- convertir_cantidad(cantidad),
         true <- id != "",
         true <- tipo != "",
         true <- descripcion != "",
         true <- zona != "",
         true <- responsable != "",
         true <- prioridad in ["critica", "alta", "media", "baja"],
         true <- estado in [
           "pendiente",
           "asignada",
           "en_atencion",
           "atendida",
           "cancelada"
         ] do

      necesidad = %Necesidad{
        id: id,
        tipo: tipo,
        descripcion: descripcion,
        cantidad: cantidad,
        zona: zona,
        prioridad: prioridad,
        responsable: responsable,
        estado: estado,
        recursos_asignados:
          if recursos == "" do
            []
          else
            String.split(recursos, ",")
          end
      }

      {:ok, necesidad}

    else
      {:error, razon} ->
        {:error, razon}

      false ->
        {:error, "La información contiene campos inválidos."}

      _ ->
        {:error, "El formato del registro no es válido."}
    end
  end

  # Decodificar los campos de Base64
  defp decodificar_campos(campos) do
    Enum.reduce_while(campos, {:ok, []}, fn campo, {:ok, acumulados} ->
      case Base.decode64(campo) do
        {:ok, valor} ->
          {:cont, {:ok, acumulados ++ [valor]}}

        :error ->
          {:halt, {:error, "No se pudo decodificar un campo."}}
      end
    end)
    |> case do
      {:ok, valores} -> valores
      {:error, razon} -> {:error, razon}
    end
  end

  # Convertir cantidad a entero
  defp convertir_cantidad(cantidad) do
    case Integer.parse(cantidad) do
      {numero, ""} when numero > 0 ->
        {:ok, numero}

      _ ->
        {:error, "La cantidad almacenada no es válida."}
    end
  end

end
