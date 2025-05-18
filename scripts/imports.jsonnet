function(pwd, imports=importstr '/dev/stdin')
  local importlines(statement) =
    std.filterMap(
      function(imp)
        imp != '',
      function(imp)
        local relative = imp[std.length(pwd) + 1:];
        "'%s': %s '%s'," % [relative, statement, relative],
      std.split(imports, '\n'),
    );

  std.lines(
    ['{']
    + ['imports: {']
    + importlines('importstr')
    + ['},']
    + ['importbins: {']
    + importlines('importbin')
    + ['},']
    + ['}']
  )
