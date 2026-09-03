# Pipes

Every app starts out with what seems like a simple task: get data, transform them, and show them to users. Getting data could be as simple as creating a local variable or as complex as streaming data over a WebSocket.

Once data arrive, you could push their raw toString values directly to the view, but that rarely makes for a good user experience. For example, in most use cases, users prefer to see a date in a simple format like April 15, 1988 rather than the raw string format Fri Apr 15 1988 00:00:00 GMT-0700 (Pacific Daylight Time).

Clearly, some values benefit from a bit of editing. You may notice that you desire many of the same transformations repeatedly, both within and across many apps. You can almost think of them as styles. In fact, you might like to apply them in your HTML templates as you do styles.

Introducing Kelicap pipes, a way to write display-value transformations that you can declare in your HTML.

Creating custom `@Directive` classes.
Writing data transformers with `@Pipe` (`PipeTransform`).
