parser grammar CubexParser;
options { tokenVocab = CubexLexer; }

vname returns [CubexVName cu]
	: NAME { $cu =  new CubexVName($NAME.text); };

cname returns [CubexCName cu]
	: CLASSNAME { $cu =  new CubexCName($CLASSNAME.text); };

pname returns [CubexPName cu]
	: TYPEPARAM { $cu =  new CubexPName($TYPEPARAM.text); };

vcname returns [CubexName cu]
	: c=cname {$cu = $c.cu;}
	| v=vname {$cu = $v.cu;};

kcont returns [List<CubexPName> cu]
    : {
        $cu = new ArrayList<CubexPName>();
      }
    (p=pname { $cu.add($p.cu); }
      (COMMA p=pname { $cu.add($p.cu); })*
    )?;

tcont returns [CubexTypeContext cu]
    : {
        $cu = new CubexTypeContext();
      }
    (v=vname COLON t=type { $cu.add($v.cu, $t.cu); }
      (COMMA v=vname COLON t=type { $cu.add($v.cu, $t.cu); })*
    )?;

type returns [CubexType cu]
  : THING { $cu = new Thing(); }
  | NOTHING { $cu = new Nothing(); }
	| p=pname { $cu = new CubexPType($p.cu); }
	| c=cname LANGLE t=types RANGLE
		{ $cu = new CubexCType($c.cu, $t.cu); }

	// type with no params
	| c=cname {
		List<CubexType> t = new ArrayList<CubexType>();
	 	$cu = new CubexCType($c.cu, t);
	}

	| t1=type AND t2=type { $cu = new CubexIType($t1.cu, $t2.cu); };

types returns [List<CubexType> cu]
    : {
        $cu = new ArrayList<CubexType>();
      }
  (t=type { $cu.add($t.cu); }
    (COMMA t=type { $cu.add($t.cu); })*
  )?;

typescheme returns [CubexTypeScheme cu]
	: LANGLE k=kcont RANGLE LPAREN tc=tcont RPAREN COLON t=type
		{ $cu = new CubexTypeScheme($k.cu, $tc.cu, $t.cu); }
	// empty type list
	| LPAREN tc=tcont RPAREN COLON t=type {
		ArrayList<CubexPName> kc = new ArrayList<CubexPName>();
		$cu = new CubexTypeScheme(kc, $tc.cu, $t.cu);
	};

// comprehension returns [CubexComprehensionable cu]
//  : e=expr {$cu = new CubexExprComp($e.cu, null); }
//  (COMMA c=comprehension {$cu = new CubexExprComp($e.cu, $c.cu);})?
//  | IF LPAREN e2=expr RPAREN c2=comprehension {
//      $cu = new CubexIfComp($e2.cu, $c2.cu); }
//  | FOR LPAREN n=vname IN e3=expr RPAREN c3=comprehension {
//      $cu = new CubexForComp($n.cu, $e3.cu, $c3.cu); }
//  | /* epsilon */ {$cu = null;};

expr returns [CubexExpression cu]
    : n=vname { $cu = new CubexVar($n.cu); }
    | c=vcname LANGLE t=types RANGLE LPAREN es=exprs RPAREN
    	{ $cu = new CubexFunctionCall($c.cu, $t.cu, $es.cu); }
    | e=expr DOT n=vname LANGLE t=types RANGLE LPAREN es=exprs RPAREN
    	{ $cu = new CubexMethodCall($e.cu, $n.cu, $t.cu, $es.cu); }
    | LSQUARE elems=exprs RSQUARE {
        $cu = new CubexIterable($elems.cu);
      }
    | BOOL { $cu = new CubexBoolean($BOOL.text); }
    | INT { $cu = new CubexInt($INT.int); }
    | STRING { $cu = new CubexString($STRING.text); }
    // function call with no types
    | c=vcname LPAREN es=exprs RPAREN {
    	List<CubexType> t = new ArrayList<CubexType>();
    	$cu = new CubexFunctionCall($c.cu, t, $es.cu);
    	}
    // method call with no types
	| e=expr DOT n=vname LPAREN es=exprs RPAREN {
		ArrayList<CubexType> t = new ArrayList<CubexType>();
		$cu = new CubexMethodCall($e.cu, $n.cu, t, $es.cu);
		}
    // unary prefixes
    | tok=(MINUS | NEGATE)  e=expr { $cu = new CubexMethodCall($e.cu, $tok);}

    // binary operators
    | e1=expr tok=(DIVIDE | TIMES | MODULO) e2=expr { $cu = new CubexMethodCall($e1.cu, $tok, $e2.cu); }
    | e1=expr tok=(PLUS | MINUS) e2=expr { $cu = new CubexMethodCall($e1.cu, $tok, $e2.cu); }
    // range operators
    | e1=expr tok=(STRICTSTRICTBINOP | STRICTOPENBINOP | OPENSTRICTBINOP | OPENOPENBINOP) e2=expr { $cu = new CubexMethodCall($e1.cu, $tok, $e2.cu); }
    | e1=expr tok=(OPENONWARDSUNARYOP | STRICTONWARDSUNARYOP) { $cu = new CubexMethodCall($e1.cu, $tok); }

    // append operator (here for precedence)
    | l=expr PLUSPLUS r=expr { $cu = new CubexAppend($l.cu, $r.cu); }

    // inequality operators
    | e1=expr tok=(LANGLE | RANGLE | LTE | GTE) e2=expr { $cu = new CubexMethodCall($e1.cu, $tok, $e2.cu); }

    // equality operators
	| e1=expr tok=(EQ | NE) e2=expr { $cu = new CubexMethodCall($e1.cu, $tok, $e2.cu); }

	// boolean operators
	| e1=expr tok=(AND | OR) e2=expr { $cu = new CubexMethodCall($e1.cu, $tok, $e2.cu); }

	// parentheses (just forget about them, the tree does scoping)
	| LPAREN e=expr RPAREN  { $cu = $e.cu; };

