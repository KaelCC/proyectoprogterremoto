defmodule Zonas do

  # Niveles de afectacion permitidos.
  @niveles ["critico", "alto", "medio", "bajo"]

  # --------------------------------------------------
  # VALIDACIONES GENERALES
  # --------------------------------------------------

  def texto_valido?(texto) do
    is_binary(texto) and String.trim(texto) != ""
  end

  def validar_nivel(nivel) do
    if is_binary(nivel) do
      nivel = String.downcase(String.trim(nivel))

      if nivel in @niveles do
        {:ok, nivel}
      else
        {:error, "Nivel de afectacion no valido."}
      end
    else
      {:error, "El nivel de afectacion debe ser texto."}
    end
  end

  def validar_cantidad(cantidad) do
    if is_integer(cantidad) and cantidad >= 0 do
      :ok
    else
      {:error, "La cantidad debe ser un entero no negativo."}
    end
  end

  # Comprueba si un codigo ya existe en cualquier nivel.
  def codigo_existe?(zonas, codigo) do
    Enum.any?(zonas, fn zona ->
      zona.codigo == codigo or
        Enum.any?(zona.sectores, fn sector ->
          sector.codigo == codigo or
            Enum.any?(sector.puntos_atencion, fn punto ->
              punto.codigo == codigo
            end)
        end)
    end)
  end

  # --------------------------------------------------
  # REGISTRAR ZONA
  # --------------------------------------------------

  def registrar_zona(zonas, codigo, nombre, nivel, personas) do

    with true <- texto_valido?(codigo),
         true <- texto_valido?(nombre),
         false <- codigo_existe?(zonas, codigo),
         {:ok, nivel_validado} <- validar_nivel(nivel),
         :ok <- validar_cantidad(personas) do

      nueva_zona = %Zona{
        codigo: String.trim(codigo),
        nombre: String.trim(nombre),
        nivel_afectacion: nivel_validado,
        personas_afectadas: personas,
        sectores: []
      }

      guardar_cambios([nueva_zona | zonas])

    else
      false ->
        {:error, "El codigo y el nombre son obligatorios."}

      true ->
        {:error, "El codigo ya esta registrado."}

      {:error, razon} ->
        {:error, razon}
    end

  end

  # --------------------------------------------------
  # BUSCAR ZONA
  # --------------------------------------------------

  def buscar_zona(zonas, codigo) do
    Enum.find(zonas, fn zona ->
      zona.codigo == codigo
    end)
  end

  # --------------------------------------------------
  # REGISTRAR SECTOR
  # --------------------------------------------------

  def registrar_sector(
        zonas,
        codigo_zona,
        codigo_sector,
        nombre,
        nivel,
        personas
      ) do

    with true <- texto_valido?(codigo_sector),
         true <- texto_valido?(nombre),
         false <- codigo_existe?(zonas, codigo_sector),
         {:ok, nivel_validado} <- validar_nivel(nivel),
         :ok <- validar_cantidad(personas),
         %Zona{} = zona <- buscar_zona(zonas, codigo_zona) do

      nuevo_sector = %Sector{
        codigo: String.trim(codigo_sector),
        nombre: String.trim(nombre),
        nivel_afectacion: nivel_validado,
        personas_afectadas: personas,
        puntos_atencion: []
      }

      zona_actualizada = %{
        zona |
        sectores: [nuevo_sector | zona.sectores]
      }

      nuevas_zonas =
        Enum.map(zonas, fn zona_actual ->
          if zona_actual.codigo == codigo_zona do
            zona_actualizada
          else
            zona_actual
          end
        end)

      guardar_cambios(nuevas_zonas)

    else
      false ->
        {:error, "El codigo y el nombre del sector son obligatorios."}

      true ->
        {:error, "El codigo ya esta registrado."}

      nil ->
        {:error, "La zona no existe."}

      {:error, razon} ->
        {:error, razon}
    end

  end

  # --------------------------------------------------
  # BUSCAR SECTOR
  # --------------------------------------------------

  def buscar_sector(zonas, codigo_zona, codigo_sector) do

    case buscar_zona(zonas, codigo_zona) do

      nil ->
        nil

      zona ->
        Enum.find(zona.sectores, fn sector ->
          sector.codigo == codigo_sector
        end)

    end

  end

  # --------------------------------------------------
  # REGISTRAR PUNTO DE ATENCION
  # --------------------------------------------------

  def registrar_punto(
        zonas,
        codigo_zona,
        codigo_sector,
        codigo_punto,
        nombre,
        ubicacion,
        tipo
      ) do

    with true <- texto_valido?(codigo_punto),
         true <- texto_valido?(nombre),
         true <- texto_valido?(ubicacion),
         true <- texto_valido?(tipo),
         false <- codigo_existe?(zonas, codigo_punto),
         %Zona{} = zona <- buscar_zona(zonas, codigo_zona),
         %Sector{} = sector <-
           buscar_sector(zonas, codigo_zona, codigo_sector) do

      nuevo_punto = %PuntoAtencion{
        codigo: String.trim(codigo_punto),
        nombre: String.trim(nombre),
        ubicacion: String.trim(ubicacion),
        tipo: String.trim(tipo),
        estado: "activo"
      }

      sector_actualizado = %{
        sector |
        puntos_atencion: [nuevo_punto | sector.puntos_atencion]
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

      guardar_cambios(nuevas_zonas)

    else
      false ->
        {:error, "Todos los datos del punto son obligatorios."}

      true ->
        {:error, "El codigo del punto ya esta registrado."}

      nil ->
        {:error, "No se encontro la zona o el sector indicado."}

      {:error, razon} ->
        {:error, razon}
    end

  end

  # --------------------------------------------------
  # BUSCAR PUNTO DE ATENCION
  # --------------------------------------------------

  def buscar_punto(zonas, codigo_zona, codigo_sector, codigo_punto) do

    case buscar_sector(zonas, codigo_zona, codigo_sector) do

      nil ->
        nil

      sector ->
        Enum.find(sector.puntos_atencion, fn punto ->
          punto.codigo == codigo_punto
        end)

    end

  end

  # --------------------------------------------------
  # LISTAR ZONAS
  # --------------------------------------------------

  def listar_zonas(zonas) do
    Enum.each(zonas, fn zona ->
      IO.inspect(zona)
    end)

    zonas
  end

  # --------------------------------------------------
  # LISTAR SECTORES
  # --------------------------------------------------

  def listar_sectores(zonas, codigo_zona) do

    case buscar_zona(zonas, codigo_zona) do

      nil ->
        {:error, "La zona no existe."}

      zona ->
        Enum.each(zona.sectores, fn sector ->
          IO.inspect(sector)
        end)

        {:ok, zona.sectores}

    end

  end

  # --------------------------------------------------
  # LISTAR PUNTOS DE ATENCION
  # --------------------------------------------------

  def listar_puntos(zonas, codigo_zona, codigo_sector) do

    case buscar_sector(zonas, codigo_zona, codigo_sector) do

      nil ->
        {:error, "El sector no existe."}

      sector ->
        Enum.each(sector.puntos_atencion, fn punto ->
          IO.inspect(punto)
        end)

        {:ok, sector.puntos_atencion}

    end

  end

  # --------------------------------------------------
  # ACTUALIZAR ZONA
  # --------------------------------------------------

  def actualizar_zona(zonas, codigo, nuevos_datos) do

    case buscar_zona(zonas, codigo) do

      nil ->
        {:error, "La zona no existe."}

      zona ->

        nivel =
          Map.get(nuevos_datos, :nivel_afectacion, zona.nivel_afectacion)

        personas =
          Map.get(nuevos_datos, :personas_afectadas, zona.personas_afectadas)

        nombre =
          Map.get(nuevos_datos, :nombre, zona.nombre)

        with true <- texto_valido?(nombre),
             {:ok, nivel_validado} <- validar_nivel(nivel),
             :ok <- validar_cantidad(personas) do

          zona_actualizada = %{
            zona |
            nombre: String.trim(nombre),
            nivel_afectacion: nivel_validado,
            personas_afectadas: personas
          }

          nuevas_zonas =
            Enum.map(zonas, fn zona_actual ->
              if zona_actual.codigo == codigo do
                zona_actualizada
              else
                zona_actual
              end
            end)

          guardar_cambios(nuevas_zonas)

        else
          false ->
            {:error, "El nombre no puede estar vacio."}

          {:error, razon} ->
            {:error, razon}
        end

    end

  end

  # --------------------------------------------------
  # OBTENER TODOS LOS PUNTOS DE UNA ZONA
  # FUNCION RECURSIVA
  # --------------------------------------------------

  def obtener_puntos(zona) do
    obtener_puntos(zona.sectores, [])
  end

  defp obtener_puntos([], acumulador) do
    Enum.reverse(acumulador)
  end

  defp obtener_puntos([sector | restantes], acumulador) do

    nuevos_puntos =
      Enum.reverse(sector.puntos_atencion) ++ acumulador

    obtener_puntos(restantes, nuevos_puntos)

  end

  # --------------------------------------------------
  # CONTAR SECTORES RECURSIVAMENTE
  # --------------------------------------------------

  def contar_sectores(zona) do
    contar_sectores(zona.sectores, 0)
  end

  defp contar_sectores([], total) do
    total
  end

  defp contar_sectores([_sector | restantes], total) do
    contar_sectores(restantes, total + 1)
  end

  # --------------------------------------------------
  # CONTAR PUNTOS RECURSIVAMENTE
  # --------------------------------------------------

  def contar_puntos(zona) do
    contar_puntos(zona.sectores, 0)
  end

  defp contar_puntos([], total) do
    total
  end

  defp contar_puntos([sector | restantes], total) do

    total_puntos = length(sector.puntos_atencion)

    contar_puntos(restantes, total + total_puntos)

  end

  # --------------------------------------------------
  # ESTADISTICAS
  # --------------------------------------------------

  def estadisticas(zonas) do

    %{
      total_zonas: length(zonas),

      total_sectores:
        Enum.reduce(zonas, 0, fn zona, total ->
          total + contar_sectores(zona)
        end),

      total_puntos:
        Enum.reduce(zonas, 0, fn zona, total ->
          total + contar_puntos(zona)
        end),

      personas_afectadas:
        Enum.reduce(zonas, 0, fn zona, total ->
          total + zona.personas_afectadas
        end),

      zonas_criticas:
        Enum.filter(zonas, fn zona ->
          zona.nivel_afectacion == "critico"
        end)
    }

  end

    # --------------------------------------------------
  # GUARDAR CAMBIOS AUTOMATICAMENTE
  # --------------------------------------------------

  defp guardar_cambios(nuevas_zonas) do

    case PersistenciaZonas.guardar(nuevas_zonas) do

      {:ok, _mensaje} ->
        {:ok, nuevas_zonas}

      {:error, razon} ->
        {:error, razon}

    end

  end

end
