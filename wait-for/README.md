## wait-for

This script came from here:

https://github.com/Eficode/wait-for

(MIT license)

We use it to wait for the main application to be able to respond to requests. When the main application is
responding, we then launch the SigSci agent.

To update the script, do something like this:

```bash
wget "https://github.com/eficode/wait-for/releases/download/v${VERSION}/wait-for"
chmod +x wait-for
```

However we added our own `--header` parameter for our particular use case. Check `git diff` when you update
the script.
