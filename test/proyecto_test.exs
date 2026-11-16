# =============================================================================
# test/pruebas_sistema_test.exs   (versión reducida)
#
# Pruebas alineadas con el enunciado del proyecto final:
#   1. Registro y consulta      (@moduletag :registro)
#   2. Validaciones             (@moduletag :validaciones)
#   3. Persistencia             (@moduletag :persistencia)
#   4. Asignación de recursos   (@moduletag :asignacion)
#   5. Concurrencia             (@moduletag :concurrencia)
#
# Ejecutar:  mix test test/pruebas_sistema_test.exs
#            mix test --only concurrencia
#
# Los archivos de priv/data se respaldan, se vacían y se restauran en cada
# prueba (SoporteDatos.preparar/0). Por eso todo es async: false.
# =============================================================================

defmodule SoporteDatos do
  @moduledoc false
  import ExUnit.Callbacks, only: [on_exit: 1]
  import ExUnit.Assertions

  @archivos [
    {PersistenciaRecursos, "recursos.txt"},
    {PersistenciaNecesidades, "necesidades.txt"},
    {PersistenciaZonas, "zonas.txt"},
    {PersistenciaPersonas, "personas.txt"},
    {PersistenciaAlbergues, "albergues.txt"},
    {PersistenciaMascotas, "mascotas.txt"},
    {PersistenciaMensajes, "mensajes.txt"},
    {Usuarios, "usuarios.txt"}
  ]

  # Calcula la ruta igual que los módulos del sistema: ../../priv/data/ respecto
  # a la carpeta del archivo fuente donde se compiló el módulo.
  def ruta(modulo, archivo) do
    modulo.module_info(:compile)[:source]
    |> to_string()
    |> Path.dirname()
    |> Path.join("../../priv/data/" <> archivo)
    |> Path.expand()
  end

  # Respalda los archivos reales, los deja vacíos y programa su restauración.
  def preparar do
    respaldos =
      Enum.map(@archivos, fn {modulo, archivo} ->
        ruta = ruta(modulo, archivo)

        copia =
          case File.read(ruta) do
            {:ok, contenido} -> {:existia, contenido}
            {:error, _} -> :no_existia
          end

        {ruta, copia}
      end)

    Enum.each(respaldos, fn {ruta, _} -> vaciar(ruta) end)
    on_exit(fn -> Enum.each(respaldos, &restaurar/1) end)
    :ok
  end

  defp vaciar(ruta) do
    File.rm_rf(ruta)
    File.mkdir_p!(Path.dirname(ruta))
    File.write!(ruta, "")
  end

  defp restaurar({ruta, :no_existia}), do: File.rm_rf(ruta)

  defp restaurar({ruta, {:existia, contenido}}) do
    File.rm_rf(ruta)
    File.mkdir_p!(Path.dirname(ruta))
    File.write!(ruta, contenido)
  end

  # Ejecuta fun sin imprimir en consola (algunos módulos usan IO.inspect/IO.puts).
  def silencio(fun) do
    padre = self()
    ExUnit.CaptureIO.capture_io(fn -> send(padre, {:resultado, fun.()}) end)

    receive do
      {:resultado, resultado} -> resultado
    end
  end

  def escribir(modulo, archivo, contenido), do: File.write!(ruta(modulo, archivo), contenido)

  # Deja una CARPETA donde debería estar el archivo: guardar/cargar fallan.
  def romper_archivo(modulo, archivo) do
    ruta = ruta(modulo, archivo)
    File.rm_rf(ruta)
    File.mkdir_p!(ruta)
  end

  # Afirma {:error, mensaje} y devuelve el mensaje.
  def mensaje_error(resultado) do
    assert {:error, mensaje} = resultado
    mensaje
  end

  def zona_base(codigo \\ "Z1") do
    %Zona{codigo: codigo, nombre: "Centro", nivel_afectacion: "alto", personas_afectadas: 100, sectores: []}
  end
end

# =============================================================================
# 1. REGISTRO Y CONSULTA
# =============================================================================

