# Validate python embeddable distribution for Delphi

Python embeddable can be a learning curve for Delphi developers and there is often confusion about what python is executing and from where.  This repo contains pre built delphi executables to help you test your python embeddable distribution.

This question has come up several times on [DelphiPraxis](https://en.delphipraxis.net/forum/39-python4delphi), so I thought it would be good to put together some test harness tools for other developers to test the configuration of python embeddable against a working application.

These testers allow you to:

* Browse for your python dll (Delphi needs to load python).
* Use a builtin object inspector inspecting the PythonEngine component so that you can see what settings should be working in your application.
* View a list of PIP installed packages.
* Execute commands against python to validate packages and scripts.

See the releases for the binaries and source code is provided for FMX and VCL.

## Quick Configure Steps

1. Download python embeddable distribution [here](https://www.python.org/downloads/windows/).
2. Unzip to a folder ie. C:\apps\Py311
3. Edit the _pth file to add paths ( sample file in repo )
4. Open a command prompt to this folder, commands will execute using the path from the command prompt first.
5. Download PIP & install into embeddable distribution
6. Install C runtime using the pip package. Delphi does not include c runtime, so it needs to be in the path.

   ```shell
   python -m pip install msvc_runtime
   ```
