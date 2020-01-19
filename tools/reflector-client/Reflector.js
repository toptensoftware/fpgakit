let fs = require('fs');
let events = require('events');
let SerialPort = require('serialport');

let BufferedFileWriter = require('./BufferedFileWriter');
let BitPacket = require('./BitPacket');
let VcdFileWriter = require('./VcdFileWriter');

// Reflector establishes a serial connection between the PC
// and an attached FPGA.
// See sandbox.js for example on how to use this component.
class Reflector extends events.EventEmitter
{
    // Constructor
    constructor(options)
    {
        super();

        // Create default port options
        if (!options.portOptions)
            options.portOptions = {};
        if (!options.portOptions.baudRate)
            options.portOptions.baudRate = 115200;

        // Store options
        this.options = options;

        // Create accessors
        this.accessors = {};
        let sWidth = this.defineAccessors(this.options.sendAccessors, false);
        let rWidth = this.defineAccessors(this.options.receiveAccessors, true);

        // Auto bit widths?
        if (this.options.receiveBitCount === undefined)
            this.options.receiveBitCount = rWidth;
        if (this.options.sendBitCount === undefined)
            this.options.sendBitCount = sWidth;
        
        // Sanity checks
        if (sWidth > this.sendBitCount)
            throw new Error(`One of more send accessors references out of range bits (${sWidth} > ${this.sendBitCount})`);
        if (rWidth > this.receiveBitCount)
            throw new Error(`One of more receive accessors references out of range bits (${rWidth} > ${this.receiveBitCount})`);

        // Create bit packets
        this.receivePacket = new BitPacket(this.receiveBitCount);
        this.sendPacket = new BitPacket(this.sendBitCount, () => this.onSendPacketChanged());
        this.sendPacketDirty = false;

        // Create receive buffer where we'll collect received packets until they're complete
        this.receiveBuffer = Buffer.alloc(this.receivePacket._buffer.length);
        this.receiveBufferUsed = -1;

        // Create buffers to detect if data actually changed
        this.receiveCompareBuffer = Buffer.alloc(this.receivePacket._buffer.length);
        this.sendCompareBuffer = Buffer.alloc(this.sendPacket._buffer.length);

        // Create serial port
        if (options.portName)
        {
            options.portOptions.autoOpen = false;
            this.serialPort = new SerialPort(options.portName, options.portOptions);

            // Receive data handler
            this.serialPort.on('data', this.onReceive.bind(this));
        }
    }

    // Open
    async open()
    {
        // Open signal writer.  When .vcd file is enabled, instead of 
        // writing directly to the .vcd file we first buffer all the
        // received signals to a binary file that we write using
        // a buffered file writer.
        if (this.options.vcdFile)
        {
            this.signalWriter = new BufferedFileWriter(this.options.vcdFile + ".tmp");
            this.signalWriter.writeInt(this.sendBitCount);
            this.signalWriter.writeInt(this.receiveBitCount);
        }

        // Open the serial port
        if (this.serialPort)
        {
            await new Promise((resolve, reject) => {
                this.serialPort.open(function(err) { 
                    if (err)
                        reject(err);
                    else
                        resolve();
                });
            });
        }

        // Remember the start time as base time for .vcd times
        this.startTime = Date.now();
    }

    // Close
    async close()
    {
        // Close the serial port
        if (this.serialPort && this.serialPort.isOpen)
            this.serialPort.close();

        // Close the signal writer
        if (this.signalWriter)
        {
            await this.signalWriter.close();
            this.signalWriter = null;
        }

        // Convert signal file to vcd file
        this.convertSignalsToVcd();
    }

    // Internal helper to define a set of accessor properties on this
    // reflector instance
    defineAccessors(accessors, receive)
    {
        // Which BitPacket instance should the property refer to
        let member = receive ? "this.receivePacket" : "this.sendPacket";

        let maxMsb = -1;

        // Create accessors
        for (let k of Object.keys(accessors))
        {
            // Get the bit range
            let bitRange = accessors[k];
            let msb = bitRange[0];
            let lsb = bitRange[1];

            // Check it
            if (msb < lsb)
                throw new Error(`Bit range incorrect for '${k}', msb must be greater than lsb`);

            // Calculate max MSB
            if (msb > maxMsb)
                maxMsb = msb;

            // Define properties
            let getter = BitPacket.buildGetAccessorBody(member, msb, lsb);
            let setter = BitPacket.buildSetAccessorBody(member, msb, lsb, k);
            Object.defineProperty(this, k, {
                get: Function([], getter),
                set: Function(['value'], setter),
            });

            // Store meta data about accessors
            this.accessors[k] = {
                msb,
                lsb,
                width: msb - lsb + 1,
                receive,
            }
        }

        return maxMsb + 1;
    }

    // Get the number of send bits this reflector is configured for
    get sendBitCount() { return this.options.sendBitCount };

    // Get the number of receive bits this reflector is configured for
    get receiveBitCount() { return this.options.receiveBitCount };

    // Format the value of a defined accessor in hex
    formatHex(name)
    {
        // Get accessor info
        let ai = this.accessors[name];

        // get the value
        let val = this[name];

        return val.toString(16).padStart(Math.floor((ai.width + 3)/4), '0');
    }

    // Format the value of a defined accessor in binary
    formatBinary(name)
    {
        // Get accessor info
        let ai = this.accessors[name];

        // get the value
        let val = this[name];

        return val.toString(2).padStart(ai.width, '0');
    }

