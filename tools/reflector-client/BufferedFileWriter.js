let fs = require('fs');

// BufferedFileWriter builds a list of pending buffers to
// be written to a file and writes them asynchronously as quickly
// as possible.
//
// To use:
// 
// 1. Create an instance: let bfw = new BufferedFileWriter("file.dat");
// 2. Write to it, passing Buffer objects: bfw.write(myBuffer);
// 3. When finished, asynchronously close: await bfw.close();

class BufferedFileWriter
{
    // Construct a new instance
    constructor(filename)
    {
        this.fd = fs.openSync(filename, "w");
        this.currentBuffer = null;
        this.filledBuffers = [];
        this.spareBuffers = [];
        this.filledBuffers = [];
        this.writing = false;
        this.tempBuffer = Buffer.alloc(4);
    }

    // Flush all unwritten buffers and close the file
    async close()
    {
        // wait for flush...
        process.nextTick(() => this.flush());       // Make sure flush gets called
        await (new Promise((resolve, reject) => {
            this.flushedResolver = resolve;
        }));

        // Close 
        fs.closeSync(this.fd);
        this.fd = -1;
    }

    // Internal: start the next write operation
    flush()
    {
        // Quit if already writing
        if (this.writing)
            return;

        // Get the next buffer to be written
        let bufToWrite;
        if (this.filledBuffers.length == 0)
        {
            // No filled buffers, try to use the current buffer
            if (this.currentBuffer == null || this.currentBuffer.used == 0)
            {
                // Nothing left.  If the close method is awaiting then
                // resolve it's promise.
                if (this.flushedResolver)
                    this.flushedResolver();
                return;
            }
            
            // Claim the current buffer
            bufToWrite = this.currentBuffer;
            this.currentBuffer = null;
        }
        else
        {
            // Get the first one from the list
            bufToWrite = this.filledBuffers.shift();
        }

        // Remember that we're writing
        this.writing = true;

        // Do the write operation
        fs.write(this.fd, bufToWrite, 0, bufToWrite.used, (err, bytesWritten, bufRet) => {

            // TODO: handle errors?

            // Flag no longer writing
            this.writing = false;

            // Return the buffer for re-use
            this.spareBuffers.push(bufRet);

            // Start the next flush op
            process.nextTick(() => this.flush());

        });
    }

    // Write a buffer to the file
    // (The entire passed buffer will be written)
    write(buf)
    {
        // Do we have an already started buffer
        if (this.currentBuffer)
        {
            // Will the passed data fit?
            if (this.currentBuffer.used + buf.length < this.currentBuffer.length)
            {
                // Yep, just append it
                buf.copy(this.currentBuffer, this.currentBuffer.used);
                this.currentBuffer.used += buf.length;
                return;
            }

            // Current buffer would overflow, put it in the queue and 
            // start a new one (below)
            this.filledBuffers.push(this.currentBuffer);
        }

        // Get a new buffer - either from the spare buffers list or by
        // allocating a new one
        if (this.spareBuffers.length > 0 && buf.length <= this.spareBuffers[0].length)
        {
            this.currentBuffer = this.spareBuffers.shift();
        }
        else
        {
            this.currentBuffer = Buffer.alloc(Math.max(16384, buf.length));
        }

        // Copy the passed data to the new buffer
        buf.copy(this.currentBuffer, 0);
        this.currentBuffer.used = buf.length;

        // Start a flush operation (unless we're already writing in which
        // case we don't need to since when the current write finishes it
        // will automatically start another.
        if (!this.writing)
        {
            process.nextTick(() => this.flush());
        }
    }

    // Simple helper to write an int32
    writeInt(val)
    {
        this.tempBuffer.writeInt32LE(val);
        this.write(this.tempBuffer);
    }
}

module.exports = BufferedFileWriter;