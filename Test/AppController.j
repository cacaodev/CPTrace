/*
 * AppController.j
 * TracerTest
 *
 * Created by cacaodev on June 18, 2012.
 * Copyright 2012, cacaodev All rights reserved.
 */

@import <Foundation/CPObject.j>
@import "../CPTrace.j"

@implementation AppController : CPObject
{
}

- (void)applicationDidFinishLaunching:(CPNotification)aNotification
{
    var displayFunction = function(receiver, selector, args, duration, total_duration, total_count, level)
    {
        document.write("This is a custom log. The receiver is " +  [receiver class] + " and the level is " + level + "<br/>");
    }
    
    CPTrace("Test", "test:times:", displayFunction);
    CPTrace("TestSubclass1", "test:times:", displayFunction);
    CPTrace("TestSubclass2", "test:times:");
    CPTrace("TestSubclass3", "test:times:");
    
    var sub3 = [TestSubclass3 new];
    [sub3 test:3 times:1000];


    var tester = [Test new];
    [tester test:3 times:4000];
    [tester test:4 times:4000];
    [tester test:5 times:4000];


    [tester test];
    [tester test:4 times:8000];
    [tester test];


    [tester test];
    
    [tester test:1 times:7000];
    [tester test];

    var tester1 = [TestSubclass1 new];
    [tester1 test:1 times:7000];
    
    var tester2 = [TestSubclass2 new];
    [tester2 test:1 times:7000];
    
    [tester test:21 times:4000];
}

@end

@implementation Test : CPObject
{
}

- (void)test:(id)angle times:(id)c
{
    while(c--)
        var cos = Math.cos(angle) + Math.sin(angle);
}

- (void)test
{
var c = 10000;
    while(c--)
        var cos = Math.cos(0) + Math.sin(0);
}

@end

@implementation TestSubclass1 : Test
{
}

- (void)test:(id)angle times:(id)c
{
    while(c--)
        var cos = Math.cos(angle) + Math.sin(angle);
    
    var sub2 = [TestSubclass2 new];
    [sub2 test:4 times:0];
    [sub2 test:5 times:0];
}

- (void)test
{
var c = 10000;
    while(c--)
        var cos = Math.cos(0) + Math.sin(0);
}

@end

@implementation TestSubclass2 : Test
{
}

- (void)test:(id)angle times:(id)c
{
    while(c--)
        var cos = Math.cos(angle) + Math.sin(angle);

    var sub3 = [TestSubclass3 new];
    [sub3 test:4 times:5000];
}

- (void)test
{
    [super test];
}

@end

@implementation TestSubclass3 : Test
{
}

- (void)test:(id)angle times:(id)c
{
    while(c--)
        var cos = Math.cos(angle) + Math.sin(angle);
}


@end
