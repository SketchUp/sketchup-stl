# Welcome to SketchUp-STL

A SketchUp Ruby Extension that adds STL (STereoLithography) file format
import and export.

3D printing is awesome, and the STL format has emerged as a standard way to share printable 3D models. To support this community, SketchUp has gathered a couple of Ruby plugins and packaged them into a single Extension. Stay tuned! This is our first foray into Open Source, an experiment we hope to repeat.

## Installing

The latest and greatest is available as an RBZ file. Download the file from this url:

https://github.com/SketchUp/sketchup-stl/raw/master/sketchup-stl-1.0.0.rbz

Then inside SketchUp, select Window > Preferences (Microsoft Windows) or SketchUp > Preferences (Mac OS X) > Extensions > Install Extension and select the RBZ file you just downloaded. Voila! SketchUp installs the extension. You'll find a new import type under File > Import and a File > Export STL menu option as well.

## Contributing

If you're a SketchUp Ruby community member, use git to grab the code, make some changes, then send us a pull request. (If you don't know what that is, that's okay, we barely know ourselves. Go google some github tutorials and give it a try. Please improve our README.md file with better instructions!)

If you're an owner of this repo, here are some steps.

Get a local copy of the files. This will create a sketchup-stl folder.

	git clone https://github.com/SketchUp/sketchup-stl.git  
	cd sketchup-stl  

Use your favorite editor to edit README.md. Then...

	git add README.md                     // Marks README.md for edit.  
	git commit -m "Editing our README"    // Records changes in the local branch.  
	git push                              // Submits to repository. Yay!  

## License

See the LICENSE and NOTICE files for more information.

Copyright: Copyright (c) 2012 Trimble Navigation, Ltd.

License: Apache License, Version 2.0

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.