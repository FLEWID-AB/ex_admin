defmodule ExAdmin.Repo do
  @moduledoc false
  require Logger

  def repo(resource \\ nil) do
    repo = Application.get_env(:ex_admin, :repo)
    case resource do
      nil -> repo
      _ -> get_repo_for_resource(resource, repo)
    end
  end

  defp get_repo_for_resource(resource, default_repo) do
    case Application.get_env(:ex_admin, :custom_repos) do
      nil -> default_repo
      list -> case Enum.find(list, fn({res, _rep}) -> res == resource end) do
        nil -> default_repo
        {_res, rep} -> rep
      end
    end
  end
    

  def get_assoc_join_model(resource, field) when is_binary(field) do
    get_assoc_join_model(resource, String.to_atom(field))
  end

  def get_assoc_join_model(resource, field) do
    res_model = resource.__struct__
    case res_model.__schema__(:association, field) do
      %Ecto.Association.ManyToMany{queryable: queryable, join_through: join_through} ->
        {:ok, {join_through, queryable, :many_to_many}}
      %Ecto.Association.Has{queryable: queryable} ->
        {:ok, queryable}
      %{through: [first, second]} ->
        {:ok, {res_model.__schema__(:association, first).related, second}}
      _ ->
        {:error, :notfound}
    end
  end

  def get_assoc_model(resource, field) when is_binary(field) do
    get_assoc_model resource, String.to_atom(field)
  end

  def get_assoc_model(resource, field) do
    case get_assoc_join_model(resource, field) do
      {:ok, {assoc, _second, :many_to_many}} ->
        {assoc, assoc}
      {:ok, {assoc, second}} ->
        {assoc.__schema__(:association, second).related, assoc}
      {:ok, assoc_model} ->
        {assoc_model, field}
      error ->
        error
    end
  end

  def delete(resource, _params, resource \\ nil) do
    repo(resource).delete resource
  end

  # V2
  #
  def insert(changeset, resource \\ nil) do
    repo(resource).insert(changeset)
  end

  def update(changeset, resource \\ nil) do
    repo(resource).update(changeset)
  end
end
