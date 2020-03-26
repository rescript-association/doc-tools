# doc-tools

A toolset for Reason / OCaml related documentation generation


## Requirements

1. Clone [Bucklescript](https://github.com/BuckleScript/bucklescript) somewhere on your machine (for example at `~/projects/bucklescript`).
2. Follow the build instructions in [`CONTRIBUTING.md`](https://github.com/BuckleScript/bucklescript/blob/master/CONTRIBUTING.md) in the Bucklescript repository.
3. Install [esy](https://esy.sh) with `npm install -g esy`.


## Generate documentation from Bucklescript modules

Make sure you followed all the steps in the Requirements section first. Once that is done, you can build the `bs-doc` tool (this is a temporary name).

```
$ esy
```

And finally, run the tool to generate the documentation artefacts (_e.g._ JSON):

```
$ esy x -- bs-doc --output=_output --bs-project-dir=~/projects/bucklescript
```

This will generate JSON and odoc files in the `_output` folder. When regenerating the files, make sure to remove the previously created files.

For additional configuration options see:

```
$ esy x -- bs-doc --help
```


## Working on JSON generator

Currently the JSON generation is implemented in a [forked version of odoc](https://github.com/odis-labs/odoc).

To work with the JSON generator, clone the forked version of odoc on your machine and build it with esy `esy @ocaml-4.06`.

To use the modified version of odoc, you can update the `package.json` file in this repository to link to the cloned `odoc` folder.