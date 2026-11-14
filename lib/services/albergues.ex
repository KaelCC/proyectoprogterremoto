
defmodule Albergues do

  # --------------------------------------------------
  # VALIDACIONES
  # --------------------------------------------------

  def texto_valido?(texto) do
    is_binary(texto) and String.trim(texto) != ""
  end

  def validar_capacidad(capacidad) do
    if is_integer(capacidad) and capacidad > 0 do
      :ok
    else
      {:error, "La capacidad debe ser un entero mayor que cero."}
    end
  end

  def codigo_existe?(albergues, codigo) do
    Enum.any?(albergues, fn albergue ->
      albergue.codigo == codigo
    end)
  end

  def persona_alojada?(albergues, codigo_persona) do
    Enum.any?(albergues, fn albergue ->
      codigo_persona in albergue.personas
    end)
  end

  # --------------------------------------------------
  # BUSCAR ALBERGUE
  # --------------------------------------------------

  def buscar_albergue(albergues, codigo) do
    Enum.find(albergues, fn albergue ->
      albergue.codigo == codigo
    end)
  end

  # --------------------------------------------------
  # REGISTRAR ALBERGUE
  # --------------------------------------------------

  def registrar_albergue(
        albergues,
        codigo,
        nombre,
        codigo_zona,
        capacidad_maxima
      ) do

    with true <- texto_valido?(codigo),
         true <- texto_valido?(nombre),
         true <- texto_valido?(codigo_zona),
         false <- codigo_existe?(albergues, String.trim(codigo)),
         :ok <- validar_capacidad(capacidad_maxima),
         %Zona{} <- Zonas.buscar_zona(
           obtener_zonas(),
           String.trim(codigo_zona)
         ) do

      nuevo_albergue = %Albergue{
        codigo: String.trim(codigo),
        nombre: String.trim(nombre),
        zona: String.trim(codigo_zona),
        capacidad_maxima: capacidad_maxima,
        personas: [],
        recursos_asignados: []
      }

      guardar_cambios([nuevo_albergue | albergues])

    else
      true ->
        {:error, "El codigo del albergue ya existe."}

      false ->
        {:error, "Los campos de texto son obligatorios."}

      nil ->
        {:error, "La zona indicada no existe."}

      {:error, razon} ->
        {:error, razon}

      _ ->
        {:error, "No se pudo registrar el albergue."}
    end

  end

  # --------------------------------------------------
  # LISTAR ALBERGUES
  # --------------------------------------------------

  def listar_albergues(albergues) do
    albergues
  end

  # --------------------------------------------------
  # FILTRAR POR ZONA
  # --------------------------------------------------

  def filtrar_por_zona(albergues, codigo_zona) do
    Enum.filter(albergues, fn albergue ->
      albergue.zona == codigo_zona
    end)
  end

  # --------------------------------------------------
  # CONSULTAR OCUPACION
  # --------------------------------------------------

  def ocupacion(albergue) do
    length(albergue.personas)
  end

  # --------------------------------------------------
  # CONSULTAR CUPOS DISPONIBLES
  # --------------------------------------------------

  def cupos_disponibles(albergues, codigo) do

    case buscar_albergue(albergues, codigo) do

      nil ->
        {:error, "El albergue no existe."}

      albergue ->
        disponibles =
          albergue.capacidad_maxima - ocupacion(albergue)

        {:ok, disponibles}

    end

  end

  # --------------------------------------------------
  # ALOJAR PERSONA
  # --------------------------------------------------

  def alojar_persona(albergues, personas, codigo_albergue, codigo_persona) do

    albergue = buscar_albergue(albergues, codigo_albergue)
    persona = Personas.buscar_persona(personas, codigo_persona)

    cond do
      is_nil(albergue) ->
        {:error, "No se encontro el albergue."}

      is_nil(persona) ->
        {:error, "No se encontro la persona registrada."}

      persona.albergue != nil ->
        {:error, "La persona ya pertenece a un albergue."}

      persona_alojada?(albergues, codigo_persona) ->
        {:error, "La persona ya aparece registrada en otro albergue."}

      persona.estado not in ["afectada", "localizada", "rescatada"] ->
        {:error, "El estado actual de la persona no permite alojarla."}

      persona.codigo in albergue.personas ->
        {:error, "La persona ya esta registrada en este albergue."}

      ocupacion(albergue) >= albergue.capacidad_maxima ->
        {:error, "El albergue no tiene cupos disponibles."}

      true ->

        albergue_actualizado = %{
          albergue |
          personas: albergue.personas ++ [codigo_persona]
        }

        persona_actualizada = %{
          persona |
          estado: "alojada",
          albergue: codigo_albergue,
          historial: persona.historial ++ [
            "Alojada en el albergue: #{codigo_albergue}"
          ]
        }

        nuevos_albergues =
          Enum.map(albergues, fn actual ->
            if actual.codigo == codigo_albergue do
              albergue_actualizado
            else
              actual
            end
          end)

        nuevas_personas =
          Enum.map(personas, fn actual ->
            if actual.codigo == codigo_persona do
              persona_actualizada
            else
              actual
            end
          end)

        with {:ok, _mensaje} <- PersistenciaAlbergues.guardar(nuevos_albergues),
             :ok <- PersistenciaPersonas.guardar(nuevas_personas) do

          {:ok, nuevos_albergues, nuevas_personas}

        else
          {:error, razon} ->
            {:error, "Error al guardar los datos: #{inspect(razon)}"}
        end

    end
  end

  # --------------------------------------------------
  # RETIRAR PERSONA
  # --------------------------------------------------

  def retirar_persona(albergues, personas, codigo_albergue, codigo_persona) do

    albergue = buscar_albergue(albergues, codigo_albergue)
    persona = Personas.buscar_persona(personas, codigo_persona)

    cond do
      is_nil(albergue) ->
        {:error, "No se encontro el albergue."}

      is_nil(persona) ->
        {:error, "No se encontro la persona registrada."}

      persona.albergue != codigo_albergue or
        codigo_persona not in albergue.personas ->
        {:error, "La persona no pertenece a este albergue o los registros no coinciden."}

      true ->

        albergue_actualizado = %{
          albergue |
          personas: List.delete(albergue.personas, codigo_persona)
        }

        persona_actualizada = %{
          persona |
          estado: "rescatada",
          albergue: nil,
          historial: persona.historial ++ [
            "Retirada del albergue: #{codigo_albergue}"
          ]
        }

        nuevos_albergues =
          Enum.map(albergues, fn actual ->
            if actual.codigo == codigo_albergue do
              albergue_actualizado
            else
              actual
            end
          end)

        nuevas_personas =
          Enum.map(personas, fn actual ->
            if actual.codigo == codigo_persona do
              persona_actualizada
            else
              actual
            end
          end)

        with {:ok, _mensaje} <- PersistenciaAlbergues.guardar(nuevos_albergues),
             :ok <- PersistenciaPersonas.guardar(nuevas_personas) do

          {:ok, nuevos_albergues, nuevas_personas}

        else
          {:error, razon} ->
            {:error, "Error al guardar los datos: #{inspect(razon)}"}
        end

    end
  end

  # --------------------------------------------------
  # ACTUALIZAR CAPACIDAD
  # --------------------------------------------------

  def actualizar_capacidad(albergues, codigo, nueva_capacidad) do

    albergue = buscar_albergue(albergues, codigo)

    with %Albergue{} <- albergue,
         :ok <- validar_capacidad(nueva_capacidad),
         true <- nueva_capacidad >= ocupacion(albergue) do

      albergue_actualizado = %{
        albergue |
        capacidad_maxima: nueva_capacidad
      }

      nuevos_albergues =
        Enum.map(albergues, fn albergue_actual ->
          if albergue_actual.codigo == codigo do
            albergue_actualizado
          else
            albergue_actual
          end
        end)

      guardar_cambios(nuevos_albergues)

    else
      nil ->
        {:error, "El albergue no existe."}

      false ->
        {:error, "La capacidad no puede ser menor que la ocupacion actual."}

      {:error, razon} ->
        {:error, razon}

      _ ->
        {:error, "No se pudo actualizar la capacidad."}
    end

  end

  # --------------------------------------------------
  # PERSISTENCIA
  # --------------------------------------------------

  defp guardar_cambios(albergues) do

    case PersistenciaAlbergues.guardar(albergues) do

      {:ok, _mensaje} ->
        {:ok, albergues}

      {:error, razon} ->
        {:error, razon}

    end

  end

  # --------------------------------------------------
  # OBTENER ZONAS
  # --------------------------------------------------

  defp obtener_zonas do
    case PersistenciaZonas.cargar() do
      {:ok, zonas} -> zonas
      {:error, _razon} -> []
    end
  end

end
