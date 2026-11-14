
defmodule Recursos do

  # Validar textos
  defp texto_valido?(texto) do
    is_binary(texto) and String.trim(texto) != ""
  end

  # Comprobar si un código ya existe
  defp codigo_existe?(recursos, codigo) do
    Enum.any?(recursos, fn recurso ->
      recurso.codigo == codigo
    end)
  end

  # Registrar un recurso
  def registrar_recurso(
        recursos,
        codigo,
        nombre,
        categoria,
        cantidad,
        unidad,
        ubicacion
      ) do

    cond do
      not texto_valido?(codigo) or
      not texto_valido?(nombre) or
      not texto_valido?(categoria) or
      not texto_valido?(unidad) or
      not texto_valido?(ubicacion) ->

        {:error, "Todos los campos son obligatorios."}

      codigo_existe?(recursos, String.trim(codigo)) ->
        {:error, "Ya existe un recurso con ese código."}

      not is_integer(cantidad) or cantidad <= 0 ->
        {:error, "La cantidad debe ser un entero mayor que cero."}

      true ->

        nuevo_recurso = %Recurso{
          codigo: String.trim(codigo),
          nombre: String.trim(nombre),
          categoria: String.downcase(String.trim(categoria)),
          cantidad: cantidad,
          unidad: String.trim(unidad),
          ubicacion: String.trim(ubicacion),
          historial: [
            "Registro inicial: #{cantidad} #{String.trim(unidad)}"
          ]
        }

        guardar_cambios([nuevo_recurso | recursos])
    end
  end

  # Buscar recurso por código
  def buscar_recurso(recursos, codigo) do
    Enum.find(recursos, fn recurso ->
      recurso.codigo == codigo
    end)
  end

  # Listar todos los recursos
  def listar_recursos(recursos) do
    recursos
  end

  # Filtrar por categoría
  def filtrar_por_categoria(recursos, categoria) do
    categoria = String.downcase(String.trim(categoria))

    Enum.filter(recursos, fn recurso ->
      recurso.categoria == categoria
    end)
  end

  # Filtrar por ubicación
  def filtrar_por_zona(recursos, ubicacion) do
    Enum.filter(recursos, fn recurso ->
      recurso.ubicacion == ubicacion
    end)
  end

  # Registrar entradas o salidas del inventario
  def actualizar_cantidad(recursos, codigo, tipo, cantidad) do

    recurso = buscar_recurso(recursos, codigo)

    cond do
      is_nil(recurso) ->
        {:error, "El recurso no existe."}

      not is_integer(cantidad) or cantidad <= 0 ->
        {:error, "La cantidad debe ser un entero mayor que cero."}

      tipo not in ["entrada", "salida"] ->
        {:error, "El movimiento debe ser entrada o salida."}

      tipo == "salida" and cantidad > recurso.cantidad ->
        {:error, "No hay suficiente cantidad disponible."}

      true ->

        nueva_cantidad =
          if tipo == "entrada" do
            recurso.cantidad + cantidad
          else
            recurso.cantidad - cantidad
          end

        recursos_actualizados =
          Enum.map(recursos, fn elemento ->
            if elemento.codigo == codigo do
              %{
                elemento |
                cantidad: nueva_cantidad,
                historial: [
                  "#{tipo}: #{cantidad} #{recurso.unidad}"
                  | elemento.historial
                ]
              }
            else
              elemento
            end
          end)

        guardar_cambios(recursos_actualizados)
    end
  end

  # Asignar recursos a una necesidad
  def asignar_recurso(
        recursos,
        necesidades,
        codigo_recurso,
        id_necesidad,
        cantidad
      ) do

    recurso = buscar_recurso(recursos, codigo_recurso)
    necesidad = Necesidades.buscar_necesidad(necesidades, id_necesidad)

    cond do
      is_nil(recurso) ->
        {:error, "El recurso no existe."}

      is_nil(necesidad) ->
        {:error, "La necesidad no existe."}

      not is_integer(cantidad) or cantidad <= 0 ->
        {:error, "La cantidad debe ser un entero mayor que cero."}

      cantidad > recurso.cantidad ->
        {:error, "No hay suficiente inventario para realizar la asignación."}

      necesidad.estado not in ["pendiente", "asignada", "en_atencion"] ->
        {:error, "La necesidad no permite recibir más recursos."}

      true ->

        recursos_actualizados =
          Enum.map(recursos, fn elemento ->
            if elemento.codigo == codigo_recurso do
              %{
                elemento |
                cantidad: elemento.cantidad - cantidad,
                historial: [
                  "Asignación de #{cantidad} #{elemento.unidad} a #{id_necesidad}"
                  | elemento.historial
                ]
              }
            else
              elemento
            end
          end)

        asignacion = "#{codigo_recurso}:#{cantidad}"

        nueva_necesidad = %{
          necesidad |
          estado:
            if necesidad.estado == "pendiente" do
              "asignada"
            else
              necesidad.estado
            end,
          recursos_asignados: [
            asignacion | necesidad.recursos_asignados
          ]
        }

        necesidades_actualizadas =
          Enum.map(necesidades, fn elemento ->
            if elemento.id == id_necesidad do
              nueva_necesidad
            else
              elemento
            end
          end)

        guardar_asignacion(
          recursos,
          recursos_actualizados,
          necesidades_actualizadas
        )
    end
  end

  # Guardar los cambios de una asignación
  defp guardar_asignacion(
       recursos_originales,
       recursos_actualizados,
       necesidades_actualizadas
     ) do

  case PersistenciaRecursos.guardar(recursos_actualizados) do

    {:ok, _mensaje} ->

      case PersistenciaNecesidades.guardar(necesidades_actualizadas) do

        {:ok, _mensaje} ->
          {:ok, recursos_actualizados, necesidades_actualizadas}

        {:error, razon} ->

          case PersistenciaRecursos.guardar(recursos_originales) do

            {:ok, _mensaje} ->
              {:error,
               "No se pudieron guardar las necesidades. " <>
               "El inventario anterior fue restaurado: #{razon}"}

            {:error, error_restauracion} ->
              {:error,
               "No se pudieron guardar las necesidades: #{razon}. " <>
               "Además, falló la restauración del inventario: #{error_restauracion}"}
          end
      end

    {:error, razon} ->
      {:error, "No se pudieron guardar los recursos: #{razon}"}
   end
  end

  # Transferir una cantidad a otra ubicación
  def transferir_recurso(
        recursos,
        codigo_origen,
        nuevo_codigo,
        cantidad,
        nueva_ubicacion
      ) do

    recurso = buscar_recurso(recursos, codigo_origen)

    cond do
      is_nil(recurso) ->
        {:error, "El recurso de origen no existe."}

      not texto_valido?(nuevo_codigo) or
      not texto_valido?(nueva_ubicacion) ->
        {:error, "El código y la ubicación son obligatorios."}

      codigo_existe?(recursos, String.trim(nuevo_codigo)) ->
        {:error, "El nuevo código ya está registrado."}

      not is_integer(cantidad) or cantidad <= 0 ->
        {:error, "La cantidad debe ser un entero mayor que cero."}

      cantidad > recurso.cantidad ->
        {:error, "No hay suficiente inventario para transferir."}

      true ->

        nuevo_codigo = String.trim(nuevo_codigo)
        nueva_ubicacion = String.trim(nueva_ubicacion)

        recursos_actualizados =
          Enum.map(recursos, fn elemento ->
            if elemento.codigo == codigo_origen do
              %{
                elemento |
                cantidad: elemento.cantidad - cantidad,
                historial: [
                  "Transferencia de #{cantidad} a #{nueva_ubicacion}"
                  | elemento.historial
                ]
              }
            else
              elemento
            end
          end)

        recurso_destino = %{
          recurso |
          codigo: nuevo_codigo,
          cantidad: cantidad,
          ubicacion: nueva_ubicacion,
          historial: [
            "Recibido por transferencia desde #{codigo_origen}"
          ]
        }

        guardar_cambios([recurso_destino | recursos_actualizados])
    end
  end

  # Guardar cambios del inventario
  defp guardar_cambios(recursos) do
    case PersistenciaRecursos.guardar(recursos) do

      {:ok, _mensaje} ->
        {:ok, recursos}

      {:error, razon} ->
        {:error, razon}
    end
  end

end
