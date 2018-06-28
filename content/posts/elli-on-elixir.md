---
title: "Elli on Elixir"
date: 2017-10-18T20:57:32+02:00
draft: true
---

In addition to the answers above, I would like to write up a complete guide on getting `knutin/elli` to work with Elixir.
The above answers are correct, but I needed some more information to get up and running in my new elixir project.

1. Implement a handler that has `@behaviour :elli_handler`

    This is your router/controller. A bare minimum example version of this looks like this:

        # lib/elli_handler.ex
        defmodule ElliHandler do
          @behaviour :elli_handler
          alias :elli_request, as: Request
        
          def handle(req, args) do
            handle(Request.method(req), Request.path(req), req, args)
          end
        
          def handle(:GET, _, req, args) do
            # do something with the request.
            # e.g. you can use Request.get_arg/2 to fetch a query param
            say = Request.get_arg("say", req)
            # Return a tuple with 3 elements
            # status code, list of header tuples, response body
            {200, [], "echo, #{say}"}
          end
        
          # Here you can react to all kinds of events of the full connection/request/response cycle
          # You must implement this, otherwise elli wont function properly, as it evaluates
          # the return value of handle_event/3.
          def handle_event(event, args, config) do
            # Here would be a good point to handle logging.
            # IO.inspect([event, args, config])
            :ok
          end
        
        end

2. Lets use an app that starts an elli supervisor

        # lib/elli_supervisor.ex
        defmodule ElliSupervisor do
          use Supervisor

          def start_link(ref, options) do
            Supervisor.start_link(__MODULE__, options, name: ref)
          end

          def init(options) do
            children = [
              worker(:elli, [options], id: :elli_http_server)
            ]
            supervise(children, strategy: :one_for_one)
          end

          def shutdown(ref) do
            case Supervisor.terminate_child(ref, :elli_http_server) do
              :ok -> Supervisor.delete_child(ref, :elli_http_server)
              err -> err
            end
          end
        end

        # lib/app.ex
        defmodule App do
          use Application

          def start(_type, _args) do
            import Supervisor.Spec, warn: false
            # lets start our elli supervisor, setting its options
            # callback should be set to the elli handler that implements the elli_handler behaviour
            # port will be the port elli is listening on, defaults to 8080
            ElliSupervisor.start_link(__MODULE__, callback: ElliHandler, port: 3000)
          end

        end

        # in mix.exs
        def application do
          [
            mod: {App, []}
          ]
        end

3. Add elli as a dependency to your mix.exs

    Run `mix get.deps` to install your dependencies.
    Start your server with `mix run --no-halt` or in a console using `iex -S mix`.

        # in mix.exs
        defp deps do
          [
            # elli is our web server layer
            {:elli, github: "knutin/elli"}
          ]
        end

