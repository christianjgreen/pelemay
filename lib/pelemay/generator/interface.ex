defmodule Pelemay.Generator.Interface do
  alias Pelemay.Db
  @nif_ex "priv/pelemay_nif.ex"

  def generate do
    funcs = generate_functions()

    str = """
    # This file was generated by Pelemay.Generator.Interface
    defmodule PelemayNif do
      @compile {:autoload, false}
      @on_load :load_nifs

      def load_nifs do
        :erlang.load_nif(Application.app_dir(:pelemay, "priv/libnif"), 0)
      end

    #{funcs}
    end
    """

    Application.app_dir(:pelemay, "priv")
    |> File.mkdir()

    Application.app_dir(:pelemay, @nif_ex)
    |> File.write(str)

    Application.app_dir(:pelemay, @nif_ex)
    |> Code.compile_file(Application.app_dir(:pelemay, "ebin"))

    Code.append_path(Application.app_dir(:pelemay, "ebin"))
  end

  defp generate_functions do
    Db.get_functions()
    |> Enum.map(&(&1 |> generate_function))
    |> List.to_string()
  end

  defp generate_function([func_info]) do
    %{
      nif_name: nif_name,
      module: _,
      function: _,
      arg_num: num,
      args: _,
      operators: _
    } = func_info

    args = generate_string_arguments(num)

    """
      def #{nif_name}(#{args}), do: raise "NIF #{nif_name}/#{num} not implemented"
    """
  end

  defp generate_string_arguments(num) do
    1..num
    |> Enum.reduce(
      "",
      fn
        x, "" -> "_arg#{x}"
        x, acc -> acc <> ", _arg#{x}"
      end
    )
  end
end
