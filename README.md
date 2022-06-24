A Python folding script which only folds functions and classes. Optionally, one can opt in to fold long list/dictionary/tuple literals or long import lists.

Requires `python3`, as it is based on a Python script to process the AST.

Can be installed with any plugin manager.

### Variables

- `g:pythonFoldCollectionLength` - defaults to `0`; if set to a number greater than 0, than all the multi-line lists/dictionaries/tuples literals with more than `g:pythonFoldCollectionLength` lines will have the inner content folded.
- `g:pythonFoldImportLength` - defaults to `0`; if set to a number greater than 0, than all the imports with more than `g:pythonFoldImportLength` lines will have the inner content folded.
