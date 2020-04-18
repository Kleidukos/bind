defmodule UseBind do

  import Bind

  def check(password) do
    check_whitespaces(password)
    ~>> check_length
    ~>> common_password
  end

  @spec check_whitespaces(String.t) :: {:ok, String.t} | {:error, String.t}
  def check_whitespaces(password) do
    trimed_pass = String.trim(password)
    if trimed_pass == "" do
      {:error, "Empty password"}
    else
      {:ok, trimed_pass}
    end
  end

  @spec check_length(String.t) :: {:ok, String.t} | {:error, String.t}
  def check_length(password) do
    if String.length(password) > 5 do
      {:ok, password}
    else
      {:error, "Password length should be greater than 5 characters!"}
    end
  end

  @spec common_password(String.t) :: {:ok, String.t} | {:error, String.t}
  def common_password(password) do
    if password in ["hunter2", "lmao", "pony", "qwerty"] do
      {:error, "Password is too common!!"}
    else
      {:ok, password}
    end
  end
end
