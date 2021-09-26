/*	Definition section */
%{
    #include "common.h" //Extern variables that communicate with lex
    // #define YYDEBUG 1
    // int yydebug = 1;

    extern int yylineno;
    extern int yylex();
    extern FILE *yyin;

    typedef struct SymbolEntry{
        int index;
        char *name;
        char *type;
        int address;
        int LineNo;
        char *elementType;
        struct SymbolEntry *next;
    }entry;

    typedef struct SymbolTable{
        int scopeLev;
        struct SymbolTable *prev;
        struct SymbolTable *next;
        entry *firstEntry;
        entry *lastEntry;
    }table;

    int scopeLevel = 0;
    int address = 0;
    bool isLiteral = false;
    bool isLiteralError = false;
    table *firstTable = NULL;
    table *lastTable = NULL;
    entry *curEntry = NULL;
    

    void yyerror (char const *s)
    {
        printf("error:%d: %s\n", yylineno, s);
    }

    /* Symbol table function - you can add new function if needed. */
    static void create_symbol(/* ... */){
        table *newTable = malloc(sizeof(table));

        if(firstTable == NULL){
            newTable->scopeLev = scopeLevel;
            newTable->prev = NULL;
            newTable->firstEntry = NULL;
            newTable->next = NULL;
            firstTable = newTable;
            lastTable = newTable;
        }else{
            lastTable->next = newTable;
            newTable->prev = lastTable;
            newTable->scopeLev = scopeLevel;
            newTable->firstEntry = NULL;
            newTable->next = NULL;
            lastTable = newTable;
        }
    }
    static void insert_symbol(char *varName, char *varType, char *elmType){
        //malloc a new enrty
        entry *newEntry = malloc(sizeof(entry));
        newEntry->index = malloc(sizeof(int));
        newEntry->name = malloc(sizeof(varName)+1);
        newEntry->type = malloc(sizeof(varType)+1);
        newEntry->address = malloc(sizeof(address));
        newEntry->LineNo = malloc(sizeof(yylineno));
        newEntry->elementType = malloc(sizeof(elmType)+1);

        //assign member value of new entry
        if(lastTable->firstEntry ==NULL){ //first entry of the table
            newEntry->index = 0;
            strcpy(newEntry->name, varName);
            strcpy(newEntry->type, varType);
            newEntry->address = address;
            newEntry->LineNo = yylineno;
            strcpy(newEntry->elementType, elmType);
            newEntry->next = NULL;
            lastTable->firstEntry = newEntry;
            lastTable->lastEntry = newEntry;
        }else{  //there are already entries in the table
            newEntry->index = lastTable->lastEntry->index + 1;
            strcpy(newEntry->name, varName);
            strcpy(newEntry->type, varType);
            newEntry->address = address;
            newEntry->LineNo = yylineno;
            strcpy(newEntry->elementType, elmType);
            newEntry->next = NULL;
            lastTable->lastEntry->next = newEntry;
            lastTable->lastEntry = newEntry;
        }
    }
    static bool lookup_symbol(char *varName, int mode){ //mode 0:find in all scope , mode1:find in current scope
        switch(mode){
            case 0:
                if(lastTable!=NULL){
                    for(table *tableItor = lastTable;tableItor!=NULL;tableItor = tableItor->prev){
                        if(tableItor->firstEntry!=NULL){
                            for(entry *entryItor = tableItor->firstEntry;entryItor!=NULL;entryItor = entryItor->next){
                                if(strcmp(entryItor->name,varName) == 0){
                                    curEntry = entryItor;
                                    return true;
                                }
                            }
                        }
                    }
                }
                return false;
                break;
            case 1:
                if(lastTable!=NULL){
                    if(lastTable->firstEntry!=NULL){
                        for(entry *entryItor = lastTable->firstEntry;entryItor!=NULL;entryItor = entryItor->next){
                            if(strcmp(entryItor->name,varName) == 0){
                                curEntry = entryItor;
                                return true;
                            }
                        }
                    }
                }
                return false;
                break;
        }
        return false;
    }
    void freeTable(){
        table *tmp = lastTable;
        if(lastTable->prev!=NULL){
            lastTable = lastTable->prev;
            lastTable->next = NULL;
        }
        if(tmp->firstEntry!=NULL){
            entry *tmpEntry = tmp->firstEntry;
            entry *tmpEntry2;
            while(tmpEntry->next!=NULL){
                tmpEntry2 = tmpEntry;
                tmpEntry = tmpEntry->next;
                printf("%-10d%-10s%-10s%-10d%-10d%s\n", tmpEntry2->index, tmpEntry2->name, tmpEntry2->type, tmpEntry2->address, tmpEntry2-> LineNo, tmpEntry2->elementType);
                free(tmpEntry2);
            }
            printf("%-10d%-10s%-10s%-10d%-10d%s\n", tmpEntry->index, tmpEntry->name, tmpEntry->type, tmpEntry->address, tmpEntry-> LineNo, tmpEntry->elementType);
            free(tmpEntry);
        }
        free(tmp);        
    }
    
    static void dump_symbol(/* ... */){
        printf("> Dump symbol table (scope level: %d)\n", scopeLevel);
        printf("%-10s%-10s%-10s%-10s%-10s%s\n", "Index", "Name", "Type", "Address", "Lineno", "Element type");
        freeTable();
    }
    
%}

