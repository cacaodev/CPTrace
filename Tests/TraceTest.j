@import "../CPTrace.j"

var stack = [];
@implementation TraceTest : OJTestCase
{
}

- (void)clear
{
    [stack removeAllObjects];
}

- (void)testTraceInstanceMethod
{
    CPTrace("CPIndexSet", "addIndex:", output);
    var indexSet = [CPIndexSet indexSet];
    [indexSet addIndex:2];
    var trace = stack[0];

    [self assert:indexSet equals:trace.receiver];
    [self assert:@selector(addIndex:) equals:trace.selector];
    [self assert:2 equals:trace.args[0]];
    [self assert:1 equals:trace.count];
    [self assert:0 equals:trace.level];
    
    [indexSet addIndex:5];
    trace = stack[1];

    [self assert:5 equals:trace.args[0]];
    [self assert:2 equals:trace.count];
}

- (void)testTraceInstanceMethodImplementedInSuperClass
{
    [self clear];
    CPTrace("TestSubclass", "implementedInSuperClass", output);
    [[TestSubclass new] implementedInSuperClass];
    var trace = stack[0];

    [self assert:[TestSubclass class] equals:[trace.receiver class]];
    [self assert:@selector(implementedInSuperClass) equals:trace.selector];    
}

- (void)testTraceClassMethod
{
    [self clear];
    CPTrace("CPIndexSet", "+indexSet", output);
    var indexSet = [CPIndexSet indexSet];
    
    var trace = stack[0];
    [self assert:[CPIndexSet class] equals:trace.receiver];
    [self assert:@selector(indexSet) equals:trace.selector];
}

- (void)testTraceClassMethodImplementedInSuperClass
{
    [self clear];
    CPTrace("TestSubclass", "+implementedInSuperClass", output);
    [TestSubclass implementedInSuperClass];
    var trace = stack[0];

    [self assert:[TestSubclass class] equals:trace.receiver];
    [self assert:@selector(implementedInSuperClass) equals:trace.selector];    
}

- (void)testTraceInstanceMethodSubclassed
{
    [self clear];
    CPTrace("TestSubclass", "subclassed", output);
    [[TestSubclass new] subclassed];
    var trace = stack[0];

    [self assert:[TestSubclass class] equals:[trace.receiver class]];
    [self assert:@selector(subclassed) equals:trace.selector];   
}

- (void)testTraceInstanceMethodImplementedInSuperclassAndTraceSuperclassImpl
{
    [self clear];
    CPTraceStop("TestSubclass", "implementedInSuperClass");
    CPTraceStop("Test", "implementedInSuperClass");

    CPTrace("Test", "implementedInSuperClass", output);
    CPTrace("TestSubclass", "implementedInSuperClass", output);
    [[Test new] implementedInSuperClass];
    [[TestSubclass new] implementedInSuperClass];
    
    [self assert:1 equals:stack.length];

    [self clear];
    
    CPTraceStop("TestSubclass", "implementedInSuperClass");
    CPTraceStop("Test", "implementedInSuperClass");
    
    CPTrace("TestSubclass", "implementedInSuperClass", output);
    CPTrace("Test", "implementedInSuperClass", output);
    [[Test new] implementedInSuperClass];
    [[TestSubclass new] implementedInSuperClass];
    
    [self assert:1 equals:stack.length];
}

- (void)testInvalidArguments
{
    [self assertNoThrow:function()
    {
        CPTrace("UnknownClass", "UnknownSelector");
    }];
    
    [self assertThrows:function()
    {
        CPTrace("Test", "UnknownSelector");
    }];

    [self assertThrows:function()
    {
        CPTrace("(Test", "UnknownSelector");
    }];

    [self assertNoThrow:function()
    {
        CPTrace("Test.*", "UnknownSelector");
    }];

}

@end

@implementation Test : CPObject
{
}

+ (void)implementedInSuperClass
{
}

- (void)implementedInSuperClass
{
}

- (void)subclassed
{
}

@end

@implementation TestSubclass : Test
{
}

- (void)subclassed
{
}

@end

var output = function(a,b,c,d,e,f,g)
{
    stack.push({receiver:a , selector:b, args:c, count:f, level:g});
}