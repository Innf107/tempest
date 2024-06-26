#!/usr/bin/env polaris
options {
    "--editor" (editor = "code"): "the editor to open projects in"
    "--name" (name = ""): "the project's name. this will be randomly generated if left unset"
}

data Target = {
    initialize : { name : String } -> ()
}

let debug(message) = print("\e[35m[TEMPEST]\e[0m ${message}")

let tempName() = "temp${!bash "-c" "echo $RANDOM"}"

let initializeStack(project) = {
    !stack "new" (project.name)
    ()
}

let initializeDune(project) = {
    !dune "init" "proj" (project.name)
    # we build the project once so that ocamllsp works properly
    chdir(project.name)
    !dune "build"
    chdir("..")
    ()
}

let initializePolaris(project) = {
    !mkdir (project.name)
    !touch ("${project.name}/"~"${project.name}.pls")
    ()
}

let initializeGleam(project) = {
    !gleam "new" (project.name)
    ()
}

let initializeCargo(project) = {
    !cargo "init" (project.name)
    ()
}

let targetFor(targetName) = match targetName {
    "stack" ->
        Target({ initialize = initializeStack
               })
    "dune" ->
        Target({ initialize = initializeDune
               })
    "polaris" ->
        Target({ initialize = initializePolaris
               })
    "gleam" ->
        Target({ initialize = initializeGleam
               })
    "cargo" ->
        Target({ initialize = initializeCargo
               })
    targetName -> fail("invalid target: ${targetName}")
}

let main() = {
    let targetName = match getArgv() {
        [] | [_] -> fail("missing target")
        [_, targetName] -> targetName
        _ -> fail("too many arguments")
    }
    let target = targetFor(targetName)

    let projectName = match name {
        "" -> tempName()
        name -> name
    }

    let directoryPath = !mktemp "-d"

    debug("initializing ${targetName} project "~"\e[34m${projectName}\e[0m in "~"\e[34m${directoryPath}\e[0m")

    chdir(directoryPath)
    try {
        target!.initialize({ name = projectName })
        !env editor projectName
        ()
    } with {
        exception_ -> {
            debug("ERROR trying to initialize project: ${exceptionMessage(exception_)}. Cleaning up...")
            # TODO: cleanup?
            raise exception_
        }
    }
}
main()
