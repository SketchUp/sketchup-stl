# Copyright 2012 Trimble Navigation Ltd.
#
# License: Apache License, Version 2.0
# 
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require 'sketchup.rb'
require 'extensions.rb'

su_stl_extension = SketchupExtension.new 'STL Import/Export',
    'sketchup-stl/stl-loader.rb'

su_stl_extension.description = 'Adds STL file format import and export.'
su_stl_extension.version = '1.0'
su_stl_extension.copyright = '2012 Trimble Navigation Ltd.'
su_stl_extension.creator = 'Jim Foltz, Nathan Bromham, Konrad Shroeder, ' +
    'and members of the SketchUp team'

Sketchup.register_extension su_stl_extension, true
