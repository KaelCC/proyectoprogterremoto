
defmodule Usuarios do

  # Ruta del archivo donde se almacenan los usuarios.
  @ruta Path.expand("../../priv/data/usuarios.txt", __DIR__)

  # Categorías permitidas para los usuarios.
  @categorias [
    "ciudadano",
    "voluntario",
    "coordinador",
    "administrador"
  ]

  # --------------------------------------------------
  # BUSCAR USUARIOS
  # --------------------------------------------------

  def buscar_usuarios(usuarios, nombre_usuario) do
    Enum.find(usuarios, fn usuario ->
      usuario.nombreUsuario == nombre_usuario
    end)
  end

  # --------------------------------------------------
  # CARGAR USUARIOS
  # --------------------------------------------------

  def cargar_usuarios() do

    # Crear el directorio si todavía no existe.
    File.mkdir_p!(Path.dirname(@ruta))

    # Crear el archivo si todavía no existe.
    unless File.exists?(@ruta) do
      File.write!(@ruta, "")
    end

    # Leer y transformar las líneas del archivo.
    resultado =
      @ruta
      |> File.stream!()
      |> Stream.map(&String.trim/1)
      |> Stream.reject(&(&1 == ""))
      |> Enum.reduce_while({:ok, []}, fn linea, {:ok, usuarios} ->

        case String.split(linea, ";") do

          [user, password, name, type, location] ->

            categoria = String.downcase(type)

            if categoria in @categorias do

              usuario = %Usuario{
                nombreUsuario: user,
                contraseña: password,
                nombre: name,
                categoria: categoria,
                ubicacion: location
              }

              {:cont, {:ok, [usuario | usuarios]}}

            else

              {:halt, {:error, "Categoría no válida en usuarios.txt: #{type}"}}

            end

          _ ->
            {:halt, {:error, "Línea incorrecta en usuarios.txt: #{linea}"}}

        end

      end)

    case resultado do

      {:ok, usuarios} ->
        {:ok, Enum.reverse(usuarios)}

      {:error, razon} ->
        {:error, razon}

    end

  end

  # --------------------------------------------------
  # VALIDAR CREDENCIALES
  # --------------------------------------------------

  def validar(usuarios, nombre_usuario, contraseña) do

    # Comprobar que las credenciales no estén vacías.
    if String.trim(nombre_usuario) == "" or String.trim(contraseña) == "" do

      {:error, "El usuario y la contraseña son obligatorios."}

    else

      case buscar_usuarios(usuarios, nombre_usuario) do

        nil ->
          {:error, "El usuario no está registrado."}

        usuario ->

          if usuario.contraseña == contraseña do

            IO.puts("\nInicio de sesión exitoso.")

            {:ok, usuario}

          else

            {:error, "La contraseña no coincide."}

          end

      end

    end

  end

  # --------------------------------------------------
  # REGISTRAR USUARIOS
  # --------------------------------------------------

  def registrar_usuario(usuarios, nombre_usuario, contraseña) do

    nombre_usuario = String.trim(nombre_usuario)
    contraseña = String.trim(contraseña)

    # Comprobar que las credenciales no estén vacías.
    if nombre_usuario == "" or contraseña == "" do

      {:error, "El usuario y la contraseña no pueden estar vacíos."}

    else

      # Comprobar si el usuario ya existe.
      case buscar_usuarios(usuarios, nombre_usuario) do

        nil ->

          IO.puts("\n--- DATOS DEL REGISTRO ---")
          IO.puts("Usuario: #{nombre_usuario}")

          nombre =
            IO.gets("Ingrese su nombre completo: ")
            |> String.trim()

          ubicacion =
            IO.gets("Ingrese su ubicación: ")
            |> String.trim()

          # Determinar el rol del usuario.
          categoria =
            if usuarios == [] do

              "administrador"

            else

              seleccionar_categoria()

            end

          # Validar los datos personales y el rol.
          if nombre == "" or ubicacion == "" do

            {:error, "El nombre y la ubicación son obligatorios."}

          else

            if categoria == nil do

              {:error, "No se seleccionó una categoría válida."}

            else

              # Crear el nuevo usuario.
              nuevo_usuario = %Usuario{
                nombreUsuario: nombre_usuario,
                contraseña: contraseña,
                nombre: nombre,
                categoria: categoria,
                ubicacion: ubicacion
              }

              # Preparar los datos para guardarlos.
              datos =
                "#{nombre_usuario};#{contraseña};#{nombre};#{categoria};#{ubicacion}\n"

              # Guardar el usuario en el archivo.
              case File.write(@ruta, datos, [:append]) do

                :ok ->

                  IO.puts("\nUsuario registrado correctamente.")
                  IO.puts("Rol asignado: #{String.upcase(categoria)}")

                  nuevos_usuarios = usuarios ++ [nuevo_usuario]

                  {:ok, nuevo_usuario, nuevos_usuarios}

                {:error, razon} ->

                  {:error, "No se pudo guardar el usuario: #{inspect(razon)}"}

              end

            end

          end

        _ ->

          {:error, "Ese nombre de usuario ya está registrado."}

      end

    end

  end

  # --------------------------------------------------
  # SELECCIONAR CATEGORÍA
  # --------------------------------------------------

  defp seleccionar_categoria() do

    IO.puts("\nSeleccione el rol que desea utilizar:")
    IO.puts("1. Ciudadano")
    IO.puts("2. Voluntario")
    IO.puts("3. Coordinador")

    opcion =
      IO.gets("Seleccione una opción: ")
      |> String.trim()

    case opcion do

      "1" ->
        "ciudadano"

      "2" ->
        "voluntario"

      "3" ->
        "coordinador"

      _ ->
        IO.puts("\nOpción no válida.")
        nil

    end

  end

end
