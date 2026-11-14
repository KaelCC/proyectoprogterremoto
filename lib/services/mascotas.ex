defmodule Mascotas do
  @tipos ["perdida", "encontrada"]
  @estados ["activa", "posible coincidencia", "resuelta"]

  # --------------------------------------------------
  # VALIDACIONES
  # --------------------------------------------------

  def texto_valido?(texto) when is_binary(texto) do
    String.trim(texto) != ""
  end

  def texto_valido?(_), do: false

  def validar_tipo(tipo) when tipo in @tipos, do: :ok

  def validar_tipo(_tipo) do
    {:error, "El tipo de reporte debe ser perdida o encontrada."}
  end

  def validar_estado(estado) when estado in @estados, do: :ok

  def validar_estado(_estado) do
    {:error, "El estado debe ser activa, posible coincidencia o resuelta."}
  end

  # --------------------------------------------------
  # BUSCAR Y VALIDAR CÓDIGOS
  # --------------------------------------------------

  def codigo_existe?(mascotas, codigo) do
    Enum.any?(mascotas, fn mascota ->
      mascota.codigo == codigo
    end)
  end

  def buscar_mascota(mascotas, codigo) do
    Enum.find(mascotas, fn mascota ->
      mascota.codigo == codigo
    end)
  end

  # --------------------------------------------------
  # REGISTRAR REPORTE
  # --------------------------------------------------

  def registrar_mascota(
        mascotas,
        codigo,
        tipo_reporte,
        especie,
        nombre,
        caracteristicas,
        color,
        tamano,
        zona,
        contacto
      ) do

    campos = [codigo, especie, caracteristicas, color, tamano, zona, contacto]

    with :ok <- validar_tipo(tipo_reporte),
         true <- Enum.all?(campos, &texto_valido?/1),
         false <- codigo_existe?(mascotas, String.trim(codigo)) do

      nombre =
        if texto_valido?(nombre) do
          String.trim(nombre)
        else
          "desconocido"
        end

      nueva_mascota = %Mascota{
        codigo: String.trim(codigo),
        tipo_reporte: String.trim(tipo_reporte),
        especie: String.trim(especie),
        nombre: nombre,
        caracteristicas: String.trim(caracteristicas),
        color: String.trim(color),
        tamano: String.trim(tamano),
        zona: String.trim(zona),
        contacto: String.trim(contacto),
        estado: "activa",
        coincidencia: nil
      }

      nuevas_mascotas = mascotas ++ [nueva_mascota]

      case guardar_cambios(nuevas_mascotas) do
        :ok ->
          {:ok, nuevas_mascotas}

        {:error, razon} ->
          {:error, razon}
      end
    else
      true ->
        {:error, "Ya existe un reporte con ese código."}

      false ->
        {:error, "Todos los campos obligatorios deben estar completos."}

      {:error, razon} ->
        {:error, razon}
    end
  end

  # --------------------------------------------------
  # LISTAR REPORTES
  # --------------------------------------------------

  def listar_mascotas(mascotas) do
    mascotas
  end

  # --------------------------------------------------
  # FILTRAR POR ESPECIE
  # --------------------------------------------------

  def filtrar_por_especie(mascotas, especie) do
    Enum.filter(mascotas, fn mascota ->
      normalizar(mascota.especie) == normalizar(especie)
    end)
  end

  # --------------------------------------------------
  # FILTRAR POR ZONA
  # --------------------------------------------------

  def filtrar_por_zona(mascotas, zona) do
    Enum.filter(mascotas, fn mascota ->
      normalizar(mascota.zona) == normalizar(zona)
    end)
  end

  # --------------------------------------------------
  # FILTRAR POR ESTADO
  # --------------------------------------------------

  def filtrar_por_estado(mascotas, estado) do
    Enum.filter(mascotas, fn mascota ->
      mascota.estado == estado
    end)
  end

  # --------------------------------------------------
  # FILTRAR POR TIPO DE REPORTE
  # --------------------------------------------------

  def filtrar_por_tipo(mascotas, tipo) do
    Enum.filter(mascotas, fn mascota ->
      mascota.tipo_reporte == tipo
    end)
  end

  # --------------------------------------------------
  # ACTUALIZAR ESTADO
  # --------------------------------------------------

  def actualizar_estado(mascotas, codigo, nuevo_estado) do
    with :ok <- validar_estado(nuevo_estado),
         mascota when not is_nil(mascota) <- buscar_mascota(mascotas, codigo),
         true <- mascota.estado == "activa" and nuevo_estado == "posible coincidencia" or
                   mascota.estado == "posible coincidencia" and nuevo_estado == "activa" do

      mascotas_actualizadas =
        Enum.map(mascotas, fn actual ->
          if actual.codigo == codigo do
            %{actual | estado: nuevo_estado}
          else
            actual
          end
        end)

      case guardar_cambios(mascotas_actualizadas) do
        :ok ->
          {:ok, mascotas_actualizadas}

        {:error, razon} ->
          {:error, razon}
      end
    else
      nil ->
        {:error, "No se encontró el reporte de mascota."}

      false ->
        {:error, "La transición de estado no está permitida."}

      {:error, razon} ->
        {:error, razon}
    end
  end

  # --------------------------------------------------
  # BUSCAR POSIBLES COINCIDENCIAS
  # --------------------------------------------------

  def buscar_coincidencias(mascotas) do
    perdidas =
      Enum.filter(mascotas, fn mascota ->
        mascota.tipo_reporte == "perdida" and
          mascota.estado in ["activa", "posible coincidencia"]
      end)

    encontradas =
      Enum.filter(mascotas, fn mascota ->
        mascota.tipo_reporte == "encontrada" and
          mascota.estado in ["activa", "posible coincidencia"]
      end)

    for perdida <- perdidas,
        encontrada <- encontradas,
        puntaje = puntaje_similitud(perdida, encontrada),
        puntaje >= 60 do
      %{
        perdida: perdida,
        encontrada: encontrada,
        puntaje: puntaje
      }
    end
  end

  # --------------------------------------------------
  # CALCULAR PUNTAJE DE SIMILITUD
  # --------------------------------------------------

  def puntaje_similitud(perdida, encontrada) do
    puntaje_especie =
      if coinciden?(perdida.especie, encontrada.especie), do: 35, else: 0

    puntaje_color =
      if coinciden?(perdida.color, encontrada.color), do: 20, else: 0

    puntaje_tamano =
      if coinciden?(perdida.tamano, encontrada.tamano), do: 15, else: 0

    puntaje_zona =
      if coinciden?(perdida.zona, encontrada.zona), do: 15, else: 0

    puntaje_nombre =
      if coinciden?(perdida.nombre, encontrada.nombre) and
           normalizar(perdida.nombre) != "desconocido" do
        10
      else
        0
      end

    puntaje_caracteristicas =
      if coinciden?(perdida.caracteristicas, encontrada.caracteristicas),
        do: 5,
        else: 0

    puntaje_especie +
      puntaje_color +
      puntaje_tamano +
      puntaje_zona +
      puntaje_nombre +
      puntaje_caracteristicas
  end

  # --------------------------------------------------
  # CONFIRMAR COINCIDENCIA
  # --------------------------------------------------

  def confirmar_coincidencia(mascotas, codigo_perdida, codigo_encontrada) do
    perdida = buscar_mascota(mascotas, codigo_perdida)
    encontrada = buscar_mascota(mascotas, codigo_encontrada)

    with %Mascota{} <- perdida,
         %Mascota{} <- encontrada,
         true <- perdida.tipo_reporte == "perdida",
         true <- encontrada.tipo_reporte == "encontrada",
         true <- perdida.estado in ["activa", "posible coincidencia"],
         true <- encontrada.estado in ["activa", "posible coincidencia"] do

      mascotas_actualizadas =
        Enum.map(mascotas, fn mascota ->
          cond do
            mascota.codigo == codigo_perdida ->
              %{mascota |
                estado: "resuelta",
                coincidencia: codigo_encontrada
              }

            mascota.codigo == codigo_encontrada ->
              %{mascota |
                estado: "resuelta",
                coincidencia: codigo_perdida
              }

            true ->
              mascota
          end
        end)

      case guardar_cambios(mascotas_actualizadas) do
        :ok ->
          {:ok, mascotas_actualizadas}

        {:error, razon} ->
          {:error, razon}
      end
    else
      nil ->
        {:error, "No se encontraron los dos reportes."}

      false ->
        {:error, "Los reportes no corresponden a una pareja válida o ya fueron resueltos."}

      _ ->
        {:error, "No se pudo confirmar la coincidencia."}
    end
  end

  # --------------------------------------------------
  # COMPARAR TEXTOS
  # --------------------------------------------------

  defp coinciden?(texto1, texto2) do
    normalizar(texto1) == normalizar(texto2)
  end

  defp normalizar(texto) do
    texto
    |> String.trim()
    |> String.downcase()
  end

  # --------------------------------------------------
  # GUARDAR CAMBIOS
  # --------------------------------------------------

  defp guardar_cambios(mascotas) do
    case PersistenciaMascotas.guardar(mascotas) do
      {:ok, _mensaje} ->
        :ok

      {:error, razon} ->
        {:error, razon}
    end
  end
end