    // Same a formatBinary but replaces 1's and 0's with LED looking characters
    formatLeds(name)
    {
        return this.formatBinary(name).replace(/./g, x => x =='1' ? "●" : "-");
    }
    
    // Set the value of an accessor using a string bit pattern
    setBits(name, value)
    {
        let ai = this.accessors[name];
        (ai.receive ? this.receivePacket : this.sendPacket).setBits(ai.msb, ai.lsb, value);
    }

    // Get the value of an accessor as a string bit pattern
    getBits(name)
    {
        let ai = this.accessors[name];
        return (ai.receive ? this.receivePacket : this.sendPacket).getBits(ai.msb, ai.lsb);
    }

    // Handler for data received via serial port
    onReceive(data)
    {
        for (let i=0; i<data.length; i++)
        {
            // Start of a packet?
            if ((data[i] & 0x80) != 0)
            {
                this.receiveBufferUsed = 0;
            }
            else if (this.receiveBufferUsed < 0)
            {
                // Haven't received start of packet byte yet
                continue;
            }

            // Copy byte to the buffer
            this.receiveBuffer[this.receiveBufferUsed++] = data[i];

            // Has the entire packet been received?
            if (this.receiveBufferUsed == this.receiveBuffer.length)
            {
                // Yep, swap buffers with the receive packet
                let temp = this.receiveBuffer;
                this.receiveBuffer = this.receivePacket._buffer;
                this.receivePacket._buffer = temp;

                // Prepare for next
                this.receiveBufferUsed = -1;

                // Fire events...
                this.onChange();
            }
        }
    }

    // Check if the receive buffer really did change since the last time we generated an event
    get didReceiveChange()
    {
        for (let i=0; i<this.receiveCompareBuffer.length; i++)
        {
            if (this.receiveCompareBuffer[i] != this.receivePacket._buffer[i])
                return true;
        }
        return false;
    }

    // Check if the send buffer really did change since the last time we generated an event
    get didSendChange()
    {
        for (let i=0; i<this.sendCompareBuffer.length; i++)
        {
            if (this.sendCompareBuffer[i] != this.sendPacket._buffer[i])
                return true;
        }
        return false;
    }

    // Fire change events and write values to the .vcd binary dump
    onChange()
    {
        // if already pending, ignore 
        if (this.changeEventPending)
            return; 

        this.changeEventPending = true;
        process.nextTick(() => {
            this.changeEventPending = false;
            if (this.didReceiveChange || this.didSendChange)
            {
                // Write to VCD file.  Time stamp, send packet, receive packet
                if (this.signalWriter)
                {
                    this.signalWriter.writeInt(Date.now() - this.startTime);
                    this.signalWriter.write(this.sendPacket._buffer);
                    this.signalWriter.write(this.receivePacket._buffer);
                }

                // Remember the current values for future comparison
                this.sendPacket._buffer.copy(this.sendCompareBuffer);
                this.receivePacket._buffer.copy(this.receiveCompareBuffer);

                // Fire event
                this.emit('change');
            }
        });
    }

    // Someone changed the send packet, send it via serial port on the next
    // event loop tick.
    onSendPacketChanged()
    {
        if (!this.sendPacketDirty)
        {
            this.onChange();
            this.sendPacketDirty = true;
            process.nextTick(() => {
                this.sendPacketDirty = false;
                if (this.serialPort)
                    this.serialPort.write(this.sendPacket._buffer);
            });
        }

    }

    // Called when this reflector component is closed to 
    // re-read the binary signal dump and convert it to a .vcd file
    convertSignalsToVcd()
    {
        // Open the binary dump file
        let fd = fs.openSync(this.options.vcdFile + ".tmp");

        // Create Vcd writer
        let w = new VcdFileWriter(this.options.vcdFile);

        // Setup headers
        w.setCreator("Reflector v1.0");
        w.setTimeScale("1 ms");
        w.addModule("signals");
        for (let a of Object.keys(this.accessors))
        {
            let acc = this.accessors[a];

            if (acc.width == 1)
                acc.signal = w.addSignal(a, "reg 1", "U");
            else
                acc.signal = w.addSignal(a, `reg ${acc.width}`, "b" + "U".repeat(acc.width));
        }

        w.closeHeaders();

        // Read the signals file
        let temp = Buffer.alloc(4);
        fs.readSync(fd, temp, 0, 4);        // sent bits (ignored)
        fs.readSync(fd, temp, 0, 4);        // receive bits (ignored)
        while (true)
        {
            // Process the time stamp
            if (fs.readSync(fd, temp, 0, 4) == 0)
                break;
            w.setTime(temp.readInt32LE(0));

            // Read signals
            fs.readSync(fd, this.sendPacket._buffer, 0, this.sendPacket._buffer.length);
            fs.readSync(fd, this.receivePacket._buffer, 0, this.receivePacket._buffer.length);

            // Write signals
            for (let a of Object.keys(this.accessors))
            {
                let acc = this.accessors[a];
    
                if (acc.width == 1)
                    w.setSignal(acc.signal, this.formatBinary(a));
                else
                    w.setSignal(acc.signal, "b" + this.formatBinary(a));
            }
        }

        // Clean up
        w.close();
        fs.closeSync(fd);
        fs.unlinkSync(this.options.vcdFile + ".tmp");
    }
}


module.exports = Reflector;
