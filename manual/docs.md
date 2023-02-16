## Documentation

In addition to manuals and reference sheets available per-game, printable documentation
can also be generated.  This documentation currently includes:

* Introduction to the system
* Game lists

In particiular, game lists are useful if you want others to be able to look through which
games to play while someone is playing a game or controlling the system.  Think of it like
a karaoke playlist.

To generate the documentation, you can use the following command(s):

```bash
bin/docs.sh build [/path/to/output_dir/]
bin/docs.sh build_intro [/path/to/output.pdf]
```

This will generate PDF files in the `docs/build` folder.
