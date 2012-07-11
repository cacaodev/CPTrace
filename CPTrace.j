/*
 * CPTrace.j
 *
 * Created by cacaodev
 * Copyright 2012 <cacaodev@gmail.com>
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA

// ==========
// ! USAGE:
// ==========

Trace an instance method for a given class.

    CPTrace(aClassName, aSelector, [optional] displayFunction);
    If displayFunction is not specified, a default message containing relevant infos will be logged to the console.


Stop tracing an instance method for a given class:

    CPTraceStop(aClassName, aSelector);


Arguments for the displayFunction:

    function(aReceiver, aSelector, arguments_array, duration_in_ms, total_duration_in_ms, total_count, nesting_level)


// ========
// ! Notes
// ========

    - nesting_level is the nesting level for selectors you chose to trace, NOT for all calls.
    - total_duration and total_count are valid only if the nesting_level is 0 (root calls).
    - If traced calls are nested, the output will appear in the right order (not reversed). You get nesting information with the nested_level argument of the displayFunction.
    - If an argument is a js object (CGPoint for example), the default log won't give any useful info. You need to handle its description in a custom displayFunction.

// =========
// ! TODO:
// =========

    Class methods are not supported.
    total_duration and total_count are valid only if the nesting_level is 0 (root calls).
*/

var patchedClassesAndSelectors = [],
    globalStack = [],
    globalLevel = 0;

var Tracer = function()
{
    this.td = 0;
    this.tc = 0;
    this.displayFunction = nil;
};

Tracer.prototype.log = function()
{
    var c = globalStack.length;

    for (var i = 0; i < c; i++)
    {
        var trace = globalStack.shift();
        this.displayFunction(trace.receiver, trace.selector, trace.args, trace.duration, this.td, this.tc, trace.level);
    }
};

var defaultDisplay  = function(receiver, selector, args, duration, total_duration, total_count, level)
{
    var message = objj_message(receiver, selector, args),
        // WARNING: average duration only supported for root calls.
        avg_message = (level == 0) ? (" , avg = " + (ROUND(100 * total_duration / total_count) / 100) + " ms") : "";

    CPLogConsole(indent(level) + message + " in " + duration + " ms" + avg_message);
};

var indent = function(n)
{
    var str = "";
    while (n--)
        str += "  ";

    return str;
};

var objj_message = function(receiver, selector, args)
{
    var c = args.length,
        sel = selector.split(":"),
        rdesc = receiver ? [receiver description] : "<null>";

    while (c--)
        sel.splice(c + 1, 0, ":" + args[c] + " ");

    var joined = sel.join("");

    if (args.length)
        joined = joined.substring(0, joined.length - 1);

    return ("[" + rdesc + " " + joined + "]");
};

function CPTrace(aClassName, aSelector, displayFunction)
{
    var aclass = CPClassFromString(aClassName);

    if (aclass)
       _CPTraceClass(aclass, aSelector, displayFunction, YES);
    else if (typeof(objj_getClassList) != 'undefined')
    {
        var regex = new RegExp(aClassName),
            classes = [],
            patchednum = 0,
            numclasses = objj_getClassList(classes, 400);

        while (numclasses--)
        {
            var cls = classes[numclasses];
            if (regex.test(cls) && class_getInstanceMethod(cls, aSelector))
            {
                console.log("Patching " + cls + " " + aSelector);
                if (_CPTraceClass(cls, aSelector, displayFunction, NO))
                    patchednum++;
            }
        }

        if (patchednum == 0)
            console.log("Could not find any class matching '" + aClassName + "'");
        else
            console.log("Patched " + patchednum + " classes matching " + aClassName);
    }
    else
        [CPException raise:CPInvalidArgumentException reason:("Unknown class name '" + aClassName + "'")];
}

