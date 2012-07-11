/*
 * AppController.j
 * TraceApp
 *
 * Created by You on July 7, 2012.
 * Copyright 2012, Your Company All rights reserved.
 */

@import <Foundation/CPObject.j>
@import "../../CPTrace.j"

@implementation AppController : CPObject
{
    @outlet CPWindow    theWindow; //this "outlet" is connected automatically by the Cib
    @outlet CPComboBox classesCombo;
    @outlet CPComboBox methodsCombo;
    
    CPArray classList @accessors;
    CPArray methodsList @accessors;
}

- (void)applicationDidFinishLaunching:(CPNotification)aNotification
{
    // This is called when the application is done loading.
}

- (void)awakeFromCib
{
    // This is called when the cib is done loading.
    // You can implement this method on any object instantiated from a Cib.
    // It's a useful hook for setting up current UI values, and other things.

    // In this case, we want the window from Cib to become our full browser window
    methodsList = [];
    
    [classesCombo setForceSelection:YES];
    [classesCombo setTarget:self];
    [classesCombo setAction:@selector(didChooseClass:)];
    [methodsCombo setForceSelection:YES];
    [methodsCombo setEnabled:NO];

    var center = [CPNotificationCenter defaultCenter];
    [center addObserver:self selector:@selector(willDismiss:) name:CPComboBoxWillDismissNotification object:classesCombo];
    
    [theWindow setFullPlatformWindow:YES];
    
    var classes = [];
    var n = objj_getClassList(classes, 400);
    classes.sort(function(a,b){return (a.name > b.name) ? 1 : -1;});
    [self setClassList:classes];
}

- (void)willDismiss:(CPNotification)note
{
    [self didChooseClass:[note object]];
}

- (void)didChooseClass:(id)sender
{
    var clsname = [sender objectValue],
        cls = CPClassFromString(clsname);
    
    if (cls)
    {
        var imethlist = class_copyMethodList(cls),
            cmethlist = class_copyMethodList(objj_getMetaClass(clsname));
              
        imethlist = imethlist.sort(MethodsSortCompare);
        imethlist = imethlist.map(function(m){return {method:m, classMethod:NO};});
        cmethlist = cmethlist.sort(MethodsSortCompare);
        cmethlist = cmethlist.map(function(m){return {method:m, classMethod:YES};});

        methodsList = cmethlist.concat(imethlist);

        [methodsCombo setObjectValue:nil];
        [methodsCombo reloadData];
        if ([methodsList count])
            [methodsCombo setEnabled:YES];
    }
}

- (id)comboBox:(CPComboBox)aComboBox objectValueForItemAtIndex:(CPInteger)index
{
    if (aComboBox === classesCombo)
        return class_getName(classList[index]);
    else
    {
        var methodRecord = methodsList[index],
            name = method_getName(methodRecord.method);

        if (methodRecord.classMethod)
            name = "+" + name;
            
        return name;
    }
}

- (id)comboBox:(CPComboBox)aComboBox completedString:(CPString)uncomplete
{
    if (aComboBox === classesCombo)
    {
        var index = [classList indexOfObjectPassingTest:ClassesCompletionTest context:uncomplete];
        return (index !== CPNotFound) ? class_getName(classList[index]) : nil; 
    }
    else
    {
        var index = [methodsList indexOfObjectPassingTest:MethodsCompletionTest context:uncomplete];
        return (index !== CPNotFound) ?  method_getName(methodsList[index].method) : nil; 
    }
}

- (CPInteger)numberOfItemsInComboBox:(CPComboBox)aComboBox
{
    if (aComboBox === classesCombo)
        return classList.length;
    else
        return methodsList.length;
}

- (IBAction)trace:(id)sender
{
    var selectedClass = [classesCombo objectValue],
        selectedSelector = [methodsCombo objectValue],
        enabled;
        
    if (selectedClass == nil || selectedSelector == nil)
        return;

    if ([sender state] == CPOnState)
    {
        CPTrace(selectedClass, selectedSelector);
        enabled = NO;
    }
    else
    {
        CPTraceStop(selectedClass, selectedSelector);
        enabled = YES;
    }
    
    [classesCombo setEnabled:enabled];
    [methodsCombo setEnabled:enabled];
}

@end

var gradient = [[CPGradient alloc] initWithColors:[[CPColor colorWithRed:199/255 green:207/255 blue:213/255 alpha:1], [CPColor colorWithRed:168/255 green:178/255 blue:186/255 alpha:1]]];

@implementation CustomView : CPView
{
}

- (void)drawRect:(CGRect)aRect
{
     [gradient drawInRect:aRect angle:90];
}

@end

var ClassesCompletionTest = function(object, index, context)
{
    return class_getName(object).toLowerCase().indexOf(context.toLowerCase()) === 0;
};

var MethodsCompletionTest = function(object, index, context)
{
    return method_getName(object.method).toLowerCase().indexOf(context.toLowerCase()) === 0;
};

var MethodsSortCompare = function(lhs, rhs)
{
    return (method_getName(lhs) > method_getName(rhs)) ? 1 : -1;
}
