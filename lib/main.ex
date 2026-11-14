

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
  # CARGAR DATOS
  # --------------------------------------------------

  def cargar_datos do
    with {:ok, usuarios} <- Usuarios.cargar_usuarios(),
         {:ok, zonas} <- PersistenciaZonas.cargar(),
         {:ok, necesidades} <- PersistenciaNecesidades.cargar(),
         {:ok, recursos} <- PersistenciaRecursos.cargar(),
         {:ok, albergues} <- PersistenciaAlbergues.cargar(),
         {:ok, personas} <- PersistenciaPersonas.cargar(),
         {:ok, mensajes} <- PersistenciaMensajes.cargar(),
         {:ok, mascotas} <- PersistenciaMascotas.cargar(),
         {:ok, _pid} <- InventarioServer.iniciar() do

      IO.puts("\nDatos cargados correctamente.")

      IO.puts("Usuarios: #{length(usuarios)}")
      IO.puts("Zonas: #{length(zonas)}")
      IO.puts("Necesidades: #{length(necesidades)}")
      IO.puts("Recursos: #{length(recursos)}")
      IO.puts("Albergues: #{length(albergues)}")
      IO.puts("Personas: #{length(personas)}")
      IO.puts("Mensajes: #{length(mensajes)}")
      IO.puts("Mascotas: #{length(mascotas)}")

      autenticacion(
        usuarios,
        zonas,
        necesidades,
        recursos,
        albergues,
        personas,
        mensajes,
        mascotas
      )

    else
      {:error, razon} ->
        IO.puts("\nError al cargar los datos: #{inspect(razon)}")
    end
  end

  # --------------------------------------------------
  # INICIO DE SESION Y REGISTRO
  # --------------------------------------------------

  defp autenticacion(
         usuarios,
         zonas,
         necesidades,
         recursos,
         albergues,
         personas,
         mensajes,
         mascotas
       ) do

    IO.puts("\n======================================")
    IO.puts("       ACCESO AL SISTEMA")
    IO.puts("======================================")
    IO.puts("1. Iniciar sesion")
    IO.puts("2. Registrarse")
    IO.puts("0. Salir")

    opcion = leer_texto("Seleccione una opcion: ")

    case opcion do

      "1" ->
        iniciar_sesion(
          usuarios,
          zonas,
          necesidades,
          recursos,
          albergues,
          personas,
          mensajes,
          mascotas
        )

      "2" ->
        registrar_cuenta(
          usuarios,
          zonas,
          necesidades,
          recursos,
          albergues,
          personas,
          mensajes,
          mascotas
        )

      "0" ->
        IO.puts("\nGracias por utilizar el sistema.")

      _ ->
        IO.puts("\nOpcion no valida.")

        autenticacion(
          usuarios,
          zonas,
          necesidades,
          recursos,
          albergues,
          personas,
          mensajes,
          mascotas
        )
    end
  end

  # --------------------------------------------------
  # INICIAR SESION
  # --------------------------------------------------

  defp iniciar_sesion(
         usuarios,
         zonas,
         necesidades,
         recursos,
         albergues,
         personas,
         mensajes,
         mascotas
       ) do

    IO.puts("\n--- INICIO DE SESION ---")

    usuario = leer_texto("Nombre de usuario: ")
    contraseña = leer_texto("Contraseña: ")

    case Usuarios.validar(usuarios, usuario, contraseña) do

      {:ok, usuario_actual} ->

        IO.puts("\nBienvenido, #{usuario_actual.nombre}.")
        IO.puts("Rol: #{String.upcase(usuario_actual.categoria)}")

        menu(
          usuarios,
          zonas,
          necesidades,
          recursos,
          albergues,
          personas,
          mensajes,
          mascotas,
          usuario_actual
        )

      {:error, razon} ->

        IO.puts("\nError: #{razon}")

        autenticacion(
          usuarios,
          zonas,
          necesidades,
          recursos,
          albergues,
          personas,
          mensajes,
          mascotas
        )
    end
  end

  # --------------------------------------------------
  # REGISTRAR CUENTA
  # --------------------------------------------------

  defp registrar_cuenta(
         usuarios,
         zonas,
         necesidades,
         recursos,
         albergues,
         personas,
         mensajes,
         mascotas
       ) do

    IO.puts("\n--- REGISTRO DE USUARIO ---")

    nombre_usuario = leer_texto("Nombre de usuario: ")
    contraseña = leer_texto("Contraseña: ")

    case Usuarios.registrar_usuario(
           usuarios,
           nombre_usuario,
           contraseña
         ) do

      {:ok, _nuevo_usuario, nuevos_usuarios} ->

        IO.puts("\nRegistro completado correctamente.")
        IO.puts("Ahora puedes iniciar sesion.")

        autenticacion(
          nuevos_usuarios,
          zonas,
          necesidades,
          recursos,
          albergues,
          personas,
          mensajes,
          mascotas
        )

      {:error, razon} ->

        IO.puts("\nError durante el registro: #{razon}")

        autenticacion(
          usuarios,
          zonas,
          necesidades,
          recursos,
          albergues,
          personas,
          mensajes,
          mascotas
        )
    end
  end

  # --------------------------------------------------
  # PERMISOS POR ROL
  # --------------------------------------------------

  defp opciones_por_rol("administrador") do
    Enum.map(1..25, &Integer.to_string/1)
  end

  defp opciones_por_rol("coordinador") do
    Enum.map(
      [2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14,
       15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25],
      &Integer.to_string/1
    )
  end

  defp opciones_por_rol("voluntario") do
    Enum.map(
      [2, 3, 4, 5, 6, 10, 11, 12, 13, 14,
       15, 16, 21, 22, 23, 24],
      &Integer.to_string/1
    )
  end

  defp opciones_por_rol("ciudadano") do
    Enum.map([10, 15, 21], &Integer.to_string/1)
  end

  defp opciones_por_rol(_), do: []

  # --------------------------------------------------
  # MENU PRINCIPAL
  # --------------------------------------------------

  def menu(
        usuarios,
        zonas,
        necesidades,
        recursos,
        albergues,
        personas,
        mensajes,
        mascotas,
        usuario_actual
      ) do

    rol = usuario_actual.categoria
    permitidas = opciones_por_rol(rol)

    IO.puts("\n======================================")
    IO.puts("              MENU PRINCIPAL")
    IO.puts("======================================")
    IO.puts("Usuario: #{usuario_actual.nombre}")
    IO.puts("Rol: #{String.upcase(rol)}")
    IO.puts("--------------------------------------")

    opciones = [
      {"1", "Listar usuarios"},
      {"2", "Listar zonas"},
      {"3", "Listar necesidades"},
      {"4", "Listar recursos"},
      {"5", "Listar albergues"},
      {"6", "Listar personas"},
      {"7", "Registrar zona"},
      {"8", "Registrar recurso"},
      {"9", "Registrar albergue"},
      {"10", "Registrar persona"},
      {"11", "Consultar cupos de un albergue"},
      {"12", "Alojar persona"},
      {"13", "Retirar persona de un albergue"},
      {"14", "Asignar recurso a una necesidad"},
      {"15", "Registrar mensaje familiar"},
      {"16", "Listar mensajes"},
      {"17", "Buscar mensajes por destinatario"},
      {"18", "Buscar mensajes por remitente"},
      {"19", "Consultar mensajes pendientes"},
      {"20", "Marcar mensaje como entregado"},
      {"21", "Registrar reporte de mascota"},
      {"22", "Listar reportes de mascotas"},
      {"23", "Filtrar reportes de mascotas"},
      {"24", "Buscar coincidencias de mascotas"},
      {"25", "Confirmar coincidencia de mascotas"}
    ]

    Enum.each(opciones, fn {numero, descripcion} ->
      if numero in permitidas do
        IO.puts("#{numero}. #{descripcion}")
      end
    end)

    IO.puts("\n99. Cerrar sesion")
    IO.puts("0. Salir del programa")
    IO.puts("======================================")

    opcion = leer_texto("Seleccione una opcion: ")

    cond do

      opcion == "0" ->
        IO.puts("\nGracias por utilizar el sistema.")

      opcion == "99" ->
        IO.puts("\nSesion cerrada correctamente.")

        autenticacion(
          usuarios,
          zonas,
          necesidades,
          recursos,
          albergues,
          personas,
          mensajes,
          mascotas
        )

      opcion not in permitidas ->
        IO.puts("\nNo tienes permisos para realizar esta operacion.")

        menu(
          usuarios,
          zonas,
          necesidades,
          recursos,
          albergues,
          personas,
          mensajes,
          mascotas,
          usuario_actual
        )

      true ->
        ejecutar_opcion(
          opcion,
          usuarios,
          zonas,
          necesidades,
          recursos,
          albergues,
          personas,
          mensajes,
          mascotas,
          usuario_actual
        )
    end
  end

  # --------------------------------------------------
  # EJECUTAR OPCIONES
  # --------------------------------------------------

  defp ejecutar_opcion(
         opcion,
         usuarios,
         zonas,
         necesidades,
         recursos,
         albergues,
         personas,
         mensajes,
         mascotas,
         usuario_actual
       ) do

    estado =
      if opcion in ["3", "4", "14"] do
        InventarioServer.consultar_estado()
      else
        %{recursos: recursos, necesidades: necesidades}
      end

    recursos = estado.recursos
    necesidades = estado.necesidades

    {usuarios, zonas, necesidades, recursos, albergues,
     personas, mensajes, mascotas} =

      case opcion do

        "1" ->
          IO.puts("\n--- USUARIOS ---")
          Enum.each(usuarios, &IO.inspect/1)
          {usuarios, zonas, necesidades, recursos, albergues,
           personas, mensajes, mascotas}

        "2" ->
          IO.puts("\n--- ZONAS ---")
          Enum.each(zonas, &IO.inspect/1)
          {usuarios, zonas, necesidades, recursos, albergues,
           personas, mensajes, mascotas}

        "3" ->
          IO.puts("\n--- NECESIDADES ---")
          Enum.each(necesidades, &IO.inspect/1)
          {usuarios, zonas, necesidades, recursos, albergues,
           personas, mensajes, mascotas}

        "4" ->
          IO.puts("\n--- RECURSOS ---")
          Enum.each(recursos, &IO.inspect/1)
          {usuarios, zonas, necesidades, recursos, albergues,
           personas, mensajes, mascotas}

        "5" ->
          listar_albergues(albergues)
          {usuarios, zonas, necesidades, recursos, albergues,
           personas, mensajes, mascotas}

        "6" ->
          IO.puts("\n--- PERSONAS ---")
          Enum.each(personas, &IO.inspect/1)
          {usuarios, zonas, necesidades, recursos, albergues,
           personas, mensajes, mascotas}

        "7" ->
          nuevas_zonas = registrar_zona(zonas)
          {usuarios, nuevas_zonas, necesidades, recursos, albergues,
           personas, mensajes, mascotas}

        "8" ->
          case registrar_recurso(recursos) do
            {:ok, _} ->
              case InventarioServer.recargar() do
                {:ok, nuevo_estado} ->
                  {usuarios, zonas, nuevo_estado.necesidades,
                   nuevo_estado.recursos, albergues, personas,
                   mensajes, mascotas}

                {:error, razon} ->
                  IO.puts("Error al actualizar inventario: #{razon}")
                  {usuarios, zonas, necesidades, recursos, albergues,
                   personas, mensajes, mascotas}
              end

            {:error, razon} ->
              IO.puts("Error: #{razon}")
              {usuarios, zonas, necesidades, recursos, albergues,
               personas, mensajes, mascotas}
          end

        "9" ->
          nuevos = registrar_albergue(albergues)
          {usuarios, zonas, necesidades, recursos, nuevos,
           personas, mensajes, mascotas}

        "10" ->
          nuevas = registrar_persona(personas)
          {usuarios, zonas, necesidades, recursos, albergues,
           nuevas, mensajes, mascotas}

        "11" ->
          consultar_cupos(albergues)
          {usuarios, zonas, necesidades, recursos, albergues,
           personas, mensajes, mascotas}

        "12" ->
          case alojar_persona(albergues, personas) do
            {:ok, nuevos_albergues, nuevas_personas} ->
              {usuarios, zonas, necesidades, recursos,
               nuevos_albergues, nuevas_personas, mensajes, mascotas}

            {:error, razon} ->
              IO.puts("Error: #{razon}")
              {usuarios, zonas, necesidades, recursos, albergues,
               personas, mensajes, mascotas}
          end

        "13" ->
          case retirar_persona(albergues, personas) do
            {:ok, nuevos_albergues, nuevas_personas} ->
              {usuarios, zonas, necesidades, recursos,
               nuevos_albergues, nuevas_personas, mensajes, mascotas}

            {:error, razon} ->
              IO.puts("Error: #{razon}")
              {usuarios, zonas, necesidades, recursos, albergues,
               personas, mensajes, mascotas}
          end

        "14" ->
          case asignar_recurso() do
            {:ok, nuevos_recursos, nuevas_necesidades} ->
              IO.puts("Recurso asignado correctamente.")
              {usuarios, zonas, nuevas_necesidades, nuevos_recursos,
               albergues, personas, mensajes, mascotas}

            {:error, razon} ->
              IO.puts("Error: #{razon}")
              {usuarios, zonas, necesidades, recursos, albergues,
               personas, mensajes, mascotas}
          end

        "15" ->
          nuevos = registrar_mensaje(mensajes)
          {usuarios, zonas, necesidades, recursos, albergues,
           personas, nuevos, mascotas}

        "16" ->
          listar_mensajes(mensajes)
          {usuarios, zonas, necesidades, recursos, albergues,
           personas, mensajes, mascotas}

        "17" ->
          consultar_mensajes_destinatario(mensajes)
          {usuarios, zonas, necesidades, recursos, albergues,
           personas, mensajes, mascotas}

        "18" ->
          consultar_mensajes_remitente(mensajes)
          {usuarios, zonas, necesidades, recursos, albergues,
           personas, mensajes, mascotas}

        "19" ->
          consultar_mensajes_pendientes(mensajes)
          {usuarios, zonas, necesidades, recursos, albergues,
           personas, mensajes, mascotas}

        "20" ->
          nuevos = marcar_mensaje_entregado(mensajes)
          {usuarios, zonas, necesidades, recursos, albergues,
           personas, nuevos, mascotas}

        "21" ->
          nuevas = registrar_mascota(mascotas)
          {usuarios, zonas, necesidades, recursos, albergues,
           personas, mensajes, nuevas}

        "22" ->
          listar_mascotas(mascotas)
          {usuarios, zonas, necesidades, recursos, albergues,
           personas, mensajes, mascotas}

        "23" ->
          filtrar_mascotas(mascotas)
          {usuarios, zonas, necesidades, recursos, albergues,
           personas, mensajes, mascotas}

        "24" ->
          consultar_coincidencias(mascotas)
          {usuarios, zonas, necesidades, recursos, albergues,
           personas, mensajes, mascotas}

        "25" ->
          nuevas = confirmar_coincidencia(mascotas)
          {usuarios, zonas, necesidades, recursos, albergues,
           personas, mensajes, nuevas}
      end

    menu(
      usuarios,
      zonas,
      necesidades,
      recursos,
      albergues,
      personas,
      mensajes,
      mascotas,
      usuario_actual
    )
  end
  # --------------------------------------------------
  # LISTAR ALBERGUES
  # --------------------------------------------------

  defp listar_albergues(albergues) do

    IO.puts("\n--- ALBERGUES ---")

    Enum.each(albergues, fn albergue ->

      case Albergues.cupos_disponibles(albergues, albergue.codigo) do

        {:ok, cupos} ->
          IO.puts("\nCodigo: #{albergue.codigo}")
          IO.puts("Nombre: #{albergue.nombre}")
          IO.puts("Zona: #{albergue.zona}")
          IO.puts("Capacidad: #{albergue.capacidad_maxima}")
          IO.puts("Ocupacion: #{Albergues.ocupacion(albergue)}")
          IO.puts("Cupos disponibles: #{cupos}")
          IO.puts("Personas: #{inspect(albergue.personas)}")

        {:error, razon} ->
          IO.puts("Error consultando #{albergue.codigo}: #{razon}")

      end

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
        {:ok, nuevos_recursos}

      {:error, razon} ->
        {:error, razon}

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

  defp asignar_recurso do

    IO.puts("\n--- ASIGNAR RECURSO ---")

    codigo_recurso = leer_texto("Codigo del recurso: ")
    id_necesidad = leer_texto("ID de la necesidad: ")
    cantidad = leer_entero("Cantidad a asignar: ")

    case InventarioServer.asignar_recurso(
           codigo_recurso,
           id_necesidad,
           cantidad
         ) do

      {:ok, nuevos_recursos, nuevas_necesidades} ->
        {:ok, nuevos_recursos, nuevas_necesidades}

      {:error, razon} ->
        {:error, razon}

    end
  end

  # --------------------------------------------------
  # REGISTRAR MENSAJE FAMILIAR
  # --------------------------------------------------

  defp registrar_mensaje(mensajes) do

    IO.puts("\n--- REGISTRAR MENSAJE FAMILIAR ---")

    codigo = leer_texto("Codigo del mensaje: ")
    remitente = leer_texto("Remitente: ")
    destinatario = leer_texto("Destinatario: ")
    contenido = leer_texto("Contenido del mensaje: ")

    case Mensajes.registrar_mensaje(
           mensajes,
           codigo,
           remitente,
           destinatario,
           contenido
         ) do

      {:ok, nuevos_mensajes} ->
        IO.puts("\nMensaje registrado correctamente.")
        nuevos_mensajes

      {:error, razon} ->
        IO.puts("\nError: #{razon}")
        mensajes

    end
  end

  # --------------------------------------------------
  # LISTAR MENSAJES
  # --------------------------------------------------

  defp listar_mensajes(mensajes) do

    IO.puts("\n--- MENSAJES FAMILIARES ---")

    if mensajes == [] do
      IO.puts("No hay mensajes registrados.")
    else
      Enum.each(mensajes, &IO.inspect/1)
    end
  end

  # --------------------------------------------------
  # BUSCAR MENSAJES POR DESTINATARIO
  # --------------------------------------------------

  defp consultar_mensajes_destinatario(mensajes) do

    IO.puts("\n--- BUSCAR MENSAJES POR DESTINATARIO ---")

    destinatario = leer_texto("Destinatario: ")

    resultados =
      Mensajes.buscar_por_destinatario(mensajes, destinatario)

    if resultados == [] do
      IO.puts("No se encontraron mensajes para ese destinatario.")
    else
      Enum.each(resultados, &IO.inspect/1)
    end
  end

  # --------------------------------------------------
  # BUSCAR MENSAJES POR REMITENTE
  # --------------------------------------------------

  defp consultar_mensajes_remitente(mensajes) do

    IO.puts("\n--- BUSCAR MENSAJES POR REMITENTE ---")

    remitente = leer_texto("Remitente: ")

    resultados =
      Mensajes.buscar_por_remitente(mensajes, remitente)

    if resultados == [] do
      IO.puts("No se encontraron mensajes de ese remitente.")
    else
      Enum.each(resultados, &IO.inspect/1)
    end
  end

  # --------------------------------------------------
  # CONSULTAR MENSAJES PENDIENTES
  # --------------------------------------------------

  defp consultar_mensajes_pendientes(mensajes) do

    IO.puts("\n--- MENSAJES PENDIENTES ---")

    case Mensajes.filtrar_por_estado(mensajes, "pendiente") do

      {:error, razon} ->
        IO.puts("Error: #{razon}")

      [] ->
        IO.puts("No hay mensajes pendientes.")

      resultados ->
        Enum.each(resultados, &IO.inspect/1)

    end
  end

  # --------------------------------------------------
  # MARCAR MENSAJE COMO ENTREGADO
  # --------------------------------------------------

  defp marcar_mensaje_entregado(mensajes) do

    IO.puts("\n--- MARCAR MENSAJE COMO ENTREGADO ---")

    codigo = leer_texto("Codigo del mensaje: ")

    case Mensajes.actualizar_estado(mensajes, codigo, "entregado") do

      {:ok, nuevos_mensajes} ->
        IO.puts("\nMensaje marcado como entregado.")
        nuevos_mensajes

      {:error, razon} ->
        IO.puts("\nError: #{razon}")
        mensajes

    end
  end

  # --------------------------------------------------
  # REGISTRAR REPORTE DE MASCOTA
  # --------------------------------------------------

  defp registrar_mascota(mascotas) do

    IO.puts("\n--- REGISTRAR REPORTE DE MASCOTA ---")

    codigo = leer_texto("Codigo: ")
    tipo = leer_texto("Tipo (perdida/encontrada): ")
    especie = leer_texto("Especie: ")
    nombre = leer_texto("Nombre (si se desconoce, dejar vacio): ")
    caracteristicas = leer_texto("Caracteristicas: ")
    color = leer_texto("Color: ")
    tamano = leer_texto("Tamano: ")
    zona = leer_texto("Zona: ")
    contacto = leer_texto("Contacto: ")

    case Mascotas.registrar_mascota(
           mascotas,
           codigo,
           tipo,
           especie,
           nombre,
           caracteristicas,
           color,
           tamano,
           zona,
           contacto
         ) do

      {:ok, nuevas_mascotas} ->
        IO.puts("\nReporte registrado correctamente.")
        nuevas_mascotas

      {:error, razon} ->
        IO.puts("\nError: #{razon}")
        mascotas

    end
  end

  # --------------------------------------------------
  # LISTAR REPORTES DE MASCOTAS
  # --------------------------------------------------

  defp listar_mascotas(mascotas) do

    IO.puts("\n--- REPORTES DE MASCOTAS ---")

    if mascotas == [] do
      IO.puts("No hay reportes registrados.")
    else
      Enum.each(mascotas, &IO.inspect/1)
    end
  end

  # --------------------------------------------------
  # FILTRAR REPORTES DE MASCOTAS
  # --------------------------------------------------

  defp filtrar_mascotas(mascotas) do

    IO.puts("\n--- FILTRAR REPORTES ---")
    IO.puts("1. Filtrar por especie")
    IO.puts("2. Filtrar por zona")
    IO.puts("3. Filtrar por estado")
    IO.puts("4. Filtrar por tipo de reporte")

    opcion = leer_texto("Seleccione una opcion: ")

    resultados =
      case opcion do

        "1" ->
          valor = leer_texto("Especie: ")
          Mascotas.filtrar_por_especie(mascotas, valor)

        "2" ->
          valor = leer_texto("Zona: ")
          Mascotas.filtrar_por_zona(mascotas, valor)

        "3" ->
          valor = leer_texto("Estado: ")
          Mascotas.filtrar_por_estado(mascotas, valor)

        "4" ->
          valor = leer_texto("Tipo (perdida/encontrada): ")
          Mascotas.filtrar_por_tipo(mascotas, valor)

        _ ->
          IO.puts("Opcion no valida.")
          []
      end

    if resultados == [] do
      IO.puts("No se encontraron reportes.")
    else
      Enum.each(resultados, &IO.inspect/1)
    end
  end

  # --------------------------------------------------
  # BUSCAR POSIBLES COINCIDENCIAS
  # --------------------------------------------------

  defp consultar_coincidencias(mascotas) do

    IO.puts("\n--- POSIBLES COINCIDENCIAS DE MASCOTAS ---")

    coincidencias = Mascotas.buscar_coincidencias(mascotas)

    if coincidencias == [] do
      IO.puts("No se encontraron coincidencias.")
    else
      Enum.each(coincidencias, fn coincidencia ->

        IO.puts("\nPuntaje de similitud: #{coincidencia.puntaje}")
        IO.puts("Reporte perdido:")
        IO.inspect(coincidencia.perdida)
        IO.puts("Reporte encontrado:")
        IO.inspect(coincidencia.encontrada)

      end)
    end
  end

  # --------------------------------------------------
  # CONFIRMAR COINCIDENCIA
  # --------------------------------------------------

  defp confirmar_coincidencia(mascotas) do

    IO.puts("\n--- CONFIRMAR COINCIDENCIA ---")

    codigo_perdida =
      leer_texto("Codigo del reporte de mascota perdida: ")

    codigo_encontrada =
      leer_texto("Codigo del reporte de mascota encontrada: ")

    case Mascotas.confirmar_coincidencia(
           mascotas,
           codigo_perdida,
           codigo_encontrada
         ) do

      {:ok, nuevas_mascotas} ->
        IO.puts("\nCoincidencia confirmada.")
        IO.puts("Los dos reportes fueron marcados como resueltos.")
        nuevas_mascotas

      {:error, razon} ->
        IO.puts("\nError: #{razon}")
        mascotas

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