var _CPTraceClass = function(aClass, aSelector, displayFunction, raiseIfNotResponding)
{
    var cls,
        sel,
        superclass,
        isMetaClass = [aSelector hasPrefix:@"+"];

    if (isMetaClass)
    {
        sel = aSelector.substring(1);
        cls = objj_getMetaClass(class_getName(aClass));
    }
    else
    {
        cls = aClass;
        sel = aSelector;
    }

    superclass = cls;

    if (isAlreadyPatched(superclass, aSelector))
        return NO;

    while (superclass && !getMethodNoSuper(superclass, sel))
    {
        superclass = class_getSuperclass(superclass);
        if (isMetaClass)
            superclass = objj_getMetaClass(class_getName(superclass));
    }

    if (!superclass || !getMethodNoSuper(superclass, sel))
    {
        if (raiseIfNotResponding)
            [CPException raise:CPInvalidArgumentException reason:(aClass + " does not respond to '" + aSelector + "'")];
        return NO;
    }

    if (superclass != cls && isAlreadyPatched(superclass, aSelector))
        return NO;
        
    var patched_sel = CPSelectorFromString("patched_" + aSelector),
        tracer = new Tracer();

    tracer.displayFunction = displayFunction ? displayFunction : defaultDisplay;

    class_addMethod(cls, patched_sel, function()
    {
        var orig_arguments = arguments,
            receiver = orig_arguments[0],
            selector = orig_arguments[1],
            args = [];

        for (var i = 2; i < orig_arguments.length; i++)
            args.push(orig_arguments[i]);

        orig_arguments[1] = patched_sel;

        var trace = {receiver:receiver, selector:selector, args:args, start:(new Date()), level:globalLevel};
        globalStack.push(trace);
        globalLevel++;

        objj_msgSend.apply(objj_msgSend, orig_arguments);

        var duration = (trace.duration = new Date() - trace.start);
        globalLevel--;
        if (globalLevel == 0)
        {
            tracer.tc++;
            tracer.td += trace.duration;
            tracer.log();
        }

    }, "");

    Swizzle(cls, sel, patched_sel);

    return YES;
};

function CPTraceStop(aClassName, aSelector)
{
    var cls,
        sel,
        isMetaClass = [aSelector hasPrefix:@"+"];

    if (isMetaClass)
    {
        sel = aSelector.substring(1);
        cls = objj_getMetaClass(aClassName);
    }
    else
    {
        cls = objj_getClass(aClassName);
        sel = aSelector;
    }

    var patched_sel = CPSelectorFromString("patched_" + aSelector);
    var patchUniqueString = (class_getName(cls) + "_" + aSelector);
    if (getMethodNoSuper(cls, patched_sel) !== NULL)
    {
        Swizzle(cls, patched_sel, sel);
        [patchedClassesAndSelectors removeObject:patchUniqueString]; // WONT WORK IF sel IMPLEMENTED IN A SUPERCLASS
    }
    else
        console.log("Nothing to untrace");
}

var Swizzle = function(aClass, orig_sel, new_sel)
{
    var origMethod = class_getInstanceMethod(aClass, orig_sel),
        newMethod = class_getInstanceMethod(aClass, new_sel);

// This check should be in class_addMethod : Don't add and return NO and if method already exists.
    if (getMethodNoSuper(aClass, orig_sel) == NULL)
    {
        class_addMethod(aClass, orig_sel, method_getImplementation(newMethod), "");
        class_replaceMethod(aClass, new_sel, method_getImplementation(origMethod), "");
    }
    else
        method_exchangeImplementations(origMethod, newMethod);

/*
    if (class_addMethod(aClass, orig_sel, method_getImplementation(newMethod), ""))
        class_replaceMethod(aClass, new_sel, method_getImplementation(origMethod), "");
    else
        method_exchangeImplementations(origMethod, newMethod);
*/
};


var getMethodNoSuper = function(cls, sel)
{
    var method_list = cls.method_list,
        count = method_list.length;

    while (count--)
    {
        var mthd = method_list[count];
        if (mthd.name == sel)
            return mthd;
    }

    return NULL;
};

var isAlreadyPatched = function(aClass, aSelector)
{
    var patchUniqueString = (class_getName(aClass) + "_" + aSelector);

    if ([patchedClassesAndSelectors containsObject:patchUniqueString])
    {
        CPLogConsole(aClass + " " + aSelector + " is already patched. Ignoring.");
        return YES;
    }
    
    [patchedClassesAndSelectors addObject:patchUniqueString];
    
    return NO;
}