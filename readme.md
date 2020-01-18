# FpgaKit

## Build Prerequisites

To build this project you'll need a Linux machine with the following 
tools installed:

* [Xilinx ISE Design Suite 14.7](https://www.xilinx.com/products/design-tools/ise-design-suite.html) (the free WebPack license will do)
* [Node 10.x](https://nodejs.org/en/) (v8.x might work too)
* [Xilt](https://www.npmjs.com/package/xilt) (front-end driver for Xilinx command line tool chain).
* Make (ie: sudo apt-get install build-essential)
* [GHDL](http://ghdl.free.fr) (optional, required to run simulations)
* [GTKWave](http://gtkwave.sourceforge.net) (options, required to view simulations)
* [Visual Studio Code](https://code.visualstudio.com/docs/setup/linux) (optional)

To install any or all of the above you might find my [xilsetup](https://bitbucket.org/toptensoftware/xilsetup/) script handy.


## Build Instructions (Mimas V2)

To build the FPGA hardware project:

```
$ cd ./boards/mimasv2/<projectname>
$ make
```

The final .bin file will be in the `/build` directory of the project

I recommend using [this updated firmware](https://github.com/toptensoftware/MimasV2-Loader) for the Mimas V2 which will then let you upload to the board like so:

```
$ make upload
```

Notes:

1. if you're running Linux in a virtual machine, you'll have to make sure the USB port the
board is plugged into is forwarded by the VM host. In VirtualBox, check the Devices -> USB menu.
2. for the Mimas V2 board you need to upload the `.bin` file - not the `.bit` file.
3. the `./boards/mimasv2` directory also contains several other experiments and 
test projects that you can try if you're interested.


## Running Simulation Test Benches

Simulation test benches for various components are available in the `./sims` sub-directory.

These simulations have only been tested using the LLVM build of GHDL - they may or may not
work in the other builds.

To run and view the simulation signal traces,  run `make view` in the project directory.

```
$ cd ./sims/01-sim-basics
$ make view
```

## Project Structre

The directory structure of this project is as follows:


* `./boards` - anything that's specific to a particular FPGA board.
* `./resources` - miscellaneous resources like original ROM images etc...
* `./shared` - shared VHDL components that aren't specific to a TRS-80
* `./sims` - all simulation test benches
* `./tools` - tools and scripts.

The `./boards` and `./sims` directory both contain numbered sub-projects.  The idea here is to keep all experiments and test benches and the numbers help keep them in sequence.

Within each project directory is a VS Code workpace file and tasks.json file.  To work with these:

1. Change to the directory of the project
2. Run `code workspace.code-workspace`
3. Use the VS Code build command to build the project
4. For FPGA projects, use the Terminal menu -> Run Task -> "Upload" task program the board
5. For simulation projects, use the Terminal menu -> Run Task -> "View" task to run the simulation and launch GTKWave.

Note: if you launch GTKWave from VS Code you'll need to close it before being able to run additional tasks in VS Code.  I've not been able to find a solution for this.  Remember to Ctrl+S before closing GTKWave to keep your displayed signals and positions.

## License

Copyright © 2019 Topten Software. All Rights Reserved.

Licensed under the Apache License, Version 2.0 (the "License"); you may not use this product except in compliance with the License. You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.