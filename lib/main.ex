
defmodule Proyectoprog.Main do

  # --------------------------------------------------
  # INICIO DEL PROGRAMA
  # --------------------------------------------------

  def main do
    IO.puts("\n======================================")
    IO.puts(" SISTEMA DE GESTION POST TERREMOTO")
    IO.puts("======================================")

    cargar_datos()
  end

  # --------------------------------------------------
  # CARGAR TODOS LOS DATOS
  # --------------------------------------------------

  def cargar_datos do

    with {:ok, usuarios} <- Usuarios.cargar_usuarios(),
         {:ok, zonas} <- PersistenciaZonas.cargar(),
         {:ok, necesidades} <- PersistenciaNecesidades.cargar(),
         {:ok, recursos} <- PersistenciaRecursos.cargar(),
         {:ok, albergues} <- PersistenciaAlbergues.cargar(),
         {:ok, personas} <- PersistenciaPersonas.cargar() do

      IO.puts("\nDatos cargados correctamente.")
      IO.puts("Usuarios: #{length(usuarios)}")
      IO.puts("Zonas: #{length(zonas)}")
      IO.puts("Necesidades: #{length(necesidades)}")
      IO.puts("Recursos: #{length(recursos)}")
      IO.puts("Albergues: #{length(albergues)}")
      IO.puts("Personas: #{length(personas)}")

      menu(usuarios, zonas, necesidades, recursos, albergues, personas)

    else
      {:error, razon} ->
        IO.puts("\nError al cargar los datos: #{inspect(razon)}")
    end
  end

  # --------------------------------------------------
  # MENU PRINCIPAL
  # --------------------------------------------------

  def menu(usuarios, zonas, necesidades, recursos, albergues, personas) do

    IO.puts("\n======================================")
    IO.puts("              MENU PRINCIPAL")
    IO.puts("======================================")
    IO.puts("1. Listar usuarios")
    IO.puts("2. Listar zonas")
    IO.puts("3. Listar necesidades")
    IO.puts("4. Listar recursos")
    IO.puts("5. Listar albergues")
    IO.puts("6. Listar personas")
    IO.puts("7. Registrar zona")
    IO.puts("8. Registrar recurso")
    IO.puts("9. Registrar albergue")
    IO.puts("10. Registrar persona")
    IO.puts("11. Consultar cupos de un albergue")
    IO.puts("12. Alojar persona")
    IO.puts("13. Retirar persona de un albergue")
    IO.puts("14. Asignar recurso a una necesidad")
    IO.puts("0. Salir")
    IO.puts("======================================")

    opcion = leer_texto("Seleccione una opcion: ")

    case opcion do

      "1" ->
        IO.puts("\n--- USUARIOS ---")
        Enum.each(usuarios, &IO.inspect/1)
        menu(usuarios, zonas, necesidades, recursos, albergues, personas)

      "2" ->
        IO.puts("\n--- ZONAS ---")
        Enum.each(zonas, &IO.inspect/1)
        menu(usuarios, zonas, necesidades, recursos, albergues, personas)

      "3" ->
        IO.puts("\n--- NECESIDADES ---")
        Enum.each(necesidades, &IO.inspect/1)
        menu(usuarios, zonas, necesidades, recursos, albergues, personas)

      "4" ->
        IO.puts("\n--- RECURSOS ---")
        Enum.each(recursos, &IO.inspect/1)
        menu(usuarios, zonas, necesidades, recursos, albergues, personas)

      "5" ->
        listar_albergues(albergues)
        menu(usuarios, zonas, necesidades, recursos, albergues, personas)

      "6" ->
        IO.puts("\n--- PERSONAS ---")
        Enum.each(personas, &IO.inspect/1)
        menu(usuarios, zonas, necesidades, recursos, albergues, personas)

      "7" ->
        nuevas_zonas = registrar_zona(zonas)
        menu(usuarios, nuevas_zonas, necesidades, recursos, albergues, personas)

      "8" ->
        nuevos_recursos = registrar_recurso(recursos)
        menu(usuarios, zonas, necesidades, nuevos_recursos, albergues, personas)

      "9" ->
        nuevos_albergues = registrar_albergue(albergues)
        menu(usuarios, zonas, necesidades, recursos, nuevos_albergues, personas)

      "10" ->
        nuevas_personas = registrar_persona(personas)
        menu(usuarios, zonas, necesidades, recursos, albergues, nuevas_personas)

      "11" ->
        consultar_cupos(albergues)
        menu(usuarios, zonas, necesidades, recursos, albergues, personas)

      "12" ->
        case alojar_persona(albergues, personas) do
          {:ok, nuevos_albergues, nuevas_personas} ->
            menu(usuarios, zonas, necesidades, recursos, nuevos_albergues, nuevas_personas)

          {:error, razon} ->
            IO.puts("\nError: #{razon}")
            menu(usuarios, zonas, necesidades, recursos, albergues, personas)
        end

      "13" ->
        case retirar_persona(albergues, personas) do
          {:ok, nuevos_albergues, nuevas_personas} ->
            menu(usuarios, zonas, necesidades, recursos, nuevos_albergues, nuevas_personas)

          {:error, razon} ->
            IO.puts("\nError: #{razon}")
            menu(usuarios, zonas, necesidades, recursos, albergues, personas)
        end

      "14" ->
        case asignar_recurso(recursos, necesidades) do
          {:ok, nuevos_recursos, nuevas_necesidades} ->
            menu(usuarios, zonas, nuevas_necesidades, nuevos_recursos, albergues, personas)

          {:error, razon} ->
            IO.puts("\nError: #{razon}")
            menu(usuarios, zonas, necesidades, recursos, albergues, personas)
        end

      "0" ->
        IO.puts("\nGracias por utilizar el sistema.")

      _ ->
        IO.puts("\nOpcion no valida.")
        menu(usuarios, zonas, necesidades, recursos, albergues, personas)

    end
  end

  # --------------------------------------------------
  # LISTAR ALBERGUES
  # --------------------------------------------------

  defp listar_albergues(albergues) do

    IO.puts("\n--- ALBERGUES ---")

    Enum.each(albergues, fn albergue ->

      {:ok, cupos} = Albergues.cupos_disponibles(albergues, albergue.codigo)

      IO.puts("\nCodigo: #{albergue.codigo}")
      IO.puts("Nombre: #{albergue.nombre}")
      IO.puts("Zona: #{albergue.zona}")
      IO.puts("Capacidad: #{albergue.capacidad_maxima}")
      IO.puts("Ocupacion: #{Albergues.ocupacion(albergue)}")
      IO.puts("Cupos disponibles: #{cupos}")
      IO.puts("Personas: #{inspect(albergue.personas)}")

    end)
  end

  # --------------------------------------------------
  # REGISTRAR ZONA
  # --------------------------------------------------

  defp registrar_zona(zonas) do

    IO.puts("\n--- REGISTRAR ZONA ---")

    codigo = leer_texto("Codigo: ")
    nombre = leer_texto("Nombre: ")
    nivel = leer_texto("Nivel de afectacion: ")
    cantidad = leer_entero("Personas afectadas: ")

    case Zonas.registrar_zona(zonas, codigo, nombre, nivel, cantidad) do

      {:ok, nuevas_zonas} ->
        IO.puts("\nZona registrada correctamente.")
        nuevas_zonas

      {:error, razon} ->
        IO.puts("\nError: #{razon}")
        zonas

    end
  end

  # --------------------------------------------------
  # REGISTRAR RECURSO
  # --------------------------------------------------

  defp registrar_recurso(recursos) do

    IO.puts("\n--- REGISTRAR RECURSO ---")

    codigo = leer_texto("Codigo: ")
    nombre = leer_texto("Nombre: ")
    categoria = leer_texto("Categoria: ")
    cantidad = leer_entero("Cantidad: ")
    unidad = leer_texto("Unidad: ")
    ubicacion = leer_texto("Ubicacion: ")

    case Recursos.registrar_recurso(
           recursos,
           codigo,
           nombre,
           categoria,
           cantidad,
           unidad,
           ubicacion
         ) do

      {:ok, nuevos_recursos} ->
        IO.puts("\nRecurso registrado correctamente.")
        nuevos_recursos

      {:error, razon} ->
        IO.puts("\nError: #{razon}")
        recursos

    end
  end

  # --------------------------------------------------
  # REGISTRAR ALBERGUE
  # --------------------------------------------------

  defp registrar_albergue(albergues) do

    IO.puts("\n--- REGISTRAR ALBERGUE ---")

    codigo = leer_texto("Codigo: ")
    nombre = leer_texto("Nombre: ")
    zona = leer_texto("Codigo de la zona: ")
    capacidad = leer_entero("Capacidad maxima: ")

    case Albergues.registrar_albergue(
           albergues,
           codigo,
           nombre,
           zona,
           capacidad
         ) do

      {:ok, nuevos_albergues} ->
        IO.puts("\nAlbergue registrado correctamente.")
        nuevos_albergues

      {:error, razon} ->
        IO.puts("\nError: #{razon}")
        albergues

    end
  end

  # --------------------------------------------------
  # REGISTRAR PERSONA
  # --------------------------------------------------

  defp registrar_persona(personas) do

    IO.puts("\n--- REGISTRAR PERSONA ---")

    codigo = leer_texto("Codigo: ")
    nombre = leer_texto("Nombre completo: ")
    edad = leer_entero("Edad: ")
    zona = leer_texto("Codigo de la zona: ")

    case Personas.registrar_persona(
           personas,
           codigo,
           nombre,
           edad,
           zona
         ) do

      {:ok, nuevas_personas} ->
        IO.puts("\nPersona registrada correctamente.")
        nuevas_personas

      {:error, razon} ->
        IO.puts("\nError: #{razon}")
        personas

    end
  end

  # --------------------------------------------------
  # CONSULTAR CUPOS
  # --------------------------------------------------

  defp consultar_cupos(albergues) do

    IO.puts("\n--- CONSULTAR CUPOS ---")

    codigo = leer_texto("Codigo del albergue: ")

    case Albergues.cupos_disponibles(albergues, codigo) do

      {:ok, cupos} ->
        IO.puts("Cupos disponibles: #{cupos}")

      {:error, razon} ->
        IO.puts("Error: #{razon}")

    end
  end

  # --------------------------------------------------
  # ALOJAR PERSONA
  # --------------------------------------------------

  defp alojar_persona(albergues, personas) do

    IO.puts("\n--- ALOJAR PERSONA ---")

    codigo_albergue = leer_texto("Codigo del albergue: ")
    codigo_persona = leer_texto("Codigo de la persona: ")

    case Albergues.alojar_persona(
           albergues,
           personas,
           codigo_albergue,
           codigo_persona
         ) do

      {:ok, nuevos_albergues, nuevas_personas} ->
        IO.puts("\nPersona alojada correctamente.")
        {:ok, nuevos_albergues, nuevas_personas}

      {:error, razon} ->
        {:error, razon}

    end
  end

  # --------------------------------------------------
  # RETIRAR PERSONA
  # --------------------------------------------------

  defp retirar_persona(albergues, personas) do

    IO.puts("\n--- RETIRAR PERSONA ---")

    codigo_albergue = leer_texto("Codigo del albergue: ")
    codigo_persona = leer_texto("Codigo de la persona: ")

    case Albergues.retirar_persona(
           albergues,
           personas,
           codigo_albergue,
           codigo_persona
         ) do

      {:ok, nuevos_albergues, nuevas_personas} ->
        IO.puts("\nPersona retirada correctamente.")
        {:ok, nuevos_albergues, nuevas_personas}

      {:error, razon} ->
        {:error, razon}

    end
  end

  # --------------------------------------------------
  # ASIGNAR RECURSO A NECESIDAD
  # --------------------------------------------------

  defp asignar_recurso(recursos, necesidades) do

    IO.puts("\n--- ASIGNAR RECURSO ---")

    codigo_recurso = leer_texto("Codigo del recurso: ")
    id_necesidad = leer_texto("ID de la necesidad: ")
    cantidad = leer_entero("Cantidad a asignar: ")

    case Recursos.asignar_recurso(
           recursos,
           necesidades,
           codigo_recurso,
           id_necesidad,
           cantidad
         ) do

      {:ok, nuevos_recursos, nuevas_necesidades} ->
        IO.puts("\nRecurso asignado correctamente.")
        {:ok, nuevos_recursos, nuevas_necesidades}

      {:error, razon} ->
        {:error, razon}

    end
  end

  # --------------------------------------------------
  # LEER TEXTO
  # --------------------------------------------------

  defp leer_texto(mensaje) do

    case IO.gets(mensaje) do
      nil -> ""
      texto -> String.trim(texto)
    end
  end

  # --------------------------------------------------
  # LEER ENTERO
  # --------------------------------------------------

  defp leer_entero(mensaje) do

    texto = leer_texto(mensaje)

    case Integer.parse(texto) do
      {numero, ""} -> numero
      _ -> nil
    end
  end

end
