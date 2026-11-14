defmodule PersistenciaPersonas do

  # Ruta del archivo de personas.
  @ruta Path.expand("../../priv/data/personas.txt", __DIR__)

  @estados [
    "afectada",
    "desaparecida",
    "localizada",
    "rescatada",
    "alojada"
  ]

  # --------------------------------------------------
  # GUARDAR PERSONAS
  # --------------------------------------------------

  def guardar(personas) do

    with :ok <- File.mkdir_p(Path.dirname(@ruta)),
         contenido <- serializar(personas),
         :ok <- File.write(@ruta, contenido) do

      :ok

    else
      {:error, razon} ->
        {:error, "Error al guardar las personas: #{inspect(razon)}"}
    end
  end

  # --------------------------------------------------
  # SERIALIZAR PERSONAS
  # --------------------------------------------------

  defp serializar(personas) do

    personas
    |> Enum.map(fn persona ->

      campos = [
        persona.codigo,
        persona.nombre,
        to_string(persona.edad),
        persona.zona,
        persona.estado,
        persona.albergue || "",
        Enum.join(persona.historial, "~")
      ]

      campos_codificados =
        Enum.map(campos, fn campo ->
          Base.encode64(campo)
        end)

      Enum.join(["P" | campos_codificados], "|")

    end)
    |> Enum.join("\n")
  end

  # --------------------------------------------------
  # CARGAR PERSONAS
  # --------------------------------------------------

  def cargar do

    with :ok <- File.mkdir_p(Path.dirname(@ruta)),
         :ok <- crear_archivo(),
         {:ok, contenido} <- File.read(@ruta) do

      contenido
      |> String.split(~r/\r\n|\n|\r/, trim: true)
      |> Enum.with_index(1)
      |> Enum.reduce_while({:ok, []}, fn {linea, numero}, {:ok, personas} ->

        case procesar_linea(linea, personas) do

          {:ok, nuevas_personas} ->
            {:cont, {:ok, nuevas_personas}}

          {:error, razon} ->
            {:halt, {:error, "Error en la linea #{numero}: #{razon}"}}

        end

      end)

    else
      {:error, razon} ->
        {:error, "Error al cargar las personas: #{inspect(razon)}"}
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
  # PROCESAR CADA LINEA
  # --------------------------------------------------

  defp procesar_linea(linea, personas) do

    case String.split(linea, "|") do

      ["P", codigo, nombre, edad_texto, zona, estado, albergue, historial] ->

        campos = [
          codigo,
          nombre,
          edad_texto,
          zona,
          estado,
          albergue,
          historial
        ]

        with {:ok, campos} <- decodificar_campos(campos),
             [codigo, nombre, edad_texto, zona, estado, albergue, historial] <- campos,
             {edad, ""} <- Integer.parse(edad_texto),
             true <- texto_valido?(codigo),
             true <- texto_valido?(nombre),
             true <- texto_valido?(zona),
             true <- edad >= 0,
             true <- estado in @estados,
             false <- Personas.codigo_existe?(personas, codigo) do

          persona = %Persona{
            codigo: codigo,
            nombre: nombre,
            edad: edad,
            zona: zona,
            estado: estado,
            albergue: if(albergue == "", do: nil, else: albergue),
            historial: decodificar_historial(historial)
          }

          {:ok, personas ++ [persona]}

        else
          {:error, razon} ->
            {:error, razon}

          true ->
            {:error, "El codigo de la persona esta duplicado."}

          false ->
            {:error, "Los datos de la persona son invalidos."}

          _ ->
            {:error, "Registro de persona invalido."}
        end

      _ ->
        {:error, "Formato de registro incorrecto."}

    end
  end

  # --------------------------------------------------
  # DECODIFICAR CAMPOS
  # --------------------------------------------------

  defp decodificar_campos(campos) do

    Enum.reduce_while(campos, {:ok, []}, fn campo, {:ok, acumulados} ->

      case Base.decode64(campo) do

        {:ok, valor} ->
          {:cont, {:ok, acumulados ++ [valor]}}

        :error ->
          {:halt, {:error, "No se pudo decodificar un campo."}}

      end

    end)
  end

  # --------------------------------------------------
  # DECODIFICAR HISTORIAL
  # --------------------------------------------------

  defp decodificar_historial("") do
    []
  end

  defp decodificar_historial(historial) do
    String.split(historial, "~", trim: true)
  end

  # --------------------------------------------------
  # VALIDAR TEXTO
  # --------------------------------------------------

  defp texto_valido?(texto) do
    is_binary(texto) and String.trim(texto) != ""
  end

end
