defmodule BankAccount do
  @moduledoc """
  A bank account that supports access from multiple processes.
  """

  @typedoc """
  An account handle.
  """
  @opaque account :: pid

  @doc """
  Open the bank account, making it available for further operations.
  """
  use Agent
  @spec open() :: account
  def open() do
    {:ok, account} = Agent.start(fn -> 0 end)
    account
  end

  @doc """
  Close the bank account, making it unavailable for further operations.
  """
  @spec close(account) :: any
  def close(account) do
    Agent.stop(account)
  end

  @doc """
  Get the account's balance.
  """
  @spec balance(account) :: integer | {:error, :account_closed}
  def balance(account) do
    case is_account_active?(account) do
      :ok -> Agent.get(account, fn state -> state end)
      {:error, error} -> {:error, error}
    end

  end

  @doc """
  Add the given amount to the account's balance.
  """
  @spec deposit(account, integer) :: :ok | {:error, :account_closed | :amount_must_be_positive}
  def deposit(_account, amount) when amount < 0, do: {:error, :amount_must_be_positive}
  def deposit(account, amount) do
    case is_account_active?(account) do
      :ok -> Agent.update(account, fn state -> state + amount end)
      {:error, error} -> {:error, error}
    end

  end

  @doc """
  Subtract the given amount from the account's balance.
  """
  @spec withdraw(account, integer) ::
          :ok | {:error, :account_closed | :amount_must_be_positive | :not_enough_balance}
  def withdraw(_account, amount) when amount < 0, do: {:error, :amount_must_be_positive}
  def withdraw(account, amount) do
    case can_withdraw?(account, amount) do
      true -> Agent.update(account, fn state -> state - amount end)
      false -> {:error, :not_enough_balance}
      error -> error
    end

  end

  defp is_account_active?(account) do
    if Process.alive?(account) do
      :ok
    else
      {:error, :account_closed}
    end
  end

  defp can_withdraw?(account, amount) do
    case is_account_active?(account) do
      :ok -> balance(account) >= amount
      {:error, error} -> {:error, error}
    end
  end
end
