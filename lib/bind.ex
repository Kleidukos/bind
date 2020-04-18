defmodule Bind do

  alias Code.Identifier

  # Formerly
  # def {:ok, value}    ~>> f, do: f.(value)
  # def {:error, error} ~>> _, do: {:error, error}

  @typedoc "Abstract Syntax Tree (AST)"
  @type t :: input

  @typedoc "The inputs of a macro"
  @type input ::
          input_expr
          | {input, input}
          | [input]
          | atom
          | number
          | binary

  @type metadata :: keyword

  @typep input_expr :: {input_expr | atom, metadata, atom | [input]}

  @spec unbind(t()) :: [t()]
  def unbind(expr) do
    :lists.reverse(unbind(expr, []))
  end

  defp unbind({:~>>, _, [left, right]}, acc) do
    unbind(right, unbind(left, acc))
  end

  defp unbind(other, acc) do
    [{other, 0} | acc]
  end


  @doc """
  Binds `expr` into the `call_args` at the given `position`.
  """
  @spec bind(t(), t(), integer) :: t()
  def bind(expr, call_args, position)

  def bind(expr, {:&, _, _} = call_args, _integer) do
    raise ArgumentError, bad_bind(expr, call_args)
  end

  def bind(expr, {tuple_or_map, _, _} = call_args, _integer) when tuple_or_map in [:{}, :%{}] do
    raise ArgumentError, bad_bind(expr, call_args)
  end

  # Without this, `Macro |> Env == Macro.Env`.
  def bind(expr, {:__aliases__, _, _} = call_args, _integer) do
    raise ArgumentError, bad_bind(expr, call_args)
  end

  def bind(expr, {:<<>>, _, _} = call_args, _integer) do
    raise ArgumentError, bad_bind(expr, call_args)
  end

  def bind(expr, {unquote, _, []}, _integer) when unquote in [:unquote, :unquote_splicing] do
    raise ArgumentError,
          "cannot bind #{to_string(expr)} into the special form #{unquote}/1 " <>
            "since #{unquote}/1 is used to build the Elixir AST itself"
  end

  # {:fn, _, _} is what we get when we bind into an anonymous function without
  # calling it, for example, `:foo |> (fn x -> x end)`.
  def bind(expr, {:fn, _, _}, _integer) do
    raise ArgumentError,
          "cannot bind #{to_string(expr)} into an anonymous function without" <>
            " calling the function; use something like (fn ... end).() or" <>
            " define the anonymous function as a regular private function"
  end

  def bind(expr, {call, line, atom}, integer) when is_atom(atom) do
    {call, line, List.insert_at([], integer, expr)}
  end

  def bind(_expr, {op, _line, [arg]}, _integer) when op == :+ or op == :- do
    raise ArgumentError,
          "piping into a unary operator is not supported, please use the qualified name: " <>
            "Kernel.#{op}(#{to_string(arg)}), instead of #{op}#{to_string(arg)}"
  end

  def bind(expr, {op, line, args} = op_args, integer) when is_list(args) do
    cond do
      is_atom(op) and Identifier.unary_op(op) != :error ->
        raise ArgumentError,
              "cannot bind #{to_string(expr)} into #{to_string(op_args)}, " <>
                "the #{to_string(op)} operator can only take one argument"

      is_atom(op) and Identifier.binary_op(op) != :error ->
        raise ArgumentError,
              "cannot bind #{to_string(expr)} into #{to_string(op_args)}, " <>
                "the #{to_string(op)} operator can only take two arguments"

      true ->
        {op, line, List.insert_at(args, integer, expr)}
    end
  end

  def bind(expr, call_args, _integer) do
    raise ArgumentError, bad_bind(expr, call_args)
  end

  defp bad_bind(expr, call_args) do
    "cannot bind #{to_string(expr)} into #{to_string(call_args)}, " <>
      "can only bind into local calls foo(), remote calls Foo.bar() or anonymous function calls foo.()"
  end

  defmacro left ~>> right do
    [{h, _} | t] = unbind({:~>>, [], [left, right]})

    fun = fn {x, pos}, acc ->
      bind(acc, x, pos)
    end

    :lists.foldl(fun, h, t)
  end
end
