  Contains the names and contents of all files which are not part of any RPM
  package. The list of unmanaged files contains only plain files and
  directories. Special files like device nodes, named pipes and Unix domain
  sockets are ignored. The directories `/tmp`,  `/var/tmp`, `/.snapshots/`,
  `/var/run` and special mounts like procfs and sysfs are ignored, too.
  If a directory is in this list, no file or directory below it belongs to a
  RPM package.

  Meta data information of unmanaged files is only available if the files were
  extracted during inspection.

  Using the `--extract-unmanaged-files` option, the files are transferred from
  the system and stored in the system description. Depending on the content of
  the inspected system, the amount of data stored may be huge.
