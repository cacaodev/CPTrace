
**CPTrace**. 

Trace objj messages for a class and a selector.
Support nested calls, custom output.

Usage
-----

```javascript
CPTrace("TheClass", "a:selector:", [optional] displayFunction);
```

where displayFunction([CPObject] areceiver, [CPString] aSelector, [CPArray] arguments, [ms] duration, [ms] total_duration, [int] total_count, [int] nesting_level)

If displayFunction is not specified, the default message is logged to the console: 

```[<TheClass x0001> a:1 selector:2] in 3ms, avg = 2.245ms```


TODO:
-----

avg call duration works only for root level calls (0).



