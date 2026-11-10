
defmodule Proyectoprog.Main do

  def main do
    IO.puts("\n====================================")
    IO.puts(" SISTEMA DE GESTIÓN DE EMERGENCIAS")
    IO.puts("====================================\n")

    # Cargar zonas
    case PersistenciaZonas.cargar() do
      {:ok, zonas} ->
        IO.puts("Zonas cargadas correctamente.")
        IO.inspect(zonas, label: "Zonas registradas")

        # Cargar necesidades
        case PersistenciaNecesidades.cargar() do
          {:ok, necesidades} ->
            IO.puts("\nNecesidades cargadas correctamente.")
            IO.inspect(necesidades, label: "Necesidades registradas")

            menu_prueba(zonas, necesidades)

          {:error, razon} ->
            IO.puts("Error al cargar necesidades: #{razon}")
        end

      {:error, razon} ->
        IO.puts("Error al cargar zonas: #{razon}")
    end
  end

  # Prueba de registro de una necesidad
  defp menu_prueba(zonas, necesidades) do
    IO.puts("\n====================================")
    IO.puts(" PRUEBA DE REGISTRO DE NECESIDADES")
    IO.puts("====================================")

    case Necesidades.registrar_necesidad(
           necesidades,
           zonas,
           "N001",
           "Agua",
           "Se necesitan botellas de agua potable.",
           500,
           "Z001",
           "critica",
           "coordinador1"
         ) do

      {:ok, nuevas_necesidades} ->
        IO.puts("\nNecesidad registrada y guardada correctamente.")
        IO.inspect(nuevas_necesidades)

      {:error, razon} ->
        IO.puts("\nNo se pudo registrar la necesidad: #{razon}")
    end
  end

end
