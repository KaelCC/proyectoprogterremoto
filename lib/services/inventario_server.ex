defmodule InventarioServer do
  use GenServer

  # --------------------------------------------------
  # INICIAR EL PROCESO
  # --------------------------------------------------

  def iniciar do
    case GenServer.start_link(__MODULE__, :ok, name: __MODULE__) do
      {:ok, pid} ->
        {:ok, pid}

      {:error, {:already_started, pid}} ->
        {:ok, pid}

      {:error, razon} ->
        {:error, razon}
    end
  end

  # --------------------------------------------------
  # INICIALIZAR EL ESTADO
  # --------------------------------------------------

  @impl true
  def init(:ok) do
    with {:ok, recursos} <- PersistenciaRecursos.cargar(),
         {:ok, necesidades} <- PersistenciaNecesidades.cargar() do
      estado = %{
        recursos: recursos,
        necesidades: necesidades
      }

      {:ok, estado}
    else
      {:error, razon} ->
        {:stop, razon}
    end
  end

  # --------------------------------------------------
  # FUNCIONES PUBLICAS
  # --------------------------------------------------

  def asignar_recurso(codigo_recurso, id_necesidad, cantidad) do
    GenServer.call(
      __MODULE__,
      {:asignar_recurso, codigo_recurso, id_necesidad, cantidad}
    )
  end

  def consultar_estado do
    GenServer.call(__MODULE__, :consultar_estado)
  end

  def recargar do
    GenServer.call(__MODULE__, :recargar)
  end

  # --------------------------------------------------
  # PROCESAR ASIGNACION
  # --------------------------------------------------

  @impl true
  def handle_call(
        {:asignar_recurso, codigo_recurso, id_necesidad, cantidad},
        _from,
        estado
      ) do
    resultado =
      Recursos.asignar_recurso(
        estado.recursos,
        estado.necesidades,
        codigo_recurso,
        id_necesidad,
        cantidad
      )

    case resultado do
      {:ok, recursos_actualizados, necesidades_actualizadas} ->
        nuevo_estado = %{
          recursos: recursos_actualizados,
          necesidades: necesidades_actualizadas
        }

        {:reply, resultado, nuevo_estado}

      {:error, razon} ->
        {:reply, {:error, razon}, estado}
    end
  end

  # --------------------------------------------------
  # CONSULTAR ESTADO
  # --------------------------------------------------

  @impl true
  def handle_call(:consultar_estado, _from, estado) do
    {:reply, estado, estado}
  end

  # --------------------------------------------------
  # RECARGAR DATOS
  # --------------------------------------------------

  @impl true
  def handle_call(:recargar, _from, estado) do
    with {:ok, recursos} <- PersistenciaRecursos.cargar(),
         {:ok, necesidades} <- PersistenciaNecesidades.cargar() do
      nuevo_estado = %{
        recursos: recursos,
        necesidades: necesidades
      }

      {:reply, {:ok, nuevo_estado}, nuevo_estado}
    else
      {:error, razon} ->
        {:reply, {:error, razon}, estado}
    end
  end
end