defmodule RegistroConsultaTest do
  use ExUnit.Case, async: false
  @moduletag :registro

  import SoporteDatos, only: [silencio: 1]

  setup do
    SoporteDatos.preparar()
  end

  test "zonas: árbol zona > sector > punto, consultas y estadísticas" do
    {:ok, zonas} = Zonas.registrar_zona([], "Z1", "Centro", "alto", 100)
    {:ok, zonas} = Zonas.registrar_zona(zonas, "Z2", "Río", "critico", 50)
    {:ok, zonas} = Zonas.registrar_sector(zonas, "Z1", "S1", "Norte", "medio", 40)
    {:ok, zonas} = Zonas.registrar_punto(zonas, "Z1", "S1", "P1", "Hospital", "Calle 1", "salud")

    zona = Zonas.buscar_zona(zonas, "Z1")
    assert Zonas.contar_sectores(zona) == 1
    assert Zonas.contar_puntos(zona) == 1
    assert [%PuntoAtencion{codigo: "P1", estado: "activo"}] = Zonas.obtener_puntos(zona)
    assert Zonas.buscar_zona(zonas, "Z9") == nil

    estadisticas = Zonas.estadisticas(zonas)
    assert estadisticas.total_zonas == 2
    assert estadisticas.total_sectores == 1
    assert estadisticas.total_puntos == 1
    assert estadisticas.personas_afectadas == 150
    assert [%Zona{codigo: "Z2"}] = estadisticas.zonas_criticas
  end

  test "personas: nacen 'afectada', se consultan y su cambio de estado queda en el historial" do
    {:ok, _} = Zonas.registrar_zona([], "Z1", "Centro", "alto", 100)
    {:ok, personas} = silencio(fn -> Personas.registrar_persona([], "P1", "Ana", 30, "Z1") end)

    assert %Persona{estado: "afectada", albergue: nil, historial: ["Registro inicial"]} =
             Personas.buscar_persona(personas, "P1")

    assert length(Personas.filtrar_por_zona(personas, "Z1")) == 1

    {:ok, personas} = Personas.actualizar_estado(personas, "P1", "localizada")
    persona = Personas.buscar_persona(personas, "P1")
    assert persona.estado == "localizada"
    assert List.last(persona.historial) == "Estado actualizado a: localizada"
    assert length(Personas.filtrar_por_estado(personas, "localizada")) == 1
  end

  test "albergues: alojar y retirar actualizan albergue y persona, y los cupos" do
    {:ok, _} = Zonas.registrar_zona([], "Z1", "Centro", "alto", 100)
    {:ok, albergues} = silencio(fn -> Albergues.registrar_albergue([], "A1", "Coliseo", "Z1", 2) end)
    {:ok, personas} = silencio(fn -> Personas.registrar_persona([], "P1", "Ana", 30, "Z1") end)

    assert Albergues.cupos_disponibles(albergues, "A1") == {:ok, 2}

    {:ok, albergues, personas} = Albergues.alojar_persona(albergues, personas, "A1", "P1")
    assert %Persona{estado: "alojada", albergue: "A1"} = Personas.buscar_persona(personas, "P1")
    assert Albergues.cupos_disponibles(albergues, "A1") == {:ok, 1}

    {:ok, albergues, personas} = Albergues.retirar_persona(albergues, personas, "A1", "P1")
    assert %Persona{estado: "rescatada", albergue: nil} = Personas.buscar_persona(personas, "P1")
    assert Albergues.cupos_disponibles(albergues, "A1") == {:ok, 2}
  end

  test "recursos: se registran normalizados y se consultan por código, categoría y ubicación" do
    {:ok, recursos} = Recursos.registrar_recurso([], " R1 ", " Agua ", " ALIMENTOS ", 100, "litros", " Bodega A ")
    {:ok, recursos} = Recursos.registrar_recurso(recursos, "R2", "Cobijas", "Abrigo", 20, "unidades", "Bodega B")

    assert %Recurso{codigo: "R1", categoria: "alimentos", ubicacion: "Bodega A", historial: ["Registro inicial: 100 litros"]} =
             Recursos.buscar_recurso(recursos, "R1")

    assert [%Recurso{codigo: "R1"}] = Recursos.filtrar_por_categoria(recursos, "ALIMENTOS")
    assert [%Recurso{codigo: "R2"}] = Recursos.filtrar_por_zona(recursos, "Bodega B")
    assert Recursos.buscar_recurso(recursos, "R9") == nil
  end

  test "necesidades: nacen pendientes y se ordenan/filtran por prioridad, zona y estado" do
    zonas = [SoporteDatos.zona_base("Z1"), SoporteDatos.zona_base("Z2")]
    {:ok, ns} = Necesidades.registrar_necesidad([], zonas, "N1", "agua", "d", 5, "Z1", "baja", "Ana")
    {:ok, ns} = Necesidades.registrar_necesidad(ns, zonas, "N2", "agua", "d", 5, "Z1", "critica", "Ana")
    {:ok, ns} = Necesidades.registrar_necesidad(ns, zonas, "N3", "agua", "d", 5, "Z2", " ALTA ", "Ana")

    assert %Necesidad{estado: "pendiente", recursos_asignados: []} = Necesidades.buscar_necesidad(ns, "N1")

    assert ns |> Necesidades.ordenar_por_prioridad() |> Enum.map(& &1.id) == ["N2", "N3", "N1"]
    assert [%Necesidad{id: "N3"}] = Necesidades.filtrar_por_zona(ns, "Z2")
    assert [%Necesidad{id: "N3"}] = Necesidades.filtrar_por_prioridad(ns, "alta")
    assert length(Necesidades.filtrar_por_estado(ns, "pendiente")) == 3
  end

  test "mascotas: detecta coincidencias por puntaje y las confirma cerrando ambos reportes" do
    {:ok, ms} =
      Mascotas.registrar_mascota([], "M1", "perdida", "perro", "Luna", "collar rojo", "negra", "mediana", "Z1", "300")

    {:ok, ms} =
      Mascotas.registrar_mascota(ms, "M2", "encontrada", "perro", "", "collar azul", "Negra", "mediana", "z1", "301")

    assert Mascotas.buscar_mascota(ms, "M2").nombre == "desconocido"

    # especie 35 + color 20 + tamaño 15 + zona 15 = 85
    assert [%{perdida: %Mascota{codigo: "M1"}, encontrada: %Mascota{codigo: "M2"}, puntaje: 85}] =
             Mascotas.buscar_coincidencias(ms)

    {:ok, ms} = Mascotas.confirmar_coincidencia(ms, "M1", "M2")
    assert %Mascota{estado: "resuelta", coincidencia: "M2"} = Mascotas.buscar_mascota(ms, "M1")
    assert %Mascota{estado: "resuelta", coincidencia: "M1"} = Mascotas.buscar_mascota(ms, "M2")
  end

  test "mensajes: se registran pendientes, se consultan y se marcan entregados" do
    {:ok, ms} = Mensajes.registrar_mensaje([], "MS1", "ana", "luis", "Estoy bien")

    assert %Mensaje{estado: "pendiente", remitente: "ana", destinatario: "luis"} =
             Mensajes.buscar_mensaje(ms, "MS1")

    assert [%Mensaje{codigo: "MS1"}] = Mensajes.buscar_por_destinatario(ms, "luis")

    {:ok, ms} = Mensajes.actualizar_estado(ms, "MS1", "entregado")
    assert length(Mensajes.filtrar_por_estado(ms, "entregado")) == 1
  end
