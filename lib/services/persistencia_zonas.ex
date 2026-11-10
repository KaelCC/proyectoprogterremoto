defmodule PersistenciaZonas do

  # Ruta del archivo de zonas.
  @ruta Path.expand("../../priv/data/zonas.txt", __DIR__)

  # --------------------------------------------------
  # GUARDAR ZONAS
  # --------------------------------------------------

  def guardar(zonas) do

    with :ok <- File.mkdir_p(Path.dirname(@ruta)),
         contenido <- serializar(zonas),
         :ok <- File.write(@ruta, contenido) do

      {:ok, "Zonas guardadas correctamente."}

    else
      {:error, razon} ->
        {:error, "No se pudieron guardar las zonas: #{inspect(razon)}"}
    end

  end

  # Convierte las zonas, sectores y puntos en lineas de texto.
  defp serializar(zonas) do

    lineas =
      Enum.flat_map(zonas, fn zona ->

        linea_zona = [
          "Z",
          codificar(zona.codigo),
          codificar(zona.nombre),
          codificar(zona.nivel_afectacion),
          codificar(Integer.to_string(zona.personas_afectadas))
        ]

        linea_sector_punto =
          Enum.flat_map(zona.sectores, fn sector ->

            linea_sector = [
              "S",
              codificar(zona.codigo),
              codificar(sector.codigo),
              codificar(sector.nombre),
              codificar(sector.nivel_afectacion),
              codificar(Integer.to_string(sector.personas_afectadas))
            ]

            lineas_puntos =
              Enum.map(sector.puntos_atencion, fn punto ->

                [
                  "P",
                  codificar(zona.codigo),
                  codificar(sector.codigo),
                  codificar(punto.codigo),
                  codificar(punto.nombre),
                  codificar(punto.ubicacion),
                  codificar(punto.tipo),
                  codificar(punto.estado)
                ]
                |> Enum.join("|")

              end)

            [
              Enum.join(linea_sector, "|")
              | lineas_puntos
            ]

          end)

        [
          Enum.join(linea_zona, "|")
          | linea_sector_punto
        ]

      end)

    Enum.join(lineas, "\n") <> if(lineas == [], do: "", else: "\n")

  end

  # Codifica un campo para almacenarlo en el archivo.
  defp codificar(valor) do
    Base.encode64(valor)
  end

  # --------------------------------------------------
  # CARGAR ZONAS
  # --------------------------------------------------

  def cargar do

    with :ok <- File.mkdir_p(Path.dirname(@ruta)),
         :ok <- crear_archivo_si_no_existe(),
         {:ok, contenido} <- File.read(@ruta) do

      contenido
      |> String.split("\n", trim: true)
      |> Enum.with_index(1)
      |> Enum.reduce_while({:ok, []}, fn {linea, numero}, {:ok, zonas} ->

        case procesar_linea(linea, zonas) do

          {:ok, nuevas_zonas} ->
            {:cont, {:ok, nuevas_zonas}}

          {:error, razon} ->
            {:halt, {:error, "Error en la linea #{numero}: #{razon}"}}

        end

      end)

    else
      {:error, razon} ->
        {:error, "No se pudieron cargar las zonas: #{inspect(razon)}"}
    end

  end

  # Crea el archivo cuando todavia no existe.
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

  defp procesar_linea(linea, zonas) do

    case String.split(linea, "|") do

      ["Z", codigo, nombre, nivel, personas] ->

        with {:ok, [codigo, nombre, nivel, personas]} <-
               decodificar_campos([codigo, nombre, nivel, personas]),
             {cantidad, ""} <- Integer.parse(personas),
             {:ok, nivel_validado} <- Zonas.validar_nivel(nivel),
             :ok <- Zonas.validar_cantidad(cantidad),
             nil <- Zonas.buscar_zona(zonas, codigo) do

          nueva_zona = %Zona{
            codigo: codigo,
            nombre: nombre,
            nivel_afectacion: nivel_validado,
            personas_afectadas: cantidad,
            sectores: []
          }

          {:ok, zonas ++ [nueva_zona]}

        else
          _ ->
            {:error, "Registro de zona invalido o codigo duplicado."}
        end

      ["S", codigo_zona, codigo, nombre, nivel, personas] ->

        with {:ok, [codigo_zona, codigo, nombre, nivel, personas]} <-
               decodificar_campos([
                 codigo_zona,
                 codigo,
                 nombre,
                 nivel,
                 personas
               ]),
             {cantidad, ""} <- Integer.parse(personas),
             {:ok, nivel_validado} <- Zonas.validar_nivel(nivel),
             :ok <- Zonas.validar_cantidad(cantidad),
             nil <- Zonas.buscar_sector(zonas, codigo_zona, codigo),
             %Zona{} = zona <- Zonas.buscar_zona(zonas, codigo_zona) do

          nuevo_sector = %Sector{
            codigo: codigo,
            nombre: nombre,
            nivel_afectacion: nivel_validado,
            personas_afectadas: cantidad,
            puntos_atencion: []
          }

          zona_actualizada = %{
            zona |
            sectores: zona.sectores ++ [nuevo_sector]
          }

          nuevas_zonas =
            Enum.map(zonas, fn zona_actual ->
              if zona_actual.codigo == codigo_zona do
                zona_actualizada
              else
                zona_actual
              end
            end)

          {:ok, nuevas_zonas}

        else
          _ ->
            {:error, "Registro de sector invalido, duplicado o sin zona."}
        end

      ["P", codigo_zona, codigo_sector, codigo, nombre, ubicacion, tipo, estado] ->

        with {:ok, [
               codigo_zona,
               codigo_sector,
               codigo,
               nombre,
               ubicacion,
               tipo,
               estado
             ]} <-
               decodificar_campos([
                 codigo_zona,
                 codigo_sector,
                 codigo,
                 nombre,
                 ubicacion,
                 tipo,
                 estado
               ]),
             nil <- Zonas.buscar_punto(zonas, codigo_zona, codigo_sector, codigo),
             %Zona{} = zona <- Zonas.buscar_zona(zonas, codigo_zona),
             %Sector{} = sector <-
               Zonas.buscar_sector(zonas, codigo_zona, codigo_sector) do

          nuevo_punto = %PuntoAtencion{
            codigo: codigo,
            nombre: nombre,
            ubicacion: ubicacion,
            tipo: tipo,
            estado: estado
          }

          sector_actualizado = %{
            sector |
            puntos_atencion: sector.puntos_atencion ++ [nuevo_punto]
          }

          zona_actualizada = %{
            zona |
            sectores:
              Enum.map(zona.sectores, fn sector_actual ->
                if sector_actual.codigo == codigo_sector do
                  sector_actualizado
                else
                  sector_actual
                end
              end)
          }

          nuevas_zonas =
            Enum.map(zonas, fn zona_actual ->
              if zona_actual.codigo == codigo_zona do
                zona_actualizada
              else
                zona_actual
              end
            end)

          {:ok, nuevas_zonas}

        else
          _ ->
            {:error, "Registro de punto invalido, duplicado o sin sector."}
        end

      _ ->
        {:error, "Tipo de registro o cantidad de campos incorrectos."}

    end

  end

  # Decodifica todos los campos de una linea.
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

end