%error-verbose

/* Use variable or self-defined structure to represent
 * nonterminal and token type
 */
%union {
    int i_val;
    float f_val;
    bool b_val;
    char *s_val;

    struct st{
        char *id_name;
        char *type_name;
        char *op_name;
    }ctr;
    
    /* ... */
}

/* Token without return */
%token INT FLOAT BOOL STRING
%token '+' '-' '*' '/' '%' '"' ';' 
%token INC DEC GTR LSS GEQ LEQ EQL NEQ ASSIGN 
%token ADD_ASSIGN SUB_ASSIGN MUL_ASSIGN QUO_ASSIGN REM_ASSIGN
%token AND OR NOT '(' ')' '[' ']' '{' '}' COMMA
%token PRINT RETURN IF ELSE FOR WHILE
%token CONTINUE BREAK VOID

/* Token with return, which need to sepcify type */
%token <i_val> INT_LIT
%token <f_val> FLOAT_LIT
%token <b_val> BOOL_LIT
%token <s_val> STRING_LIT
%token <ctr.id_name> IDENT

/* Nonterminal with return, which need to sepcify type */
%type <ctr.type_name> TypeName Type
%type <ctr.type_name> Expression UnaryExpr PrimaryExpr Operand Literal IndexExpr ConversionExpr Condition
%type <ctr.type_name> Expression2 Expression3 Expression4 Expression5 Expression6 
%type <ctr.op_name> cmp_op add_op mul_op binary_op unary_op assign_op

/* Yacc will start at this nonterminal */
%start Program

/* Grammar section */
%%

Program
    : StatementList
;

Expression
    : Expression OR Expression2 {
        if(strcmp($1, $3) != 0){
            printf("error:%d: invalid operation: (operator %s not defined on %s)\n", yylineno, "OR", strcmp($1,"bool")==0?$3:$1);
        }
        printf("%s\n", "OR");
    }
    | Expression2
;
Expression2
    : Expression2 AND Expression3 {
        if(strcmp($1, $3) != 0){
            printf("error:%d: invalid operation: (operator %s not defined on %s)\n", yylineno, "AND", strcmp($1,"bool")==0?$3:$1);
        }
        printf("%s\n", "AND");
    }
    | Expression3
;
Expression3
    : Expression3 cmp_op Expression4 { 
        $$ = "bool"; 
        printf("%s\n", $2);
    }
    | Expression4
