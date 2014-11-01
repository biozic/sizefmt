// Written in the D programming language
/++
This small library allows to easily format file sizes in a human-readable
format.

Copyright: Copyright 2014, Nicolas Sicard
Authors: Nicolas Sicard
License: $(LINK www.boost.org/LICENSE_1_0.txt, Boost License 1.0)
Source: $(LINK https://github.com/biozic/sizefmt)
+/
module sizefmt;

import std.format;
import std.traits;
version (unittest) import std.string;
//debug import std.stdio;

/++
Wraps a size value of type $(D ulong) which is formatted appropriately
when output as text.
+/
struct SizeBase(Config config)
{
    /// The size that should be formatted.
    ulong value;
    
    /++
    Formats the size according to the format fmt, automatically choosing the
    prefix and performing the unit conversion.

    The size is formatted as a floating point value, so fmt has to be a
    floating-point-value format specification (s, f, F, e, E, g, G, a or A).
    But when the unit is just bytes, it is formatted as an integer.
    +/
    void toString(scope void delegate(const(char)[]) sink, FormatSpec!char fmt) const
    {
        import std.algorithm, std.array;
        
        // Override defaults for 's' spec.
        if (fmt.spec == 's')
        {
            fmt.spec = 'f';
            fmt.precision = 2;
            if (config.spacing == Spacing.tabular)
                fmt.width = max(7, fmt.precision);
        }
        
        // List of prefixes (the first _ is for no prefix,
        // the second _ if for kilo, which is special cased.
        static immutable string PrefixList = "__MGTPEZY";
        
        static if (config.prefixUse == PrefixUse.decimal)
            double base = 1000;
        else
            double base = 1024;
        
        int order = 0;
        double tmp = value;
        while (tmp > (base - 1))
        {
            order++;
            tmp /= base;
        }
        order = min(order, PrefixList.length);
        
        // Output the numeric value
        if (order > 0)
            sink.formatValue(value / base^^order, fmt);
        else
            sink.formattedWrite("%*d", fmt.width, value);
        
        // Prepare the unit part
        static app = appender!(char[]);
        
        static if (config.spacing != Spacing.none)
            app.put(" ");
        
        if (order > 0)
        {
            if (order == 1)
                app.put(config.prefixUse == PrefixUse.decimal ? "k" : "K");
            else
                app.put(PrefixList[order .. order + 1]);
            
            static if (config.prefixUse == PrefixUse.IEC)
                app.put("i");
        }
        
        static if (config.useNameIfNoPrefix)
        {
            if (order == 0)
                app.put(value == 1 ? config.unitName : config.unitNamePlural);
            else
                app.put(config.symbol);
        }
        else
            app.put(config.symbol);
        
        // Output the unit part
        static if (config.spacing == Spacing.tabular)
            sink.formattedWrite("%-*s", 1 + config.maxUnitLength, app.data);
        else
            sink(app.data);
        
        app.clear();
    }
}

/// Size struct with default options.
alias Size = SizeBase!(Config.init);
///
unittest
{
    assert("%s".format(Size(1)) == "1 B");
    assert("%s".format(Size(42)) == "42 B");
    assert("%g".format(Size(1024)) == "1 KB");
    assert("%.2f".format(Size(2_590_000)) == "2.47 MB");
}

static assert(__traits(isPOD, Size));

/++
Configuration of size format.
+/
struct Config
{
    /// The symbol of the size unit.
    string symbol = "B";
    
    /// The name of the size unit (singular).
    string unitName = "byte"; 
    
    /// The name of the size unit (plural).
    string unitNamePlural = "bytes"; 
    
    /// The type of prefix used along with the symbol.
    PrefixUse prefixUse = PrefixUse.binary; 
    
    /// The spacing between the value and the unit.
    Spacing spacing = Spacing.singleSpace; 
    
    /// Whether to use the name of the symbol if there is no prefix.
    bool useNameIfNoPrefix = false; 

    private size_t maxUnitLength()
    {
        import std.algorithm : max;
        return max(
            useNameIfNoPrefix ? max(unitName.length, unitNamePlural.length) : 0,
            1 + (prefixUse == PrefixUse.IEC ? 1 : 0) + symbol.length
        );
    }
}
///
unittest
{
    enum Config config = {
        symbol: "O",
        unitName: "octet",
        unitNamePlural: "octets",
        prefixUse: PrefixUse.IEC,
        spacing: Spacing.tabular,
        useNameIfNoPrefix: true
    };

	alias MySize = SizeBase!config;
    
    assert("|%4.1f|".format(MySize(1))         == "|   1 octet |");
    assert("|%4.1f|".format(MySize(42))        == "|  42 octets|");
    assert("|%4.1f|".format(MySize(1024))      == "| 1.0 KiO   |");
    assert("|%4.1f|".format(MySize(2_590_000)) == "| 2.5 MiO   |");
}

/++
The use of prefix when formatting long size values.
+/
enum PrefixUse
{
    /++
    Sizes will be formatted using the traditional _binary prefixes, e.g. 1024
    bytes = 1 kilobyte = 1 KB.
    +/
    binary,
    
    /++
    Sizes will be formatted using the _IEC recommandations for binary prefixes
    equivalent of a multiple of 1024, e.g. 1024 bytes = kibibyte = 1 KiB.
    +/
    IEC,
    
    /++
    Sizes will be formatted using _decimal prefixes, e.g. 1024 bytes = 1.024
    kilobyte = 1.024 kB.
    +/
    decimal
}

/++
The type of spacing around the symbol of the size unit.
+/
enum Spacing
{
    /++
    No space between the value and the unit.
    +/
    none,
    
    /++
    A single space between the value and the unit.
    +/
    singleSpace,
    
    /++
    The right amount of space so that sizes can be vertically aligned in a
    table. In order to achieve this vertical alignement, the value itself must
    be formatted as a fixed-size string.
    +/
    tabular
}
