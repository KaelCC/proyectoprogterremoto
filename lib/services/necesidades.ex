defmodule Necesidades do

  @prioridades ["critica", "alta", "media", "baja"]

  @estados [
    "pendiente",
    "asignada",
    "en_atencion",
    "atendida",
    "cancelada"
  ]

  # Validar que un texto no esté vacío
  defp texto_valido?(texto) do
    is_binary(texto) and String.trim(texto) != ""
  end

  # Validar cantidad
  defp validar_cantidad(cantidad) do
    if is_integer(cantidad) and cantidad > 0 do
      {:ok, cantidad}
    else
      {:error, "La cantidad debe ser un número entero mayor que cero."}
    end
  end

  # Validar prioridad
  defp validar_prioridad(prioridad) do
    if texto_valido?(prioridad) do
      prioridad = String.downcase(String.trim(prioridad))

      if prioridad in @prioridades do
        {:ok, prioridad}
      else
        {:error, "La prioridad no es válida."}
      end
    else
      {:error, "Debe ingresar una prioridad."}
    end
  end

  # Comprobar si un identificador ya existe
  defp id_existe?(necesidades, id) do
    Enum.any?(necesidades, fn necesidad ->
      necesidad.id == id
    end)
  end

  # Registrar una necesidad
  def registrar_necesidad(
        necesidades,
        zonas,
        id,
        tipo,
        descripcion,
        cantidad,
        codigo_zona,
        prioridad,
        responsable
      ) do

    with true <- texto_valido?(id),
         true <- texto_valido?(tipo),
         true <- texto_valido?(descripcion),
         true <- texto_valido?(codigo_zona),
         true <- texto_valido?(responsable),
         false <- id_existe?(necesidades, id),
         {:ok, cantidad} <- validar_cantidad(cantidad),
         {:ok, prioridad} <- validar_prioridad(prioridad),
         %Zona{} <- Zonas.buscar_zona(zonas, codigo_zona) do

      nueva_necesidad = %Necesidad{
        id: String.trim(id),
        tipo: String.trim(tipo),
        descripcion: String.trim(descripcion),
        cantidad: cantidad,
        zona: String.trim(codigo_zona),
        prioridad: prioridad,
        responsable: String.trim(responsable),
        estado: "pendiente",
        recursos_asignados: []
      }

      guardar_cambios([nueva_necesidad | necesidades])

    else
      false ->
        {:error, "Hay campos obligatorios vacíos."}

      true ->
        {:error, "Ya existe una necesidad con ese identificador."}

      nil ->
        {:error, "La zona indicada no existe."}

      {:error, razon} ->
        {:error, razon}

      _ ->
        {:error, "No fue posible registrar la necesidad."}
    end
  end

  # Buscar una necesidad por su identificador
  def buscar_necesidad(necesidades, id) do
    Enum.find(necesidades, fn necesidad ->
      necesidad.id == id
    end)
  end

  # Listar todas las necesidades
  def listar_necesidades(necesidades) do
    necesidades
  end

  # Filtrar necesidades por estado
  def filtrar_por_estado(necesidades, estado) do
    Enum.filter(necesidades, fn necesidad ->
      necesidad.estado == estado
    end)
  end

  # Filtrar necesidades por prioridad
  def filtrar_por_prioridad(necesidades, prioridad) do
    Enum.filter(necesidades, fn necesidad ->
      necesidad.prioridad == prioridad
    end)
  end

  # Filtrar necesidades por zona
  def filtrar_por_zona(necesidades, codigo_zona) do
    Enum.filter(necesidades, fn necesidad ->
      necesidad.zona == codigo_zona
    end)
  end

  # Ordenar necesidades por prioridad
  def ordenar_por_prioridad(necesidades) do
    orden = %{
      "critica" => 1,
      "alta" => 2,
      "media" => 3,
      "baja" => 4
    }

    Enum.sort_by(necesidades, fn necesidad ->
      Map.get(orden, necesidad.prioridad, 5)
    end)
  end

  # Actualizar el estado de una necesidad
  def actualizar_estado(necesidades, id, nuevo_estado) do

    nuevo_estado = String.downcase(String.trim(nuevo_estado))

    necesidad = buscar_necesidad(necesidades, id)

    cond do
      is_nil(necesidad) ->
        {:error, "La necesidad no existe."}

      nuevo_estado not in @estados ->
        {:error, "El estado indicado no es válido."}

      necesidad.estado == nuevo_estado ->
        {:error, "La necesidad ya tiene ese estado."}

      not transicion_valida?(necesidad.estado, nuevo_estado) ->
        {:error, "No se permite esa transición de estado."}

      true ->
        necesidades_actualizadas =
          Enum.map(necesidades, fn elemento ->
            if elemento.id == id do
              %{elemento | estado: nuevo_estado}
            else
              elemento
            end
          end)

        guardar_cambios(necesidades_actualizadas)
    end
  end

  # Validar transiciones permitidas
  defp transicion_valida?(estado_actual, nuevo_estado) do
    transiciones = %{
      "pendiente" => ["asignada", "cancelada"],
      "asignada" => ["en_atencion", "cancelada"],
      "en_atencion" => ["atendida", "cancelada"],
      "atendida" => [],
      "cancelada" => []
    }

    nuevo_estado in Map.get(transiciones, estado_actual, [])
  end

  defp guardar_cambios(necesidades) do
    case PersistenciaNecesidades.guardar(necesidades) do
        {:ok, _mensaje} ->
        {:ok, necesidades}

        {:error, razon} ->
        {:error, razon}
    end
end

end
