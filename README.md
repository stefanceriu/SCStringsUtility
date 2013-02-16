# SCStringsUtility

SCStringsUtility is an OS X Application built for easing the way we deal with localizable strings. It started off as a simple to/from CSV utility but ended up being a little bit more than that.

![SCStringsUtility](http://dl.dropbox.com/u/12748201/SCStringsUtility.png)

## Features
* Import from Xcode project using genstrings and its .string files (options for a different genstrings routine and positional parameters)

* Export to Localizable.strings/CSV/XML (with comments / key for missing translations)

* Import from CSV/XML

* Save back on top of the original files

* Search (filter all or just the keys)

* Editing & undo/redo support

* Console for displaying genstrings warnings

## How to use it
- download the .dmg from http://sourceforge.net/projects/stringsutility/files/SCStringsUtility.dmg/download

- fire up the application and point it to an .xcodeproj

##Known issues
- The application doesn't work when opening Xcode projects that have the .strings files inside virual groups. XcodeEditor doesn't provide correct paths for that case

##ToDo
- Individual cell selection

- Better error handling
 
## License
SCStringsUtility is released under the GNU GENERAL PUBLIC LICENSE (see the LICENSE file)

## Contact

Feel free to contact me at stefan.ceriu@yahoo.com or https://twitter.com/stefanceriu