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

class FileScope < Machinery::Object
  def compare_with(other)
    only_self = new_instance
    only_other = new_instance
    shared = new_instance

    compare_extracted(other, only_self, only_other, shared)
    compare_files(other, only_self, only_other, shared)

    only_self = nil if only_self.empty?
    only_other = nil if only_other.empty?
    shared = nil if shared.empty?
    [only_self, only_other, shared]
  end

  private

  def new_instance
    self.class.new
  end

  def compare_extracted(other, only_self, only_other, shared)
    if extracted == other.extracted
      shared.extracted = extracted
    else
      only_self.extracted = extracted
      only_other.extracted = other.extracted
    end
  end

  def compare_files(other, only_self, only_other, shared)
    own_files, other_files, shared_files = files.compare_with(other.files)

    only_self.files = own_files if own_files
    only_other.files = other_files if other_files
    shared.files = shared_files if shared_files
  end
end
