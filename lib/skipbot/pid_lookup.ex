defmodule Skipbot.PidLookup do
  def start_link do
    Agent.start_link(fn -> %{} end, name: Skipbot.PidLookup)
  end

  def get(uuid) do
    Agent.get(Skipbot.PidLookup, &Map.get(&1, uuid))
  end

  def put(uuid, pid) do
    Agent.update(Skipbot.PidLookup, &Map.put(&1, uuid, pid))
  end

  def delete(uuid) do
    Agent.update(Skipbot.PidLookup, &Map.delete(&1, uuid))
  end
end