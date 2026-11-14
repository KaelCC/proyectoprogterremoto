defmodule Personas do

  @estados [
    "afectada",
    "desaparecida",
    "localizada",
    "rescatada",
    "alojada"
  ]

  # --------------------------------------------------
  # VALIDACIONES
  # --------------------------------------------------

  def texto_valido?(texto) do
    is_binary(texto) and String.trim(texto) != ""
  end

  def validar_edad(edad) do
    if is_integer(edad) and edad >= 0 do
      :ok
    else
      {:error, "La edad debe ser un numero entero mayor o igual a cero."}
    end
  end

  defp validar_zona(codigo_zona) do

  case PersistenciaZonas.cargar() do

    {:ok, zonas} ->
      case Zonas.buscar_zona(zonas, codigo_zona) do
        nil -> {:error, "La zona indicada no existe."}
        %Zona{} -> :ok
      end

    {:error, razon} ->
      {:error, "No se pudieron cargar las zonas: #{inspect(razon)}"}

  end
end

  def validar_estado(estado) do
    if estado in @estados do
      :ok
    else
      {:error, "El estado ingresado no es valido."}
    end
  end

  def codigo_existe?(personas, codigo) do
    Enum.any?(personas, fn persona ->
      persona.codigo == codigo
    end)
  end

  # --------------------------------------------------
  # BUSCAR PERSONAS
  # --------------------------------------------------

  def buscar_persona(personas, codigo) do
    Enum.find(personas, fn persona ->
      persona.codigo == codigo
    end)
  end

  # --------------------------------------------------
  # REGISTRAR PERSONA
  # --------------------------------------------------

  def registrar_persona(personas, codigo, nombre, edad, zona) do

    with true <- texto_valido?(codigo),
     true <- texto_valido?(nombre),
     true <- texto_valido?(zona),
     false <- codigo_existe?(personas, String.trim(codigo)),
     :ok <- validar_edad(edad),
     :ok <- validar_zona(String.trim(zona)) do

      persona = %Persona{
        codigo: String.trim(codigo),
        nombre: String.trim(nombre),
        edad: edad,
        zona: String.trim(zona),
        estado: "afectada",
        albergue: nil,
        historial: ["Registro inicial"]
      }

      nuevas_personas = [persona | personas]

      case guardar_cambios(nuevas_personas) do
        :ok ->
          {:ok, nuevas_personas}

        {:error, razon} ->
          {:error, "No se pudo guardar la persona: #{razon}"}
      end

    else
      true ->
        {:error, "El codigo ya existe o hay campos invalidos."}

      false ->
        {:error, "Los campos de texto son obligatorios."}

      {:error, razon} ->
        {:error, razon}
    end
  end

  # --------------------------------------------------
  # LISTAR PERSONAS
  # --------------------------------------------------

  def listar_personas(personas) do
    personas
  end

  # --------------------------------------------------
  # FILTRAR POR ZONA
  # --------------------------------------------------

  def filtrar_por_zona(personas, zona) do
    Enum.filter(personas, fn persona ->
      persona.zona == zona
    end)
  end

  # --------------------------------------------------
  # FILTRAR POR ESTADO
  # --------------------------------------------------

  def filtrar_por_estado(personas, estado) do
    Enum.filter(personas, fn persona ->
      persona.estado == estado
    end)
  end

  # --------------------------------------------------
  # ACTUALIZAR ESTADO
  # --------------------------------------------------

  def actualizar_estado(personas, codigo, nuevo_estado) do

    with :ok <- validar_estado(nuevo_estado),
         %Persona{} = persona <- buscar_persona(personas, codigo) do

      persona_actualizada = %{
        persona |
        estado: nuevo_estado,
        historial: persona.historial ++ ["Estado actualizado a: #{nuevo_estado}"]
      }

      nuevas_personas =
        Enum.map(personas, fn persona_actual ->
          if persona_actual.codigo == codigo do
            persona_actualizada
          else
            persona_actual
          end
        end)

      case guardar_cambios(nuevas_personas) do
        :ok ->
          {:ok, nuevas_personas}

        {:error, razon} ->
          {:error, "No se pudo actualizar la persona: #{razon}"}
      end

    else
      {:error, razon} ->
        {:error, razon}

      nil ->
        {:error, "No se encontro una persona con ese codigo."}
    end
  end

  # --------------------------------------------------
  # GUARDAR CAMBIOS
  # --------------------------------------------------

  defp guardar_cambios(personas) do
    PersistenciaPersonas.guardar(personas)
  end

end