end

# =============================================================================
# 2. VALIDACIONES  (reglas del apartado "Validaciones y manejo de errores")
# =============================================================================

defmodule ValidacionesTest do
  use ExUnit.Case, async: false
  @moduletag :validaciones

  import SoporteDatos, only: [silencio: 1, escribir: 3, mensaje_error: 1]

  setup do
    SoporteDatos.preparar()
  end

  test "zonas: datos inválidos y códigos repetidos" do
    assert mensaje_error(Zonas.registrar_zona([], "  ", "Centro", "alto", 10)) =~ "obligatorios"
    assert mensaje_error(Zonas.registrar_zona([], "Z1", "Centro", "extremo", 10)) =~ "Nivel"
    assert mensaje_error(Zonas.registrar_zona([], "Z1", "Centro", "alto", -5)) =~ "no negativo"

    {:ok, zonas} = Zonas.registrar_zona([], "Z1", "Centro", "alto", 100)
    assert mensaje_error(Zonas.registrar_zona(zonas, "Z1", "Otra", "bajo", 1)) =~ "ya esta registrado"
    assert mensaje_error(Zonas.registrar_sector(zonas, "Z9", "S1", "Norte", "bajo", 1)) =~ "zona no existe"
  end

  test "recursos: identificadores únicos y cantidades no negativas ni cero" do
    {:ok, recursos} = Recursos.registrar_recurso([], "R1", "Agua", "agua", 10, "l", "B")

    assert mensaje_error(Recursos.registrar_recurso(recursos, "R1", "Otra", "agua", 5, "l", "B")) =~ "Ya existe"

    for cantidad <- [0, -5, 2.5, "10"] do
      assert mensaje_error(Recursos.registrar_recurso([], "R2", "Agua", "agua", cantidad, "l", "B")) =~
               "entero mayor"
    end

    # una salida nunca deja el inventario en negativo
    assert mensaje_error(Recursos.actualizar_cantidad(recursos, "R1", "salida", 11)) =~ "No hay suficiente"
  end

  test "necesidades: transiciones válidas y una necesidad cerrada no se cierra dos veces" do
    zonas = [SoporteDatos.zona_base("Z1")]
    {:ok, ns} = Necesidades.registrar_necesidad([], zonas, "N1", "agua", "d", 5, "Z1", "alta", "Ana")

    assert mensaje_error(Necesidades.registrar_necesidad(ns, zonas, "N1", "agua", "d", 5, "Z1", "alta", "Ana")) =~
             "Ya existe"

    assert mensaje_error(Necesidades.registrar_necesidad([], zonas, "N2", "agua", "d", 0, "Z1", "alta", "Ana")) =~
             "mayor que cero"

    assert mensaje_error(Necesidades.registrar_necesidad([], zonas, "N2", "agua", "d", 5, "Z1", "urgente", "Ana")) =~
             "prioridad"

    # pendiente -> atendida no está permitido
    assert mensaje_error(Necesidades.actualizar_estado(ns, "N1", "atendida")) =~ "transici"

    {:ok, ns} = Necesidades.actualizar_estado(ns, "N1", "asignada")
    {:ok, ns} = Necesidades.actualizar_estado(ns, "N1", "en_atencion")
    {:ok, ns} = Necesidades.actualizar_estado(ns, "N1", "atendida")

    # atendida es final: no se puede cerrar ni cancelar de nuevo
    assert mensaje_error(Necesidades.actualizar_estado(ns, "N1", "atendida")) =~ "ya tiene"
    assert mensaje_error(Necesidades.actualizar_estado(ns, "N1", "cancelada")) =~ "transici"
  end

  test "albergues: capacidad máxima nunca superada y reglas de alojamiento" do
    assert mensaje_error(silencio(fn -> Albergues.registrar_albergue([], "A1", "Coliseo", "Z1", 0) end)) =~
             "mayor que cero"

    albergues = [%Albergue{codigo: "A1", nombre: "Coliseo", zona: "Z1", capacidad_maxima: 1, personas: ["P9"]}]

    personas = [
      %Persona{codigo: "P1", nombre: "Ana", edad: 20, zona: "Z1", estado: "afectada"},
      %Persona{codigo: "P2", nombre: "Luis", edad: 20, zona: "Z1", estado: "afectada", albergue: "A2"}
    ]

    assert mensaje_error(Albergues.alojar_persona(albergues, personas, "A1", "P1")) =~ "cupos"
    assert mensaje_error(Albergues.alojar_persona(albergues, personas, "A1", "P2")) =~ "ya pertenece"
    assert mensaje_error(Albergues.actualizar_capacidad(albergues, "A1", 0)) =~ "mayor que cero"
  end

  test "mascotas: no se puede resolver dos veces el mismo reporte" do
    nueva = fn ms, codigo, tipo ->
      {:ok, ms} = Mascotas.registrar_mascota(ms, codigo, tipo, "perro", "Fido", "collar", "negra", "mediana", "Z1", "300")
      ms
    end

    ms = [] |> nueva.("M1", "perdida") |> nueva.("M2", "encontrada")

    assert mensaje_error(Mascotas.registrar_mascota(ms, "M1", "perdida", "perro", "Fido", "c", "negra", "m", "Z1", "3")) =~
             "Ya existe"

    assert mensaje_error(Mascotas.registrar_mascota(ms, "M3", "extraviada", "perro", "F", "c", "n", "m", "Z1", "3")) =~
             "tipo de reporte"

    {:ok, ms} = Mascotas.confirmar_coincidencia(ms, "M1", "M2")
    assert mensaje_error(Mascotas.confirmar_coincidencia(ms, "M1", "M2")) =~ "ya fueron resueltos"
  end

  test "mensajes: solo pendiente -> entregado, y no se repite el código" do
    {:ok, ms} = Mensajes.registrar_mensaje([], "MS1", "ana", "luis", "Hola")

    assert mensaje_error(Mensajes.registrar_mensaje(ms, "MS1", "ana", "luis", "Otro")) =~ "ya existe"
    assert mensaje_error(Mensajes.registrar_mensaje([], "MS2", "ana", "luis", "  ")) =~ "obligatorios"

    {:ok, ms} = Mensajes.actualizar_estado(ms, "MS1", "entregado")
    assert mensaje_error(Mensajes.actualizar_estado(ms, "MS1", "entregado")) =~ "ya fue entregado"
  end

  test "usuarios: credenciales y archivo mal formado" do
    usuarios = [%Usuario{nombreUsuario: "ana", contraseña: "123", categoria: "ciudadano"}]

    assert mensaje_error(Usuarios.validar(usuarios, "", "123")) =~ "obligatorios"
    assert mensaje_error(Usuarios.validar(usuarios, "luis", "123")) =~ "registrado"
    assert mensaje_error(Usuarios.validar(usuarios, "ana", "999")) =~ "no coincide"
    assert {:ok, %Usuario{}} = silencio(fn -> Usuarios.validar(usuarios, "ana", "123") end)

    escribir(Usuarios, "usuarios.txt", "ana;123;Ana;rey;Armenia\n")
    assert mensaje_error(Usuarios.cargar_usuarios()) =~ "rey"
  end
