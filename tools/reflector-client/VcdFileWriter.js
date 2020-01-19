let fs = require('fs');

let dayNames = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
let monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec' ];

// Simple .VCD file writer
class VcdFileWriter
{
    // Construct a new file writer
    constructor(filename)
    {
        // Open the file
        this.fd = fs.openSync(filename, "w");

        // Write date
        let now = new Date();
        this.write(`$date`);
        this.write(`  ${dayNames[now.getUTCDay()]} ${monthNames[now.getUTCMonth()]} ${now.getUTCDate()} ${now.getUTCHours().toString().padStart(2, '0')}:${now.getUTCMinutes().toString().padStart(2, '0')}:${now.getUTCSeconds().toString().padStart(2, '0')} ${now.getUTCFullYear()}`);
        this.write(`$end`);

        // Setup state
        this.nextSymbolIndex = 33;
        this.signals = [];
        this.currentTime = "0";
    }

    // Set the creator version string
    setCreator(name)
    {
        this.write(`$version`);
        this.write(`  ${name}`);
        this.write(`$end`);
    }

    // Set the time scale
    setTimeScale(value)
    {
        this.write(`$timescale`);
        this.write(`  ${value}`);
        this.write(`$end`);
    }

    // Add a module
    addModule(name)
    {
        this.write(`$scope module ${name} $end`);
    }

    // Add a signal to the current module
    // Returns an object that should be used with setSignal to
    // later set the values for this signal
    addSignal(name, type, value)
    {
        let symbol = String.fromCharCode(this.nextSymbolIndex++);
        this.write(`$var ${type} ${symbol} ${name} $end`);
        let signal = { name, symbol, type, value, lastValue: "" };
        this.signals.push(signal);
        return signal;
    }

    // Close the header section and start the value dump
    closeHeaders()
    {
        this.write(`$upscope $end`);
        this.write(`$enddefinitions $end`);
        this.write(`$dumpvars`);

        // Write initial values
        this.writeSignals();
    }

    // Close the file
    close()
    {
        // Write final signal values
        this.writeSignals();

        // Close
        fs.closeSync(this.fd);
        this.fd = -1;
    }

    // Internal helper to write a line to the output file
    write(str)
    {
        fs.writeSync(this.fd, str, "utf8");
        fs.writeSync(this.fd, "\n", "utf8");
    }

    // Write the current timestamp and all changed signal values
    writeSignals()
    {
        // Remember if the time stamp has been written (only write 
        // it if we have changed values at this timestamp)
        let timeWritten = false;

        // Write all changed signals
        for (let i=0; i<this.signals.length; i++)
        {
            let signal = this.signals[i];
            if (signal.lastValue != signal.value)
            {
                // Write time stamp if we haven't already
                if (!timeWritten)
                {
                    this.write(`#${this.currentTime}`);   
                    timeWritten = true;
                }

                // Remember value and write value
                signal.lastValue = signal.value;
                if (signal.value[0] == 'b')
                    this.write(`${signal.value} ${signal.symbol}`);
                else
                    this.write(`${signal.value}${signal.symbol}`);
            }
        }
    }

    // Set the current time for following setSignal values
    setTime(value)
    {
        // Same time?
        if (this.currentTime == value)
            return;

        // Write changed signal at last time
        this.writeSignals();

        // Update current time
        this.currentTime = value;
    }

    // Set a signal value
    setSignal(signal, newValue)
    {
        signal.value = newValue;
    }
}

module.exports = VcdFileWriter;