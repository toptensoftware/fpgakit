let fs = require('fs');
var path = require('path');

try
{
let inFile;
let outFile;
let entityName;
let addrWidth = 0;
let dataWidth = 8;
let bigEndian = false;

for (let i=2; i<process.argv.length; i++)
{
    let a = process.argv[i];

    let isSwitch = false;
    if (a.startsWith("--"))
    {
        isSwitch = true;
        a = a.substring(2);
    }

    if (isSwitch)
    {
        let parts = a.split(':');
        if (parts.length > 2)
        {
            parts = [parts[0], parts.slice(1).join(":")]
        }
        if (parts.length == 2)
        {
            if (parts[1]=='false' || parts[1]=='no')
                parts[1] = false;
            if (parts[1]=='true' || parts[1]=='yes')
                parts[1] = true;
        }
        parts[0] = parts[0].toLowerCase();

        switch (parts[0])
        {
            case "help":
                showHelp();
                process.exit(0);
                break;

            case "entity":
                entityName = parts[1];
                break;

            case "addrwidth":
                addrWidth = parseInt(parts[1]);
                break;

            case "datawidth":
                dataWidth = parseInt(parts[1]);
                if (dataWidth != 8 && dataWidth != 16)
                    throw new Error("Invalid data width - must be 8 or 16");
                break;

            case "bigendian":
                bigEndian = true;
                break;

            default:
                throw new Error(`Unrecognized switch: --${parts[0]}`)
        }
    }
    else
    {
        if (!inFile)
            inFile = a;
        else if (!outFile)
            outFile = a;
        else
            throw new Error(`Too many args: ${a}`);
    }

}

if (!inFile)
{
    showHelp();
    throw new Error("Input file not specified");
    process.exit(7);
}

if (!outFile)
{
    outFile = inFile;
    var lastDot = outFile.lastIndexOf('.');
    if (lastDot >= 0)
        outFile = outFile.substring(0, lastDot);
    outFile += ".vhd";
}

if (!entityName)
{
    entityName = path.parse(outFile).name;
}

let step =  (dataWidth / 8);

// Load data
var data = fs.readFileSync(inFile);

// Work out address width
if (addrWidth == 0)
{
    addrWidth = parseInt(Math.ceil(Math.log2(data.length / step)));
    if (Math.pow(2, addrWidth) * step < data.length)
        addrWidth++;
}
var dataWords = Math.pow(2, addrWidth);
if (dataWords * step < data.length )
{
    throw new Error(`\nFAILED: Address width of ${addrWidth} can't hold ${data.length} bytes\n`);
}

var out = "";
let comma = ",";

out += "--\n";
out += "--\n";
out += "-- THIS FILE WAS AUTOMATICALLY GENERATED - DO NOT EDIT\n";
out += "--\n";
out += "--\n";
out += "";
out += "library ieee;\n";
out += "use ieee.std_logic_1164.ALL;\n";
out += "use ieee.numeric_std.ALL;\n";
out += "\n";
out += `entity ${entityName} is\n`;
out += "port\n";
out += "(\n";
out += "	i_clock : in std_logic;\n";
out += `	i_addr : in std_logic_vector(${addrWidth-1} downto 0);\n`;
out += `	o_dout : out std_logic_vector(${dataWidth-1} downto 0)\n`;
out += ");\n";
out += `end ${entityName};\n`;
out += "\n";
out += `--xilt:nowarn:Signal 'ram', unconnected in block '${entityName}', is tied to its initial value.\n`;
out += "\n";
out += `architecture behavior of ${entityName} is\n`;
out += `	type mem_type is array(0 to ${dataWords-1}) of std_logic_vector(${dataWidth-1} downto 0);\n`;
out += "	signal ram : mem_type := (\n";

for (let i=0; i<dataWords; i++)
{
    if (i == dataWords-1)
        comma ="";
    if ((i % 16) ==0)
        out += "\n\t";
    else
        out += " ";

    if (step == 1)
    {
        var byte = i< dataWords ? data[i] : 0;
        out += "x\"" + byte.toString(16).padStart(2, "0") + "\"" + comma;
    }
    else if (step == 2)
    {
        let ih = bigEndian ? i*2 : i*2 + 1;
        let il = bigEndian ? i*2 + 1 : i*2;
        var byteL = il < data.length ? data[il] : 0;
        var byteH = ih < data.length ? data[ih] : 0;

        out += "x\"" + (byteH << 8 | byteL).toString(16).padStart(4, "0") + "\"" + comma;
    }
}

out += ");\n";
out += "begin\n";
out += "	process (i_clock)\n";
out += "	begin\n";
out += "		if rising_edge(i_clock) then\n";
out += "			o_dout <= ram(to_integer(unsigned(i_addr)));\n";
out += "		end if;\n";
out += "	end process;\n";
out += "end;\n";

fs.writeFileSync(outFile, out, "utf8");
}
catch (err)
{
    console.error(err.message);
    process.exit(7);
}


function showHelp()
{
    console.log("bin2vhdlrom inputBinaryFile [vhdlFileToWrite] [options]");
    console.log();
    console.log("Options:");
    console.log(" --entityName:<name>  name of the VHDL entity to generate");
    console.log("                         (defaults to outfile name)");
    console.log(" --help               show this help");
    console.log(" --entity:<name>      name of generated entity");
    console.log(" --addrWidth:<width>  address width");
    console.log(" --dataWidth:<width>  bit data width (8 or 16)");
    console.log(" --bigendian          use big endian encoding");
}