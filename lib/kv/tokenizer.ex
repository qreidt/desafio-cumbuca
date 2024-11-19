defmodule KV.Tokenizer do

  @spec tokenize(binary()) :: :err | list()
  def tokenize(input) do
    tokenize(input, false, false, "", [], false)
  end

  # Quando não houverem mais caracteres, adicionar token atual a lista de tokens,
  # retornar um erro ou uma lista de tokens, filtrando tokens vazios
  defp tokenize(<<>>, in_quotes, is_escaping, current_token, tokens, has_quotes) do
    if in_quotes or is_escaping do
      :err # Aspas não fechadas ou escapando vazio
    else

      # Garantir lógica de envolver tokens que utilizaram aspas
      new_token = if has_quotes, do: "\"#{current_token}\"", else: current_token

      (tokens ++ [new_token]) # Retornar tokens
       |> Enum.reject(&(&1 == "")) # Ignorar tokens vazios
    end
  end

  # Loop para tratar cada tipo novo de caracter na string, escapando aspas e delimitando inicio e fim dos tokens
  defp tokenize(<<char::utf8, rest::binary>>, in_quotes, is_escaping, current_token, tokens, has_quotes) do
    case {in_quotes, is_escaping, char} do
      # Escaping quotes
      {_, true, ?"} -> tokenize(rest, in_quotes, false, current_token <> <<char>>, tokens, has_quotes)
      {_, true, ?\\} -> tokenize(rest, in_quotes, false, current_token <> <<char>>, tokens, has_quotes)

      # Start quoted segment
      {false, _, ?"} -> tokenize(rest, true, false, current_token, tokens, String.length(current_token) == 0)

      # End quoted segment
      {true, _, ?"} -> tokenize(rest, false, false, current_token, tokens, has_quotes)

      # Escape in quotes
      {_, _, ?\\} -> tokenize(rest, in_quotes, true, current_token, tokens, has_quotes)

      # New token
      {false, _, ?\s} -> new_token(rest, in_quotes, is_escaping, current_token, tokens, has_quotes)

      # Add char to token
      {_, _, _} -> tokenize(rest, in_quotes, false, current_token <> <<char>>, tokens, has_quotes)
    end
  end

  # Adicionar o token a lista de tokens e iniciar um novo token
  # Caso o token tenha usado aspas, adicionar aspas novamente em volta do token
  defp new_token(rest, in_quotes, is_escaping, current_token, tokens, has_quotes) do
    if has_quotes do
      tokenize(rest, in_quotes, is_escaping, "", tokens ++ ["\"#{current_token}\""], false)
    else
      tokenize(rest, in_quotes, is_escaping, "", tokens ++ [current_token], false)
    end
  end
end