exprs returns [List<CubexExpression> cu]
    : {
        $cu = new ArrayList<CubexExpression>();
      }
    (e=expr { $cu.add($e.cu); }
      (COMMA f=expr { $cu.add($f.cu); })*
    )?;

statement returns [CubexStatement cu]
	: LBRACE t=statement RBRACE
		{ $cu = $t.cu; }
	| LBRACE s=statements RBRACE
		{ $cu = new CubexBlock($s.cu); }
	| n=nbstatement { $cu = $n.cu;};

nbstatement returns [CubexStatement cu]
	: n=vname ASSIGN e1=expr SEMICOLON
		{ $cu = new CubexAssign($n.cu, $e1.cu); }
	// handle if without else
	| {CubexStatement el = new CubexBlock(new ArrayList<CubexStatement>());}
	IF LPAREN e2=expr RPAREN s1=statement
	(ELSE s2=statement {el = $s2.cu;})?
	{ $cu = new CubexConditional($e2.cu, $s1.cu, el); }

	| WHILE LPAREN e3=expr RPAREN s3=statement
		{ $cu = new CubexWhileLoop($e3.cu, $s3.cu); }
	| FOR LPAREN n=vname IN e4=expr RPAREN s4=statement
		{ $cu = new CubexForLoop($n.cu, $e4.cu, $s4.cu); }
	| RETURN e5=expr SEMICOLON
		{ $cu = new CubexReturn($e5.cu); };

statements returns [List<CubexStatement> cu]
    : { $cu = new ArrayList<CubexStatement>(); }
	    ((s=nbstatement { $cu.add($s.cu); } | t=bracestatement { $cu.addAll($t.cu); } )
	     ((s=nbstatement { $cu.add($s.cu); }) | t=bracestatement { $cu.addAll($t.cu); } )*
	    )?;

bracestatement returns [List<CubexStatement> cu]
	: LBRACE t=statements RBRACE
    {
      $cu = $t.cu;
    };

funheader returns [CubexFunHeader cu]
	: FUN v=vname t=typescheme
		{ $cu = new CubexFunHeader($v.cu, $t.cu); };

funheaders returns [List<CubexFunHeader> cu]
    : {
        $cu = new ArrayList<CubexFunHeader>();
      }
    (c=funheader SEMICOLON { $cu.add($c.cu); }
    | d=fundef { $cu.add($d.cu); })*;

fundef returns [CubexFunction cu]
	// overide with immediate return statement
	: FUN v=vname t=typescheme EQUAL e=expr SEMICOLON
	  {
      $cu = new CubexFunction($v.cu, $t.cu, $e.cu);
    }
	| FUN v=vname t=typescheme s=statement
		{
      $cu = new CubexFunction($v.cu, $t.cu, $s.cu);
    };

funsdef returns [List<CubexFunction> cu]
    : {
        $cu = new ArrayList<CubexFunction>();
      }
    (c=fundef { $cu.add($c.cu); })*;

interfacedef returns [CubexInterface cu]
	: {
      // no types
      List<CubexPName> kl = new ArrayList<CubexPName>();
		  // no extends
		  CubexType ct = CubexType.getThing();
    }
	INTERFACE c=cname
	(LANGLE k=kcont RANGLE { kl = $k.cu; })?
	(EXTENDS t=type { ct = $t.cu; })?
	LBRACE f=funheaders RBRACE
	{
    $cu = new CubexInterface($c.cu, kl, ct, $f.cu);
  };

classdef returns [CubexClass cu]
	: {
      // no types
      List<CubexPName> kl = new ArrayList<CubexPName>();
  		// no extends
  		CubexType ct = CubexType.getThing();
  		// no super
  		List<CubexExpression> es = new ArrayList<CubexExpression>();
    }
	CLASS c=cname
	(LANGLE k=kcont RANGLE { kl = $k.cu; })?
	LPAREN ty=tcont RPAREN
	(EXTENDS t=type { ct = $t.cu; })?
	LBRACE s=statements
	(SUPER LPAREN e=exprs RPAREN SEMICOLON { es = $e.cu;})?
	f=funsdef RBRACE
	{
    $cu = new CubexClass($c.cu, kl, $ty.cu, ct, $s.cu, es, $f.cu);
  };

// at least one, fixes left recursion
mutlifuns returns [List<CubexFunction> cu]
    : {
        $cu = new ArrayList<CubexFunction>();
      }
    (c=fundef { $cu.add($c.cu); })+;

multistatement returns [List<CubexStatement> cu]
    : { $cu = new ArrayList<CubexStatement>(); }
      ((s=nbstatement { $cu.add($s.cu); } | t=bracestatement { $cu.addAll($t.cu); } )
       ((s=nbstatement { $cu.add($s.cu); }) | t=bracestatement { $cu.addAll($t.cu); } )*
      );


almostprog returns [CubexProg cu]
	: s=multistatement p=almostprog { $cu = new CubexStatementsProg($s.cu, $p.cu); }
  | f=mutlifuns p=almostprog { $cu = new CubexFuncsProg($f.cu, $p.cu); }
  | i=interfacedef p=almostprog { $cu = new CubexInterfaceProg($i.cu, $p.cu); }
  | c=classdef p=almostprog { $cu = new CubexClassProg($c.cu, $p.cu); }
	| s2=statement { $cu = new CubexStatementProg($s2.cu); };

prog returns [CubexProg cu]
  : p=almostprog EOF{ $cu = $p.cu; }
  | errorchar { int n = 1 / 0; } ;

errorchar : .*?;