end

# =============================================================================
# 3. PERSISTENCIA  (archivos de texto plano)
# =============================================================================

defmodule PersistenciaTest do
  use ExUnit.Case, async: false
  @moduletag :persistencia

  import SoporteDatos, only: [silencio: 1, escribir: 3, romper_archivo: 2, mensaje_error: 1]

  setup do
    SoporteDatos.preparar()
  end

  test "recursos: guardar y cargar devuelven lo mismo (incluye '|', tildes e historial vacío)" do
    recursos = [
      %Recurso{codigo: "R1", nombre: "Agua | potable ñ", categoria: "agua", cantidad: 10, unidad: "litros", ubicacion: "Bodega #1", historial: ["Registro inicial: 10 litros", "salida: 2 litros"]},
      %Recurso{codigo: "R2", nombre: "Cobijas", categoria: "abrigo", cantidad: 0, unidad: "unidades", ubicacion: "Bodega B", historial: []}
    ]

    assert {:ok, _} = PersistenciaRecursos.guardar(recursos)
    assert PersistenciaRecursos.cargar() == {:ok, recursos}
  end

  test "necesidades: guardar y cargar devuelven lo mismo" do
    necesidades = [
      %Necesidad{id: "N1", tipo: "agua", descripcion: "Agua | potable", cantidad: 50, zona: "Z1", prioridad: "alta", responsable: "Ana", estado: "asignada", recursos_asignados: ["R1:30", "R2:5"]},
      %Necesidad{id: "N2", tipo: "abrigo", descripcion: "Cobijas", cantidad: 10, zona: "Z1", prioridad: "baja", responsable: "Luis", estado: "pendiente", recursos_asignados: []}
    ]

    assert {:ok, _} = PersistenciaNecesidades.guardar(necesidades)
    assert PersistenciaNecesidades.cargar() == {:ok, necesidades}
  end

  test "zonas: el árbol zona > sector > punto se guarda y se recarga idéntico" do
    {:ok, zonas} = Zonas.registrar_zona([], "Z1", "Centro", "alto", 100)
    {:ok, zonas} = Zonas.registrar_sector(zonas, "Z1", "S1", "Norte", "medio", 40)
    {:ok, zonas} = Zonas.registrar_punto(zonas, "Z1", "S1", "P1", "Hospital", "Calle 1", "salud")

    assert silencio(fn -> PersistenciaZonas.cargar() end) == {:ok, zonas}
  end

  test "personas, mascotas y mensajes: lo que guardan los módulos de dominio se recarga igual" do
    {:ok, _} = Zonas.registrar_zona([], "Z1", "Centro", "alto", 100)
    {:ok, personas} = silencio(fn -> Personas.registrar_persona([], "P1", "Ana", 30, "Z1") end)
    {:ok, personas} = Personas.actualizar_estado(personas, "P1", "localizada")
    assert PersistenciaPersonas.cargar() == {:ok, personas}

    {:ok, ms} = Mascotas.registrar_mascota([], "M1", "perdida", "perro", "Luna", "collar | rojo", "negra", "mediana", "Z1", "300")
    {:ok, ms} = Mascotas.registrar_mascota(ms, "M2", "encontrada", "perro", "", "collar", "negra", "mediana", "Z1", "301")
    {:ok, ms} = Mascotas.confirmar_coincidencia(ms, "M1", "M2")
    assert PersistenciaMascotas.cargar() == {:ok, ms}

    {:ok, mensajes} = Mensajes.registrar_mensaje([], "MS1", "ana", "luis", "Hola | ¿necesitas agua?")
    {:ok, mensajes} = Mensajes.actualizar_estado(mensajes, "MS1", "entregado")
    assert PersistenciaMensajes.cargar() == {:ok, mensajes}
  end

  test "albergues: se guardan y recargan (cargar exige que la zona exista)" do
    {:ok, _} = Zonas.registrar_zona([], "Z1", "Centro", "alto", 100)

    albergues = [
      %Albergue{codigo: "A1", nombre: "Coliseo", zona: "Z1", capacidad_maxima: 3, personas: ["P1", "P2"], recursos_asignados: ["R1"]}
    ]

    assert {:ok, _} = PersistenciaAlbergues.guardar(albergues)
    assert silencio(fn -> PersistenciaAlbergues.cargar() end) == {:ok, albergues}
  end

  test "archivos corruptos o con duplicados se rechazan con un error (sin excepción)" do
    escribir(PersistenciaRecursos, "recursos.txt", "esto-no-es-base64!!\n")
    assert mensaje_error(PersistenciaRecursos.cargar()) =~ "decodificar"

    r = %Recurso{codigo: "R1", nombre: "Agua", categoria: "agua", cantidad: 5, unidad: "l", ubicacion: "B", historial: []}
    {:ok, _} = PersistenciaRecursos.guardar([r, r])
    assert mensaje_error(PersistenciaRecursos.cargar()) =~ "duplicado"

    escribir(PersistenciaMensajes, "mensajes.txt", "M|abc\n")
    assert mensaje_error(PersistenciaMensajes.cargar()) =~ "formato"
  end

  test "si no se puede escribir, guardar devuelve error" do
    romper_archivo(PersistenciaRecursos, "recursos.txt")
    assert mensaje_error(PersistenciaRecursos.guardar([])) =~ "No se pudieron guardar"
  end

  test "cargar crea el archivo vacío si no existe" do
    File.rm_rf(SoporteDatos.ruta(PersistenciaRecursos, "recursos.txt"))
    assert PersistenciaRecursos.cargar() == {:ok, []}
  end
