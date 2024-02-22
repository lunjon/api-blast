defmodule Blast.CLI.Parser do
  @workers 1
  @frequency 1

  @help """
  blast - load test HTTP APIs

  Options:
    -s/--blast-file           File path to blast file. Must exist.
                              (default: looks for blast.y[a]ml in cwd)
    -w/--workers N            Number of concurrent workers to run.
                              (default: #{@workers})
    -f/--frequency N          Sets the frequency of requests per worker. To limit the total
                              request frequency use `--workers 1 --frequency N`.
                              A value of 0 means no limit. (default: #{@frequency})
    --hooks FILE              Load an elixir file (.ex) as hooks module.
    --repl                    Start in REPL mode.
    -v/--verbose              Output logs. (default: false)
    --help                    Display this help message.
  """

  def parse_args(args) do
    OptionParser.parse(args,
      strict: [
        specfile: :string,
        workers: :integer,
        frequency: :integer,
        duration: :integer,
        verbose: :boolean,
        hooks: :string,
        repl: :boolean,
        help: :boolean
      ],
      aliases: [
        s: :specfile,
        w: :workers,
        f: :frequency,
        v: :verbose,
        h: :help
      ]
    )
    |> handle_parsed_args()
  end

  defp handle_parsed_args({args, [], []}) do
    if Keyword.get(args, :help) do
      {:help, @help}
    else
      with {:ok, spec} <- parse_specfile(Keyword.get(args, :specfile)),
           {:ok, hook_file} <- parse_hook_file(Keyword.get(args, :hooks)) do
        args = %{
          spec: spec,
          hook_file: hook_file,
          workers: Keyword.get(args, :workers, @workers),
          frequency: Keyword.get(args, :frequency, 1),
          verbose: Keyword.get(args, :verbose, false),
          repl: Keyword.get(args, :repl, false)
        }

        {:ok, args}
      else
        err -> err
      end
    end
  end

  defp handle_parsed_args({_, _rest_args, invalid_args}) do
    invalid =
      invalid_args
      |> Enum.map(fn {arg, _} -> arg end)
      |> Enum.join(", ")

    {:error, "invalid arguments: #{invalid}"}
  end

  defp parse_specfile(nil) do
    cond do
      File.exists?("./blast.yaml") -> parse_blastfile("./blast.yaml")
      File.exists?("./blast.yml") -> parse_blastfile("./blast.yml")
      File.exists?("./test/blast.yml") -> parse_blastfile("./test/blast.yml")
      true -> {:error, "blastfile not found"}
    end
  end

  defp parse_blastfile(filepath) when is_binary(filepath), do: Blast.Spec.load_file(filepath)

  defp parse_hook_file(nil), do: {:ok, nil}

  defp parse_hook_file(filepath) do
    case File.exists?(filepath) do
      false -> {:error, "file not found: #{filepath}"}
      true -> {:ok, filepath}
    end
  end
end