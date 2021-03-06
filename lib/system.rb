# Copyright (c) 2013-2014 SUSE LLC
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of version 3 of the GNU General Public License as
# published by the Free Software Foundation.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.   See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, contact SUSE LLC.
#
# To contact SUSE about this file by physical or electronic mail,
# you may find current contact information at www.suse.com

# System and its subclasses are used to represent systems that are to be
# inspected.
#
# It abstracts common inspection tasks that need to be run, like executing
# commands or running "kiwi --describe". Different implementations, e.g. for
# local or ssh-accessed systems are done in the according subclasses.
class System
  abstract_method :requires_root?
  abstract_method :run_command
  abstract_method :kiwi_describe
  abstract_method :retrieve_files
  abstract_method :read_file

  def self.for(host)
    if host && host != "localhost"
      RemoteSystem.new(host)
    else
      LocalSystem.new
    end
  end

  # checks if the required command can be executed on the target system
  def check_requirement(command, *args)
    begin
      run_command(command, *args)
    rescue Cheetah::ExecutionFailed
      raise Machinery::Errors::MissingRequirement.new(
        "Need binary '#{command}' to be available on the inspected system."
      )
    end
  end

  # Retrieves files specified in filelist from the remote system and create an archive.
  # To be able to deal with arbitrary filenames we use zero-terminated
  # filelist and the --null option of tar
  def create_archive(filelist, archive, exclude = [])
    created = !File.exists?(archive)
    out = File.open(archive, "w")
    begin
      run_command(
        "tar", "--directory=/", "--create", "--gzip", "--null", "--files-from=-",
        *exclude.flat_map { |f| ["--exclude", f]},
        :stdout => out,
        :stdin => filelist
      )
    rescue Cheetah::ExecutionFailed => e
      if e.status.exitstatus == 1
        # The tarball has been created successfully but some files were changed
        # on disk while being archived, so we just log the warning and go on
        Machinery.logger.info e.stderr
      else
        raise
      end
    end
    out.close
    File.chmod(0600, archive) if created
  end

  def run_script(*args)
    script = File.read(File.join(Machinery::ROOT, "helpers", args.shift))

    run_command("bash", "-c", script, *args)
  end
end
