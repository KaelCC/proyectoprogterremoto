defmodule Usuarios do

  # Ruta del archivo donde se almacenan los usuarios.
  @ruta Path.expand("../../priv/data/usuarios.txt", __DIR__)

  # Categorías permitidas en el sistema.
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

            usuario = %Usuario{
              nombreUsuario: user,
              contraseña: password,
              nombre: name,
              categoria: type,
              ubicacion: location
            }

            {:cont, {:ok, [usuario | usuarios]}}

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

    case buscar_usuarios(usuarios, nombre_usuario) do

      nil ->
        IO.puts("El usuario no está registrado. Iniciando proceso de registro...")

        registrar_usuario(
          usuarios,
          nombre_usuario,
          contraseña
        )

      usuario ->

        if usuario.contraseña == contraseña do

          IO.puts("Inicio de sesión exitoso.")

          {:ok, usuario}

        else

          {:error, "La contraseña no coincide."}

        end

    end

  end

  # --------------------------------------------------
  # REGISTRAR USUARIOS
  # --------------------------------------------------

  def registrar_usuario(usuarios, nombre_usuario, contraseña) do

    # Comprobar que el nombre de usuario no esté vacío.
    if String.trim(nombre_usuario) == "" or String.trim(contraseña) == "" do

      {:error, "El usuario y la contraseña no pueden estar vacíos."}

    else

      # Comprobar si el usuario ya existe.
      case buscar_usuarios(usuarios, nombre_usuario) do

        nil ->

          IO.puts("""
          Se realizará un registro de usuario con los siguientes datos:

          Usuario: #{nombre_usuario}
          """)

          eleccion =
            IO.gets("""
            ¿Desea continuar con los datos o cambiar alguno?
            1. Continuar
            2. Cambiar credenciales
            """)
            |> String.trim()

          case eleccion do

            "1" ->

              nombre =
                IO.gets("Ingrese su nombre: ")
                |> String.trim()

              ubicacion =
                IO.gets("Ingrese su ubicación: ")
                |> String.trim()

              categoria =
                IO.gets("Ingrese su categoría: ")
                |> String.trim()
                |> String.downcase()

              # Validar que los campos no estén vacíos.
              if nombre == "" or ubicacion == "" do

                IO.puts("El nombre y la ubicación son obligatorios.")

                {:error, "Datos personales incompletos."}

              # Validar la categoría.
              else

                if categoria in @categorias do

                  nuevo_usuario = %Usuario{
                    nombreUsuario: nombre_usuario,
                    contraseña: contraseña,
                    nombre: nombre,
                    categoria: categoria,
                    ubicacion: ubicacion
                  }

                  # Guardar el usuario en el archivo.
                  datos =
                    "#{nombre_usuario};#{contraseña};#{nombre};#{categoria};#{ubicacion}\n"

                  case File.write(@ruta, datos, [:append]) do

                    :ok ->

                      IO.puts("Usuario registrado correctamente.")

                      nuevos_usuarios = [nuevo_usuario | usuarios]

                      {:ok, nuevo_usuario, nuevos_usuarios}

                    {:error, razon} ->

                      {:error, "No se pudo guardar el usuario: #{inspect(razon)}"}

                  end

                else

                  IO.puts("Categoría no válida.")
                  IO.puts("Categorías permitidas: #{Enum.join(@categorias, ", ")}")

                  {:error, "Categoría no permitida."}

                end

              end

            "2" ->

              nuevo_usuario =
                IO.gets("Ingrese el nuevo nombre de usuario: ")
                |> String.trim()

              nueva_contraseña =
                IO.gets("Ingrese la nueva contraseña: ")
                |> String.trim()

              registrar_usuario(
                usuarios,
                nuevo_usuario,
                nueva_contraseña
              )

            _ ->

              IO.puts("Opción inválida.")

              {:error, "Opción de registro no válida."}

          end

        _ ->

          {:error, "Ese nombre de usuario ya está registrado."}

      end

    end

  end

end

# --------------------------------------------------
# PRUEBAS
# --------------------------------------------------

case Usuarios.cargar_usuarios() do

  {:ok, usuarios} ->

    IO.inspect(usuarios, label: "Usuarios cargados")

    resultado =
      Usuarios.validar(
        usuarios,
        "kael",
        "1234"
      )

    IO.inspect(resultado, label: "Resultado")

  {:error, razon} ->

    IO.inspect(razon, label: "Error al cargar usuarios")

end
