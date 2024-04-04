[
  15,
  1.5,
  -1.5,
  1e5,
  1E5,
  1.5e5,
  1.5E5,
  1.5e-5,
  1.5E+5,

  //15e5garbage, // lexer splits into NUMBER and IDENTIFIER, fails on parsing
  //15e,  // asserts with junk after 'e'
  //1garbag5e5garbage,// lexer splits into NUMBER and IDENTIFIER, fails on parsing
  //1.,  // asserts with junk after '.'

  garbage15e5garbage,  // is IDENTIFIER
  //+, // is OPERATOR, fails on parsing
  +1E5,  // lexer splits into OPERATOR and NUMBER, valid jsonnet
  //.5, // lexer splits into SYMBOL and NUMBER, fails on parsing
  E5,  // is IDENTIFIER
  e5,  // is IDENTIFIER

]
