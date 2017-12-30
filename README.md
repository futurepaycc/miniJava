# The minijavac compiler

A compilation project for Thrid year students of IMT Atlantique (the former Telecom Bretagne)

## How to clone the project

Using `git clone`

```sh
git clone https://redmine-df.telecom-bretagne.eu/git/f2b304_compiler_cn
```

then input your Username and Password in the command prompt

## How to build the compiler

Using the shell script `build`

```sh
./build
```

or using `ocamlbuild` to build the compiler

```sh
ocamlbuild Main.byte
```

*Notes*
> The main file is `Main/Main.ml`, it should not be modified. It opens the given file,creates a lexing buffer, initializes the location and call the compile function of the module `Main/compile.ml`. It is this function that you should modify to call your parser.


## How to execute the compiler


Using the shell script `minijavac`

```sh
./minijavac <filename>
```

or using the following command to build and then execute the compiler on the given file named `<filename>`

```sh
ocamlbuild Main.byte -- <filename>
```

> By default, the program searches for file with the extension `.java` and append it to the given filename if
it does not end with it.

## How to test the Compiler

Using the shell script `test`

```sh
./test
```

it will execute `Main.byte` on all files in the directory `Evaluator`

## How to contribute the Project

If you are a team member of the project, please follow the [Working Standard](./WorkingStandard.md) to make appropriate contributions