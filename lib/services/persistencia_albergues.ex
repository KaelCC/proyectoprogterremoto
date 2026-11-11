
defmodule PersistenciaAlbergues do

  # Ruta del archivo de albergues.
  @ruta Path.expand("../../priv/data/albergues.txt", __DIR__)

  # --------------------------------------------------
  # GUARDAR ALBERGUES
  # --------------------------------------------------

  def guardar(albergues) do

    with :ok <- File.mkdir_p(Path.dirname(@ruta)),
         contenido <- serializar(albergues),
         :ok <- File.write(@ruta, contenido) do

      {:ok, "Albergues guardados correctamente."}

    else
      {:error, razon} ->
        {:error, "No se pudieron guardar los albergues: #{inspect(razon)}"}
    end

  end

  # --------------------------------------------------
  # SERIALIZAR
  # --------------------------------------------------

  defp serializar(albergues) do

    lineas =
      Enum.map(albergues, fn albergue ->

        personas = Enum.join(albergue.personas, "~")
        recursos = Enum.join(albergue.recursos_asignados, "~")

        [
          "A",
          codificar(albergue.codigo),
          codificar(albergue.nombre),
          codificar(albergue.zona),
          codificar(Integer.to_string(albergue.capacidad_maxima)),
          codificar(personas),
          codificar(recursos)
        ]
        |> Enum.join("|")

      end)

    Enum.join(lineas, "\n") <>
      if(lineas == [], do: "", else: "\n")

  end

  # Codifica un campo.
  defp codificar(valor) do
    Base.encode64(valor)
  end

  # --------------------------------------------------
  # CARGAR ALBERGUES
  # --------------------------------------------------

  def cargar do

    with :ok <- File.mkdir_p(Path.dirname(@ruta)),
         :ok <- crear_archivo_si_no_existe(),
         {:ok, contenido} <- File.read(@ruta),
         {:ok, zonas} <- PersistenciaZonas.cargar() do

      contenido
      |> String.split(~r/\r\n|\n|\r/, trim: true)
      |> Enum.with_index(1)
      |> Enum.reduce_while({:ok, []}, fn {linea, numero}, {:ok, albergues} ->

        case procesar_linea(linea, albergues, zonas) do

          {:ok, nuevos_albergues} ->
            {:cont, {:ok, nuevos_albergues}}

          {:error, razon} ->
            {:halt, {:error, "Error en la linea #{numero}: #{razon}"}}

        end

      end)

    else
      {:error, razon} ->
        {:error, "No se pudieron cargar los albergues: #{inspect(razon)}"}
    end

  end

  # --------------------------------------------------
  # CREAR ARCHIVO SI NO EXISTE
  # --------------------------------------------------

  defp crear_archivo_si_no_existe do

    if File.exists?(@ruta) do
      :ok
    else
      File.write(@ruta, "")
    end

  end

  # --------------------------------------------------
  # PROCESAR CADA LINEA
  # --------------------------------------------------

  defp procesar_linea(linea, albergues, zonas) do

    case String.split(linea, "|") do

      ["A", codigo, nombre, zona, capacidad, personas, recursos] ->

        with {:ok, [
               codigo,
               nombre,
               zona,
               capacidad,
               personas,
               recursos
             ]} <-
               decodificar_campos([
                 codigo,
                 nombre,
                 zona,
                 capacidad,
                 personas,
                 recursos
               ]),
             {cantidad, ""} <- Integer.parse(capacidad),
             :ok <- validar_textos(codigo, nombre, zona),
             :ok <- Albergues.validar_capacidad(cantidad),
             {:ok, lista_personas} <- decodificar_lista(personas),
             {:ok, lista_recursos} <- decodificar_lista(recursos),
             true <- length(lista_personas) <= cantidad,
             false <- Enum.uniq(lista_personas) != lista_personas,
             false <- Albergues.codigo_existe?(albergues, codigo),
             %Zona{} <- Zonas.buscar_zona(zonas, zona) do

          nuevo_albergue = %Albergue{
            codigo: codigo,
            nombre: nombre,
            zona: zona,
            capacidad_maxima: cantidad,
            personas: lista_personas,
            recursos_asignados: lista_recursos
          }

          {:ok, albergues ++ [nuevo_albergue]}

        else
          true ->
            {:error, "La ocupacion supera la capacidad o hay datos duplicados."}

          false ->
            {:error, "Hay personas duplicadas o el codigo del albergue ya existe."}

          nil ->
            {:error, "La zona del albergue no existe."}

          {:error, razon} ->
            {:error, razon}

          _ ->
            {:error, "Registro de albergue invalido."}
        end

      _ ->
        {:error, "Tipo de registro o cantidad de campos incorrectos."}

    end

  end

  # --------------------------------------------------
  # VALIDAR TEXTOS
  # --------------------------------------------------

  defp validar_textos(codigo, nombre, zona) do

    if Albergues.texto_valido?(codigo) and
       Albergues.texto_valido?(nombre) and
       Albergues.texto_valido?(zona) do

      :ok

    else
      {:error, "El codigo, nombre y zona son obligatorios."}
    end

  end

  # --------------------------------------------------
  # DECODIFICAR CAMPOS
  # --------------------------------------------------

  defp decodificar_campos(campos) do

    Enum.reduce_while(campos, {:ok, []}, fn campo, {:ok, acumulador} ->

      case Base.decode64(campo) do

        {:ok, valor} ->
          {:cont, {:ok, acumulador ++ [valor]}}

        :error ->
          {:halt, {:error, "No se pudo decodificar un campo."}}

      end

    end)

  end

  # --------------------------------------------------
  # DECODIFICAR LISTAS
  # --------------------------------------------------

  defp decodificar_lista("") do
    {:ok, []}
  end

  defp decodificar_lista(contenido) do
    {:ok, String.split(contenido, "~", trim: true)}
  end

end
