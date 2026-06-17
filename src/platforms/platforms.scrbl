#lang scribble/manual

@(require "../../scribble-api.rkt")

@title[#:tag "platforms"]{Platforms}

This section summarizes the different @emph{platforms} in which Jayret can
run.  Most features are available across all platforms, there are some that
only work in particular settings.

Elsewhere in the documentation you may see features flagged with

@cpo-only{@para{Behavior that is specific to, or works only in,
@url["https://jayret-lang.github.io/code"]. These typically require using a Google-specific
API to access files in Google Drive.}}

@vscode-only{@para{Behavior that is specific to, or works only in, the Visual
Studio Code extension.}}

@cli-only{@para{Behavior that is specific to, or works only in, the command line.}}

A common combination is:

@vscode-cli-only{@para{Behavior that is specific to, or works only in, the Visual
Studio Code extension @emph{or} at the command-line. This typically has to do
with accessing the filesystem.}}

@section{jayret-lang.github.io/code}

The website @url["https://jayret-lang.github.io/code"] lets you run Jayret code directly in
your browser, and connect to Google Drive to save and share programs you write.

@section{VScode Extension}

The
@link["https://marketplace.visualstudio.com/items?itemName=PyretProgrammingLanguage.pyret-parley"
"Jayret VScode Extension"] provides a way to run Jayret code within Visual Studio
Code in an interface similar to jayret-lang.github.io/code, with a definitions and interactions area.

@subsection{Installing the VScode Extension}

From Visual Studio Code, choose the extensions sidebar options (looks like four
squares with the top right square at an angle). Search for “Jayret” and click on
the extension called “Jayret Interactive Editor for VScode” by the author “Jayret Programming Language”. You should see a
screen like this, with an option to install, which you can click to add the extension.

@margin-note{Screenshots in this section still show the Pyret-era UI of the
extension and have been removed pending Jayret captures
(see @link["https://github.com/jayret-lang/docs/blob/horizon/PARITY.md"
"PARITY.md"]).}

@subsection{Opening Files in the VScode Extension}

The extension can be used from desktop Visual Studio Code, in which case it's
generally expected that students or users are able to open files and folders
from their computer in VScode (or get a copy of a folder from version control,
etc). Once a folder is opened (for example with File -> Open Folder...),
clicking on files with the @code{.jrt} extension will open them in the editor.
Then you can use the Run button and other editor features as usual.

Jayret programs in open editors save and synchronize to the filesystem like
other open text files, respecting keyboard shortcuts like Ctrl/Cmd-s or
“Save” in the “File” menu. Depending on how VScode is configured autosave
may or may not be turned on (it is
@link["https://docs.github.com/en/codespaces/about-codespaces/understanding-the-codespace-lifecycle#saving-changes-in-a-codespace"
"automatically enabled on github.dev and in Codespaces"] and
@link["https://code.visualstudio.com/docs/editing/codebasics#_save-auto-save"
"not enabled by default in desktop VScode"]). Look for a dot next to the
filename (e.g. @tt{my-program.jrt •}) indicating unsaved changes if you're not sure.

@subsection{Use with github.dev}

The extension can also be used from
@link["https://docs.github.com/en/codespaces/the-githubdev-web-based-editor"
"github.dev"]. When visiting any Github repository, the keyboard shortcut
. (that is, a single period) will open that repository in
@code{github.dev}, so the repository folder will already be open. (This requires
being logged into a Github account.)

In new github.dev workspaces, the extension is not installed automatically. A
repository can list @emph{recommended} extensions: the
@link["https://github.com/jpolitz/sample-pyret-project/blob/main/.vscode/extensions.json"
"sample-pyret-project"] repository gives examples of this, and will make it so
users are prompted to install the extension when the workspace opens.

@subsection{Editing Jayret Files with the Default Editor}

For many reasons we might prefer to edit @code{.jrt} files without using the
visual editor and instead using the Visual Studio Code default text editor.  To
do this, you can open the context menu on a file and choose “Open With...”,
which will allow you select the visual editor or the plain text editor, and
optionally set your preferred default.

In plain text editors for Jayret files, there is a ▶ icon at the top of the tab.
Clicking this button will run the program (like using the run button in the
visual editor), and open the interactions area in a new VScode pane to the side.

@section{Command Line}

Jayret can also be run from the command line. The command-line interface is
distributed as an npm package @link["https://www.npmjs.com/package/jayret-npm"
"jayret-npm"]. The options for using the command line are described in the tool
itself. The @code{--help} option lists the available options.