;
Expression4
    : Expression4 add_op Expression5 {
        if(strcmp($1, $3) != 0){
            printf("error:%d: invalid operation: %s (mismatched types %s and %s)\n", yylineno, $2, $1, $3);
        }
        printf("%s\n", $2);
    }
    | Expression5
;
Expression5
    : Expression5 mul_op Expression6 {
        if(strcmp($1, $3) != 0){
            if(strcmp($2, "REM") == 0){
                printf("error:%d: invalid operation: (operator %s not defined on %s)\n", yylineno, $2, strcmp($1,"int")==0?$3:$1);
            }    
        }
        printf("%s\n", $2);
    }
    | Expression6
;
Expression6
    :  UnaryExpr { $$ = $1; }
;

UnaryExpr
    : PrimaryExpr { $$ = $1; }
    | unary_op UnaryExpr {
        printf("%s\n", $1);
        $$ = $2;
    }
;

binary_op
    : OR { $$ = "OR"; }
    | AND { $$ = "AND"; }
    | cmp_op { $$ = $1; }
    | add_op { $$ = $1; }
    | mul_op{ $$ = $1; }
;

cmp_op 
    : EQL { $$ = "EQL"; }
    | NEQ { $$ = "NEQ"; }
    | LSS { $$ = "LSS"; }
    | LEQ { $$ = "LEQ"; }
    | GTR { $$ = "GTR"; }
    | GEQ { $$ = "GEQ"; }
;

add_op 
    : '+' { $$ = "ADD"; }
    | '-' { $$ = "SUB"; }
;

mul_op 
    : '*' { $$ = "MUL"; }
    | '/' { $$ = "QUO"; }
    | '%' { $$ = "REM"; }
;

unary_op 
    : '+' { $$ = "POS"; }
    | '-' { $$ = "NEG"; }
    | NOT { $$ = "NOT"; }
;

PrimaryExpr 
    : Operand { $$ = $1; }
    | IndexExpr { $$ = $1; }
    | ConversionExpr { $$ = $1; }
;

Operand 
    : Literal { $$ = $1; }
    | IDENT {
        if(lookup_symbol($1,0)){
            printf("IDENT (name=%s, address=%d)\n", $1, curEntry->address);
            if(strcmp(curEntry->type,"array") == 0){
                $$ = curEntry->elementType;
            }else{
                $$ = curEntry->type;
            }
        }else{
            printf("error:%d: undefined: %s\n", yylineno, $1);
            $$ = "undefined";
        }
        isLiteral = false;
    }
    | '(' Expression ')' { $$ = $2; }
;

IndexExpr 
    : PrimaryExpr '[' Expression ']' { 
        $$ = $1; 
        isLiteral = false;
    }
;

ConversionExpr 
    : '(' Type ')' Expression {
        if(strcmp($2,"int") == 0){
            printf("F to I\n");
        }else if(strcmp($2,"float") == 0){
            printf("I to F\n");
        }
        $$ = $2;
    }
;

Type
    : TypeName { $$ = $1; }
;

TypeName
    : INT { $$ = "int"; }
    | FLOAT { $$ = "float"; }
    | STRING { $$ = "string"; }
    | BOOL { $$ = "bool"; }
;

Literal
    : INT_LIT {
        printf("INT_LIT %d\n", $<i_val>1);
        $$ = "int";
        isLiteral = true;
    }
    | FLOAT_LIT {
        printf("FLOAT_LIT %f\n", $<f_val>1);
        $$ = "float";
    }
    | BOOL_LIT {
        printf("%s\n", $1 ? "TRUE" : "FALSE");
        $$ = "bool";
    }
    | STRING_LIT {
        printf("STRING_LIT %s\n", $1);
        $$ = "string";
    }
;

Statement
    : DeclarationStmt
    | AssignmentStmt
    | IncDecStmt
    | ExpressionStmt
    | Block
    | IfStmt
    | WhileStmt
    | ForStmt
    | PrintStmt
;

ExpressionStmt
    : Expression ';'
;