end

# =============================================================================
# 4. ASIGNACIÓN DE RECURSOS
# =============================================================================

defmodule AsignacionRecursosTest do
  use ExUnit.Case, async: false
  @moduletag :asignacion

  import SoporteDatos, only: [romper_archivo: 2, mensaje_error: 1]

  # Parte de: R1 = 100 litros de agua y N1 = necesidad pendiente.
  setup do
    :ok = SoporteDatos.preparar()
    {:ok, recursos} = Recursos.registrar_recurso([], "R1", "Agua", "agua", 100, "litros", "Bodega A")

    {:ok, necesidades} =
      Necesidades.registrar_necesidad([], [SoporteDatos.zona_base("Z1")], "N1", "agua", "Agua potable", 50, "Z1", "alta", "Ana")

    {:ok, recursos: recursos, necesidades: necesidades}
  end

  test "asignar descuenta inventario, pasa la necesidad a 'asignada' y queda guardado",
       %{recursos: recursos, necesidades: necesidades} do
    {:ok, rs, ns} = Recursos.asignar_recurso(recursos, necesidades, "R1", "N1", 30)

    recurso = Recursos.buscar_recurso(rs, "R1")
    necesidad = Necesidades.buscar_necesidad(ns, "N1")

    assert recurso.cantidad == 70
    assert hd(recurso.historial) == "Asignación de 30 litros a N1"
    assert necesidad.estado == "asignada"
    assert necesidad.recursos_asignados == ["R1:30"]
    assert PersistenciaRecursos.cargar() == {:ok, rs}
    assert PersistenciaNecesidades.cargar() == {:ok, ns}
  end

  test "varias asignaciones se acumulan y conservan el total: asignado + restante = inicial",
       %{recursos: recursos, necesidades: necesidades} do
    {rs, ns} =
      Enum.reduce([5, 10, 20], {recursos, necesidades}, fn cantidad, {rs, ns} ->
        {:ok, rs2, ns2} = Recursos.asignar_recurso(rs, ns, "R1", "N1", cantidad)
        {rs2, ns2}
      end)

    asignado =
      ns
      |> Necesidades.buscar_necesidad("N1")
      |> Map.fetch!(:recursos_asignados)
      |> Enum.map(fn "R1:" <> n -> String.to_integer(n) end)
      |> Enum.sum()

    assert asignado == 35
    assert Recursos.buscar_recurso(rs, "R1").cantidad + asignado == 100
  end

  test "pedir más de lo disponible falla y no cambia nada (memoria ni disco)",
       %{recursos: recursos, necesidades: necesidades} do
    assert mensaje_error(Recursos.asignar_recurso(recursos, necesidades, "R1", "N1", 101)) =~
             "No hay suficiente inventario"

    assert mensaje_error(Recursos.asignar_recurso(recursos, necesidades, "R1", "N1", -1)) =~ "entero mayor"
    assert PersistenciaRecursos.cargar() == {:ok, recursos}
    assert PersistenciaNecesidades.cargar() == {:ok, necesidades}
  end

  test "una necesidad atendida o cancelada no vuelve a consumir recursos",
       %{recursos: recursos, necesidades: [necesidad]} do
    for estado <- ["atendida", "cancelada"] do
      assert mensaje_error(Recursos.asignar_recurso(recursos, [%{necesidad | estado: estado}], "R1", "N1", 5)) =~
               "no permite recibir"
    end
  end

  test "si falla guardar las necesidades, el inventario se restaura (rollback)",
       %{recursos: recursos, necesidades: necesidades} do
    romper_archivo(PersistenciaNecesidades, "necesidades.txt")

    assert mensaje_error(Recursos.asignar_recurso(recursos, necesidades, "R1", "N1", 30)) =~ "restaurado"
    assert PersistenciaRecursos.cargar() == {:ok, recursos}
  end

  test "entradas, salidas y transferencias entre centros conservan el inventario",
       %{recursos: recursos} do
    {:ok, rs} = Recursos.actualizar_cantidad(recursos, "R1", "entrada", 50)
    assert Recursos.buscar_recurso(rs, "R1").cantidad == 150

    {:ok, rs} = Recursos.transferir_recurso(rs, "R1", "R2", 30, "Albergue 2")
    assert Recursos.buscar_recurso(rs, "R1").cantidad == 120
    assert %Recurso{cantidad: 30, ubicacion: "Albergue 2"} = Recursos.buscar_recurso(rs, "R2")
    assert Enum.sum(Enum.map(rs, & &1.cantidad)) == 150

    assert mensaje_error(Recursos.transferir_recurso(rs, "R1", "R3", 500, "Albergue 3")) =~ "No hay suficiente"
  end
