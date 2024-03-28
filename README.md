# Welcome to SketchUp-STL

A SketchUp Ruby Extension that adds STL (STereoLithography) file format
import and export.

3D printing is awesome, and the STL format has emerged as a standard way to share printable 3D models. To support this community, SketchUp has gathered a couple of Ruby plugins and packaged them into a single Extension. Stay tuned! This is our first foray into Open Source, an experiment we hope to repeat.

## Installing

The latest and greatest is available as an RBZ file. Download the file from this URL:

https://extensions.sketchup.com/extension/412723d4-1f7a-4a5f-b866-281a3e223337/sketch-up-stl

Then inside SketchUp, select `Window` → `Preferences` (Microsoft Windows) or `SketchUp` → `Preferences` (Mac OS X) → `Extensions` → `Install Extension` and select the RBZ file you just downloaded. Voila! SketchUp installs the extension. You'll find a new import type under `File` → `Import` and a `File` → `Export STL` menu option as well.

## Contributing

### Members

If you're an owner of this repo, here are some steps.

Get a local copy of the files. This will create a `sketchup-stl` folder.
```
	git clone https://github.com/SketchUp/sketchup-stl.git  
	cd sketchup-stl  
```
Use your favorite editor to edit `README.md`. Then...
```
	git add README.md                     // Marks README.md for edit.  
	git commit -m "Editing our README"    // Records changes in the local branch.  
	git push                              // Submits to repository. Yay!  
```
### Community 

If you're a SketchUp Ruby community member, you need to fork this repo (If you don't know what that is, that's okay, we barely know ourselves. Go google some GitHub tutorials and give it a try. Please improve our `README.md` file with better instructions!)

#### Steps

1. Fork this repo ([tutorial](https://help.github.com/articles/fork-a-repo)). Forking will create a copy of this repo under your GitHub user name.

1. Clone your fork. For this you will need git installed on your personal computer. [GitHub for Windows](http://windows.github.com/) is a good choice.

1. Add this repo as a remote so you can pull in updates to your clone.
```
		git remote add upstream https://github.com/SketchUp/sketchup-stl.git
```
1. Make your changes to the code in your cloned repo, then commit. (`git commit ...`)

1. Push your changes to your GitHub repo.  (`git push`)

1. From your GitHub repo, send a Pull Request.

#### Debuging advice

To debug, the following steps will allow to reload the app without closing sketchup on each modification:

- uncomment the line `` Sketchup::require File.join(PLUGIN_PATH, 'reload')`` in loader.rb
- copy `` sketchup-stl.rb`` S file and `` sketchup-stl`` folder in `` SC:\Users\tks\AppData\Roaming\SketchUp\SketchUp 2023\SketchUp\Plugins`` folder 

Once Sketchup launched, you can modify scrripts and reload the extensions by going to "Extensions">"Developer"> "Reload Code Files: sketchup-stl"

	

## License

The MIT License (MIT)

Copyright (c) 2014 Trimble Navigation

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