DeclarationStmt 
    : Type IDENT ';' {
        if(lookup_symbol($2,1)){
            printf("error:%d: %s redeclared in this block. previous declaration at line %d\n", yylineno, $2, curEntry->LineNo);
        }else{
            insert_symbol($2, $1, "-");
            ++address;
            printf("> Insert {%s} into symbol table (scope level: %d)\n", $2, scopeLevel);
        }
    }
    | Type IDENT ASSIGN Expression ';' {
        if(lookup_symbol($2,1)){
            printf("error:%d: %s redeclared in this block. previous declaration at line %d\n", yylineno, $2, curEntry->LineNo);
        }else{
            insert_symbol($2, $1, "-");
            ++address;
            printf("> Insert {%s} into symbol table (scope level: %d)\n", $2, scopeLevel);
        }
    }
    | Type IDENT '[' Expression ']' ';' {
        if(lookup_symbol($2,1)){
            printf("error:%d: %s redeclared in this block. previous declaration at line %d\n", yylineno, $2, curEntry->LineNo);
        }else{
            insert_symbol($2, "array", $1);
            ++address;
            printf("> Insert {%s} into symbol table (scope level: %d)\n", $2, scopeLevel);
        }
    }
;

AssignmentExpr 
    : Expression  assign_op {
            if(strcmp($1, "int") == 0 && isLiteral){
                isLiteralError = true;
                isLiteral = false;
        }
        }
        Expression {
            if(strcmp($1,"undefined") != 0 && strcmp($1, $4) != 0){
                printf("error:%d: invalid operation: %s (mismatched types %s and %s)\n", yylineno, $2, $1, $4);
            }
            if(isLiteralError){
                printf("error:%d: cannot assign to int\n", yylineno);
                isLiteralError = false;
            }
            printf("%s\n",$2);
        }
;

AssignmentStmt 
    : AssignmentExpr ';'
;

assign_op 
    : ASSIGN { $$ = "ASSIGN";}
    | ADD_ASSIGN { $$ = "ADD_ASSIGN";}
    | SUB_ASSIGN { $$ = "SUB_ASSIGN";}
    | MUL_ASSIGN { $$ = "MUL_ASSIGN";}
    | QUO_ASSIGN { $$ = "QUO_ASSIGN";}
    | REM_ASSIGN { $$ = "REM_ASSIGN";}
;

IncDecExpr 
    : Expression INC {
        printf("INC\n");
    }
    | Expression DEC {
        printf("DEC\n");
    }
;

IncDecStmt 
    : IncDecExpr ';'
;

Block 
    : '{' {
        ++scopeLevel;
        create_symbol();
    } StatementList '}' {
        dump_symbol();
        --scopeLevel;
    }
;

StatementList 
    : Statement StatementList
    | 
;

IfStmt 
    : IF Condition Block ElseStmt 
;

ElseStmt
    : ELSE IfStmt
    | ELSE Block
    |
;

Condition 
    : Expression { 
        $$ = $1;
        if(strcmp($1,"bool")!=0){
            printf("error:%d: non-bool (type %s) used as for condition\n", yylineno+1, $1);
        }
    }
;

WhileStmt 
    : WHILE '(' Condition ')' Block 
;

ForStmt 
    : FOR '(' ForClause ')' Block
;

ForClause 
    : InitStmt ';' Condition ';' PostStmt 
;

InitStmt 
    : SimpleExpr
;

PostStmt 
    : SimpleExpr
;

SimpleExpr 
    : AssignmentExpr 
    | Expression 
    | IncDecExpr
;

PrintStmt 
    : PRINT '(' Expression ')' ';'{
        printf("PRINT %s\n", $3);
    }
;


%%

/* C code section */
int main(int argc, char *argv[])
{
    if (argc == 2) {
        yyin = fopen(argv[1], "r");
    } else {
        yyin = stdin;
    }

    create_symbol();
    yyparse();
    dump_symbol();

	printf("Total lines: %d\n", yylineno);
    fclose(yyin);
    return 0;
}