end

# =============================================================================
# 5. CONCURRENCIA  (InventarioServer, un GenServer)
# =============================================================================

defmodule ConcurrenciaTest do
  use ExUnit.Case, async: false
  @moduletag :concurrencia
  @moduletag timeout: 60_000

  # R1 = 100 litros, R2 = 50 litros (caso del enunciado), R3 = 10 kg.
  setup do
    detener_servidor()
    :ok = SoporteDatos.preparar()

    {:ok, recursos} = Recursos.registrar_recurso([], "R1", "Agua", "agua", 100, "litros", "Bodega A")
    {:ok, recursos} = Recursos.registrar_recurso(recursos, "R2", "Agua", "agua", 50, "litros", "Centro 1")
    {:ok, _} = Recursos.registrar_recurso(recursos, "R3", "Arroz", "alimentos", 10, "kg", "Bodega A")

    zonas = [SoporteDatos.zona_base("Z1")]
    {:ok, necesidades} = Necesidades.registrar_necesidad([], zonas, "N1", "agua", "Punto 3", 1000, "Z1", "critica", "Laura")
    {:ok, _} = Necesidades.registrar_necesidad(necesidades, zonas, "N2", "agua", "Albergue", 1000, "Z1", "alta", "Luis")

    {:ok, _pid} = InventarioServer.iniciar()
    on_exit(&detener_servidor/0)
    :ok
  end

  defp detener_servidor do
    case Process.whereis(InventarioServer) do
      nil ->
        :ok

      pid ->
        try do
          GenServer.stop(pid)
        catch
          :exit, _ -> :ok
        end
    end
  end

  defp cantidad(estado, codigo), do: Recursos.buscar_recurso(estado.recursos, codigo).cantidad

  defp asignaciones(estado, id),
    do: Necesidades.buscar_necesidad(estado.necesidades, id).recursos_asignados

  defp en_paralelo(n, fun) do
    1..n
    |> Task.async_stream(fun, max_concurrency: n, timeout: 30_000)
    |> Enum.map(fn {:ok, resultado} -> resultado end)
  end

  test "caso del enunciado: 30 y 25 litros pedidos a la vez sobre 50 nunca suman 55" do
    resultados =
      [
        Task.async(fn -> InventarioServer.asignar_recurso("R2", "N1", 30) end),
        Task.async(fn -> InventarioServer.asignar_recurso("R2", "N2", 25) end)
      ]
      |> Task.await_many(30_000)

    # Solo una de las dos cabe en el inventario real.
    assert Enum.count(resultados, &match?({:ok, _, _}, &1)) == 1
    assert Enum.count(resultados, &match?({:error, _}, &1)) == 1

    estado = InventarioServer.consultar_estado()
    assert cantidad(estado, "R2") in [20, 25]
    assert cantidad(estado, "R2") >= 0
  end

  test "30 procesos piden 1 kg de un recurso de 10 kg: se confirman exactamente 10" do
    resultados = en_paralelo(30, fn _ -> InventarioServer.asignar_recurso("R3", "N1", 1) end)

    assert Enum.count(resultados, &match?({:ok, _, _}, &1)) == 10
    assert Enum.count(resultados, &match?({:error, _}, &1)) == 20

    estado = InventarioServer.consultar_estado()
    assert cantidad(estado, "R3") == 0
    assert length(asignaciones(estado, "N1")) == 10

    {:ok, en_disco} = PersistenciaRecursos.cargar()
    assert Recursos.buscar_recurso(en_disco, "R3").cantidad == 0
  end

  test "50 asignaciones simultáneas no pierden ninguna actualización y quedan en disco" do
    resultados = en_paralelo(50, fn _ -> InventarioServer.asignar_recurso("R1", "N1", 1) end)
    assert Enum.all?(resultados, &match?({:ok, _, _}, &1))

    estado = InventarioServer.consultar_estado()
    assert cantidad(estado, "R1") == 50
    assert length(asignaciones(estado, "N1")) == 50
    assert PersistenciaRecursos.cargar() == {:ok, estado.recursos}
    assert PersistenciaNecesidades.cargar() == {:ok, estado.necesidades}
  end

  test "un pedido inválido no tumba al servidor ni cambia el estado, y recargar lee el disco" do
    antes = InventarioServer.consultar_estado()

    assert {:error, _} = InventarioServer.asignar_recurso("NOEXISTE", "N1", 1)
    assert {:error, _} = InventarioServer.asignar_recurso("R1", "N1", 1000)
    assert Process.alive?(Process.whereis(InventarioServer))
    assert InventarioServer.consultar_estado() == antes

    # Cambio hecho por fuera del servidor: solo se ve después de recargar.
    {:ok, _} = Recursos.registrar_recurso(antes.recursos, "R9", "Cobijas", "abrigo", 5, "unidades", "Bodega C")
    assert Recursos.buscar_recurso(InventarioServer.consultar_estado().recursos, "R9") == nil
    assert {:ok, nuevo} = InventarioServer.recargar()
    assert Recursos.buscar_recurso(nuevo.recursos, "R9").cantidad == 5
  end
end
