
defmodule PersistenciaRecursos do

  @ruta Path.expand("../../priv/data/recursos.txt", __DIR__)

  # Guardar todos los recursos
  def guardar(recursos) do
    try do
      File.mkdir_p!(Path.dirname(@ruta))

      contenido =
        Enum.map(recursos, fn recurso ->
          campos = [
            "R",
            recurso.codigo,
            recurso.nombre,
            recurso.categoria,
            Integer.to_string(recurso.cantidad),
            recurso.unidad,
            recurso.ubicacion,
            Enum.join(recurso.historial, "~")
          ]

          campos
          |> Enum.map(&Base.encode64/1)
          |> Enum.join("|")
        end)

      texto = Enum.join(contenido, "\n")

      case File.write(@ruta, texto) do
        :ok ->
          {:ok, "Recursos guardados correctamente."}

        {:error, razon} ->
          {:error, "No se pudieron guardar los recursos: #{inspect(razon)}"}
      end

    rescue
      error ->
        {:error, "Error al guardar recursos: #{Exception.message(error)}"}
    end
  end

  # Cargar todos los recursos
  def cargar do
    try do
      File.mkdir_p!(Path.dirname(@ruta))

      unless File.exists?(@ruta) do
        File.write!(@ruta, "")
      end

      case File.read(@ruta) do
        {:ok, contenido} ->
          lineas = String.split(contenido, "\n", trim: true)

          lineas
          |> Enum.with_index(1)
          |> Enum.reduce_while({:ok, []}, fn {linea, numero}, {:ok, acumulados} ->

            case procesar_linea(linea) do
              {:ok, recurso} ->
                if Enum.any?(acumulados, fn existente ->
                  existente.codigo == recurso.codigo
                end) do
                  {:halt, {:error, "Código duplicado en la línea #{numero}."}}
                else
                  {:cont, {:ok, acumulados ++ [recurso]}}
                end

              {:error, razon} ->
                {:halt, {:error, "Error en la línea #{numero}: #{razon}"}}
            end

          end)

        {:error, razon} ->
          {:error, "No se pudo leer el archivo: #{inspect(razon)}"}
      end

    rescue
      error ->
        {:error, "Error al cargar recursos: #{Exception.message(error)}"}
    end
  end

  # Procesar cada línea
  defp procesar_linea(linea) do
    campos = String.split(linea, "|")

    with ["R", codigo, nombre, categoria, cantidad,
          unidad, ubicacion, historial] <- decodificar_campos(campos),
         {:ok, cantidad} <- convertir_cantidad(cantidad),
         true <- codigo != "",
         true <- nombre != "",
         true <- categoria != "",
         true <- unidad != "",
         true <- ubicacion != "" do

      recurso = %Recurso{
        codigo: codigo,
        nombre: nombre,
        categoria: categoria,
        cantidad: cantidad,
        unidad: unidad,
        ubicacion: ubicacion,
        historial:
          if historial == "" do
            []
          else
            String.split(historial, "~")
          end
      }

      {:ok, recurso}

    else
      {:error, razon} ->
        {:error, razon}

      false ->
        {:error, "El registro contiene campos vacíos."}

      _ ->
        {:error, "El formato del registro no es válido."}
    end
  end

  # Decodificar campos Base64
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

  # Convertir cantidad
  defp convertir_cantidad(cantidad) do
    case Integer.parse(cantidad) do
      {numero, ""} when numero >= 0 ->
        {:ok, numero}

      _ ->
        {:error, "La cantidad almacenada no es válida."}
    end
  end

end
