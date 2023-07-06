## wait-for

This script came from here:

https://github.com/Eficode/wait-for

(MIT license)

We use it to wait for the main application to be able to respond to requests. We then only start the Signal Sciences
agent after the main application is running.

To update the script, do something like this:

```bash
wget "https://github.com/eficode/wait-for/releases/download/v${VERSION}/wait-for"
chmod +x wait-for
```
