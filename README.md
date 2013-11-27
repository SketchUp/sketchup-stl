# Welcome to SketchUp-STL

A SketchUp Ruby Extension that adds STL (STereoLithography) file format
import and export.

3D printing is awesome, and the STL format has emerged as a standard way to share printable 3D models. To support this community, SketchUp has gathered a couple of Ruby plugins and packaged them into a single Extension. Stay tuned! This is our first foray into Open Source, an experiment we hope to repeat.

## Installing

The latest and greatest is available as an RBZ file. Download the file from this URL:

http://extensions.sketchup.com/content/sketchup-stl

Then inside SketchUp, select `Window → Preferences` (Microsoft Windows) or `SketchUp → Preferences` (Mac OS X) `→ Extensions → Install Extension` and select the RBZ file you just downloaded. Voila! SketchUp installs the extension. You'll find a new import type under `File → Import and a File → Export STL` menu option as well.

## Contributing

### Members

If you're an owner of this repo, here are some steps.

Get a local copy of the files. This will create a sketchup-stl folder.

	git clone https://github.com/SketchUp/sketchup-stl.git  
	cd sketchup-stl  

Use your favorite editor to edit README.md. Then...

	git add README.md                     // Marks README.md for edit.  
	git commit -m "Editing our README"    // Records changes in the local branch.  
	git push                              // Submits to repository. Yay!  

### Community 

If you're a SketchUp Ruby community member, you need to fork this repo (If you don't know what that is, that's okay, we barely know ourselves. Go google some GitHub tutorials and give it a try. Please improve our README.md file with better instructions!)

#### Steps

1. Fork this repo ([tutorial](https://help.github.com/articles/fork-a-repo)). Forking will create a copy of this repo under your GitHub user name.

1. Clone your fork. For this you will need git installed on your personal computer. [GitHub for Windows](http://windows.github.com/) is a good choice.

1. Add this repo as a remote so you can pull in updates to your clone.

		git remote add upstream https://github.com/SketchUp/sketchup-stl.git

1. Make your changes to the code in your cloned repo, then commit. (`git commit ...`)

1. Push your changes to your GitHub repo.  (`git push`)

1. From your GitHub repo, send a Pull Request.


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
