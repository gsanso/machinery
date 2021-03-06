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

shared_examples "inspect" do |bases|
  bases.each do |base|
    describe "inspect #{base} system" do
      before(:all) do
        @subject_system = start_system(box: base)
        prepare_machinery_for_host(@machinery, @subject_system.ip, password: "vagrant")
      end

      include_examples "inspect packages", base
      include_examples "inspect patterns", base
      include_examples "inspect repositories", base
      include_examples "inspect os", base
      include_examples "inspect services", base
      include_examples "inspect users", base
      include_examples "inspect groups", base
      include_examples "inspect config files", base
      include_examples "inspect changed managed files", base
      include_examples "inspect unmanaged files", base
    end
  end
end
