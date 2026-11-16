
defmodule Emergencias.Supervisor do
  @moduledoc """
  Supervisor encargado de iniciar y controlar los procesos
  relacionados con el sistema de gestión de emergencias.

  Utiliza el comportamiento Supervisor de Elixir para administrar
  el ciclo de vida de los procesos hijos, permitiendo que estos
  sean reiniciados automáticamente cuando presentan fallos.

  Actualmente, este supervisor administra el siguiente proceso:

  - `InventarioServer`: servidor GenServer encargado de mantener
    y administrar el estado de los recursos y las necesidades
    del sistema.

  **Estrategia de supervisión:**

  Utiliza la estrategia `:one_for_one`, que indica que cuando
  un proceso hijo falla, únicamente se reinicia ese proceso,
  sin afectar a los demás procesos hijos.

  **Funcionamiento general:**

  1. Se inicia el supervisor mediante `start_link/1`.
  2. Se ejecuta `init/1` para definir los procesos hijos.
  3. Se registra `InventarioServer` como proceso hijo.
  4. El supervisor inicia y supervisa el proceso hijo.
  5. Si el proceso hijo falla, el supervisor intenta reiniciarlo.

  **Módulos relacionados:**

  - `InventarioServer`: proceso hijo administrado por este supervisor.
  - `Proyectoprog.Application`: aplicación que inicia este supervisor
    como parte de la estructura principal de supervisión.

  **Consideración:**

  Cuando `InventarioServer` se reinicia, vuelve a ejecutar su función
  `init/1`, por lo que intenta recuperar los recursos y las necesidades
  desde los archivos de persistencia.
  """

  use Supervisor

  # --------------------------------------------------
  # INICIAR EL SUPERVISOR
  # --------------------------------------------------

  @doc """
  Inicia el proceso supervisor y lo registra con el nombre del módulo.

  Esta función permite que el supervisor sea iniciado desde la
  aplicación principal o desde otro proceso supervisor.

  **Entradas:**

  - `opts`: opciones recibidas durante el inicio. Actualmente
    no se utilizan.

  **Proceso:**

  1. Invoca `Supervisor.start_link/3`.
  2. Indica que el módulo actual implementa el supervisor.
  3. Envía `:ok` como argumento inicial para ejecutar `init/1`.
  4. Registra el proceso supervisor con el nombre
     `Emergencias.Supervisor`.

  **Salidas:**

  - `{:ok, pid}`: el supervisor se inició correctamente.
  - `{:error, razon}`: no fue posible iniciar el supervisor.

  **Posibles fallos:**

  - Ya existe un proceso registrado con el mismo nombre.
  - Ocurre un error durante la inicialización de los procesos hijos.
  - Alguno de los procesos hijos no puede iniciarse correctamente.

  **Relación:** es utilizado por `Proyectoprog.Application`
  para iniciar la supervisión de los procesos del sistema.
  """
  def start_link(_opts) do
    Supervisor.start_link(
      __MODULE__,
      :ok,
      name: __MODULE__
    )
  end

  # --------------------------------------------------
  # INICIALIZAR LOS PROCESOS HIJOS
  # --------------------------------------------------

  @doc """
  Define e inicializa los procesos hijos que estarán bajo
  la supervisión de `Emergencias.Supervisor`.

  Esta función es ejecutada automáticamente cuando se inicia
  el supervisor.

  **Entradas:**

  - `:ok`: argumento inicial enviado desde `start_link/1`.

  **Proceso:**

  1. Crea la lista de procesos hijos que debe administrar
     el supervisor.
  2. Agrega `InventarioServer` como proceso hijo.
  3. Invoca `Supervisor.init/2` para configurar la supervisión.
  4. Establece la estrategia `:one_for_one`.

  **Estrategia de supervisión:**

  `:one_for_one` indica que si un proceso hijo falla,
  el supervisor intenta reiniciar únicamente ese proceso,
  sin reiniciar los demás procesos hijos.

  **Salidas:**

  Devuelve la configuración de supervisión que utilizará
  Elixir para iniciar y administrar los procesos hijos.

  **Posibles fallos:**

  - Un módulo hijo no tiene una especificación de inicio válida.
  - La configuración de los procesos hijos es incorrecta.
  - No es posible iniciar alguno de los procesos hijos.
  - `InventarioServer` falla durante su inicialización,
    por ejemplo, al no poder cargar los archivos de persistencia.

  **Relación:** administra el ciclo de vida de `InventarioServer`.
  """
  @impl true
  def init(:ok) do
    hijos = [
      InventarioServer
    ]

    Supervisor.init(
      hijos,
      strategy: :one_for_one
    )
  end
end
