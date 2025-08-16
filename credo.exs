%{
  configs: [
    %{
      name: "default",
      files: %{
        included: ["lib/", "src/", "web/", "apps/"],
        excluded: [
          ~r"/_build/",
          ~r"/deps/",
          ~r"/node_modules/",
          ~r"/priv/",
          ~r"/test/"
        ]
      },
      checks: [
        # Only enable a few essential checks
        {Credo.Check.Consistency.MultiAliasImportRequireUse, []},
        {Credo.Check.Consistency.UnusedVariableNames, []}
      ],
      strict: false
    }
  ]
}
