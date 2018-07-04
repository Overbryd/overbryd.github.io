---
title: "Connecting Apis With Flow"
date: 2018-01-01T04:20:00+02:00
tags:
- Elixir
---

Build an API connector with `Flow`.

Say you need to consume events and act upon them. There are numerous services that fit this pattern.
A recent client of mine wanted just that. In this case it was an API connector, subscribing on events from AMQP, mapping the data to the target API structure and posting to it.

<!--more-->

Given the projects deadline and budget, I was tempted to be a little more defensive and have proper errors explaining when things go wrong. Besides full test coverage, of course.

I found Elixir `Flow` handling that just perfectly well.

## The flow must go on

Most of the examples building Elixir flows deal with the ad-hoc/scripting/console usage of Flow. By using `Flow.from_enumerable/1` you hook up a flow to some sort of enumerable and with `Enum.into/2` you can easily build a nice parallel processing engine.

Taking this a step further, as a _forever_ running application, `Flow.from_stage/1` and `Flow.start_link` are the way to go.

Here is a showcase of the processing pipeline module:

```
defmodule Pipeline do

  def start_link() do
    pipeline = Flow.from_stage(Pipeline.Dispatcher, max_demand: 100, stages: 10)
               |> flow
    Flow.start_link(pipeline, name: __MODULE__)
  end

  def flow(input) do
    input
    |> put(:item, &Poison.decode/1)
    |> put(:transformed, &transform/1)
    |> put(:response, &post/1)
    |> Flow.each(&report/1)
  end

  def transform(%{item: item}) do
    # returns {:ok, transformed} or {:error, ...}
    TargetApi.object_from_item(item)
  end
  
  def post(%{transformed: object}) do
    # also returns {:ok, ...} or {:error, ...}
    TargetApi.post(object)
  end
  
  def report({:ok, _state}), do: Logger.info("posted successfully")
  
  def report({:error, key, error, state}) do
    Logger.error("processing errored at #{key}: #{inspect error}, #{inspect state}")
  end
  
  defp put(flow, key, fun) do
    Flow.map(flow, fn
      {:ok, state} ->
        case fun.(state) do
          {:ok, result} -> {:ok, Map.put(state, key, result)}
          error -> {:error, key, error, state}
        end
      pass -> pass
    end)
  end

end
```

I hope you get the idea. There are two nice benefits coming out of this:

1. Testability
2. Error handling

### Testability

By having the input of the flow construction as an argument, the flow can be isolated in tests. There is no need to hook up or startup the `Pipeline.Dispatcher` GenStage. I use `Flow.from_enumerable/1` in my tests to provide input, and I append `Enum.into/2` to receive output from the pipeline.

My tests look like this:

```
defmodule PipelineTest do

  test "flow fails when provided invalid JSON" do
    assert {:error, :item, _error, _state} = run("not json")
  end

  def run(data) do
    [{:ok, data}]
    |> Flow.from_enumerable
    |> Pipeline.flow
    |> Enum.into([])
    |> List.first
  end
  
end
```

And since the pipeline itself mostly calls into other modules, most of the logic is already tested in the respective tests of these modules. And as long as these functions adhere to the `:ok`/`:error` tagged returns, the pipeline will deliver. More about that in the next section about error handling.

### Error handling

Looking at this flow, it acts as one state transformation. Each result is put in its own key, and can provide input for further actions.
This also acts as the protocol between functions that depend on the output of the previous. The return values can clearly being looked up. Errors can clearly be tracked back to where they occured.

But first, a small fundamental discussion about Elixir error handling.
It is quite a complex topic, mostly due to the fact that there are so many different ways to handle errors in Elixir.
First there is the let-it-crash mentality. Processes isolate the execution, and they stay unaffected by errors from other processes.
Then there is the very common `:ok`/`:error` construct, tagged return values that indicate whether the called function succeeded in its execution.

Over the course of Elixir development, you will have to pick and choose between them, or mix and match what is best for the users of your application.
In this case, my users are of two different kinds.

The first kind is the end user of the application, who should be affected the least by any malfunction. This user will never see any error output, since the whole pipeline is attached to a notification system that triggers events after he has interacted with the front-facing application. Worst case, this user will just never receive the intended consequences of his interaction.

The second kind are the developers of the front facing application. They are maintaining the application the user is interacting with, they are the ones responsible if something along the way fails and the principal users do not get what they want.

So thought mainly about the latter, the developers. I want them to quickly reason about any potential failures that might occur during processing.

I choose to implement `:ok`/`:error` for everything that I _expect_ to fail. The main promise there is to quickly get to know what went wrong how.

The second is, that severe crashes happen under supervision, and basic process isolation takes care of keeping the application running and restarts its parts. This good for any _unforeseen_ errors.

## Dispatcher

The ever running input provided to the pipeline is a queueing GenStage dispatching on demand.
In this case the AMQP consumer forwards incoming events to the Dispatcher like this:

```
Dispatcher.async_push(Pipeline.Dispatcher, {:ok, data})
```

For completeness sake, here is the implementation of a queueing GenStage producer, dispatching on demand:

```
defmodule Dispatcher do
  use GenStage

  def start_link(name) do
    GenStage.start_link(__MODULE__, nil, name: name, id: name)
  end

  def init(_) do
    {:producer, {Queue.new, 0}, dispatcher: GenStage.DemandDispatcher}
  end

  def async_push(name, event) do
    GenStage.cast(name, {:push, event})
  end

  def queue_size(name) do
    GenStage.call(name, :queue_size)
  end

  def handle_call(:queue_size, _from, {queue, _demand} = state) do
    {:reply, Queue.size(queue), [], state}
  end

  def handle_cast({:push, event}, {queue, demand}) do
    dispatch_events(Queue.put_front(queue, event), demand, [])
  end

  def handle_demand(incoming_demand, {queue, demand}) when incoming_demand > 0 do
    dispatch_events(queue, demand + incoming_demand, [])
  end

  defp dispatch_events(queue, demand, events) do
    with true <- demand > 0,
      {event, remaining_queue} <- Queue.pop(queue)
    do
      dispatch_events(remaining_queue, demand - 1, [event | events])
    else
      _ -> {:noreply, Enum.reverse(events), {queue, demand}}
    end
  end

end
```
