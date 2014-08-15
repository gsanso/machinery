#  Copyright (c) 2013-2014 SUSE LLC
#
#  This program is free software; you can redistribute it and/or
#  modify it under the terms of version 3 of the GNU General Public License as
#  published by the Free Software Foundation.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.   See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program; if not, contact SUSE LLC.
#
#  To contact SUSE about this file by physical or electronic mail,
#  you may find current contact information at www.suse.com

shared_examples "build" do |distribution|
  describe "build" do
    before(:each) do
      @system_description_file = "spec/data/descriptions/#{distribution}-build/manifest.json"
      @system_description_dir = File.dirname(@system_description_file)
      @system_description = SystemDescription.from_json("original", File.read(@system_description_file))
    end

    it "builds a #{distribution} image from a system description" do
      @machinery.inject_directory(
        @system_description_dir,
        "/home/vagrant/.machinery/",
        owner: "vagrant",
        group: "users"
      )

      measure("Build image") do
        @machinery.run_command(
          "machinery build #{distribution}-build --image-dir=/home/vagrant/build_image -d -s > /tmp/#{distribution}-build.log",
          as: "vagrant"
        )
      end

      # Check that image was built
      images = @machinery.run_command(
        "find", "/home/vagrant/build_image", "-name", "*qcow2", :stdout => :capture
      )
      expect(images).not_to be_empty
    end

    describe "built image" do
      before(:all) do
        local_image = nil
        images = @machinery.run_command(
          "find", "/home/vagrant/build_image", "-name", "*qcow2", :stdout => :capture
        )
        measure("Extract image") do
          # Extract image from master VM
          image = images.split.first.chomp
          local_image = File.join("/tmp", File.basename(image))
          `sudo rm #{local_image}` if File.exists?(local_image)
          @machinery.extract_file image, "/tmp"
        end

        # Boot built image and extract system description
        @test_system = start_system(image: local_image)
        prepare_machinery_for_host(@machinery, @test_system.ip, password: "linux")

        measure("inspect image") do
          @machinery.run_command(
            "machinery inspect #{@test_system.ip} -n built_image --scope packages,patterns,repositories,config-files,unmanaged-files,services,changed-managed-files -x",
            as: "vagrant"
          )
        end

        # Read in system description from built and booted image
        new_description_json = @machinery.run_command(
          "cat ~/.machinery/built_image/manifest.json",
          as: "vagrant",
          stdout: :capture
        )
        @new_description = SystemDescription.from_json("new", new_description_json)
      end

      it "contains the RPM from the system description" do
        original_rpmlist = @system_description.packages.map(&:name).sort
        current_rpmlist = @new_description.packages.map(&:name).sort
        expect(current_rpmlist).to match_array(original_rpmlist)
      end

      it "contains the patterns from the system description" do
        original_patlist = @system_description.patterns.map(&:name).sort
        current_patlist = @new_description.patterns.map(&:name).sort
        expect(current_patlist).to match_array(original_patlist)
      end

      it "contains the repositories from the system description" do
        original_repos = @system_description.repositories.map(&:name).sort
        current_repos = @new_description.repositories.map(&:name).sort
        expect(current_repos).to match_array(original_repos)
      end

      describe "config-files:" do
        it "contains the changed config file" do
          actual_config_files = @machinery.run_command(
            "find", "/home/vagrant/.machinery/built_image/config_files/", "-printf", "%P\n",
            :stdout => :capture
          ).split("\n")
          expect(actual_config_files).to include("etc/crontab")
        end

        it "contains the changed config-files from the system description" do
          expect(@new_description).to include_scope(@system_description,
            "config_files")
        end

        it "removed the deleted config file" do
          expect {
            @test_system.run_command("ls /etc/postfix/LICENSE", stdout: :capture)
          }.to raise_error(ExecutionFailed, /No such file/)
        end
      end

      describe "changed-managed-files:" do
        it "contains the changed managed file" do
          actual_files = @machinery.run_command(
            "find", "/home/vagrant/.machinery/built_image/changed_managed_files/", "-printf", "%P\n",
            :stdout => :capture
          ).split("\n")
          actual_md5 = @machinery.run_command(
            "md5sum",
            "/home/vagrant/.machinery/built_image/changed_managed_files/usr/share/doc/packages/rsync/README",
            :stdout => :capture
          )

          expect(actual_files).to include("usr/share/doc/packages/rsync/README")
          expect(actual_md5).to include("23183915f5dd4202d2e00520807f02ff")
        end

        it "contains the changed managed-files from the system description" do
          expect(@new_description).to include_scope(@system_description,
            "config_files")
        end

        it "removed the deleted managed file" do
          expect {
            @test_system.run_command("ls /usr/share/doc/packages/rsync/NEWS", stdout: :capture)
          }.to raise_error(ExecutionFailed, /No such file/)
        end
      end


      it "contains the unmanaged files from the system description" do
        # Check meta data
        expect(@new_description).to include_scope(@system_description,
          "unmanaged_files")

        # Check file content
        file_content = @test_system.run_command(
          "cat '/usr/local/magicapp/weird-filenames/spacy file name'",
          as: "root",
          stdout: :capture
        )
        expect(file_content).to eq "This is a file with spaces in its name.\n"
      end

      it "contains the activated services from the system description" do
        expect(@new_description).to match_scope(@system_description,
          "services")
      end
    end
  end
end
