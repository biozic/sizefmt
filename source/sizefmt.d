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
version (unittest) import std.string;
debug import std.stdio;
    
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

/++
Helper struct used to wrap size values of type $(D ulong) and format them as
text.
+/
struct Size
{
    /++
    Configuration struct.
    +/
    struct Config
    {
        /// The name of the size unit (singular).
        string unitName = "byte"; 
        
        /// The name of the size unit (plural).
        string unitNamePlural = "bytes"; 
        
        /// The symbol of the size unit.
        string symbol = "B";
        
        /// The type of prefix used along with the symbol.
        PrefixUse prefixUse = PrefixUse.binary; 
        
        /// Whether to use the name of the symbol if there is no prefix.
        bool useNameIfNoPrefix = false; 
        
        /// The spacing between the value and the unit.
        Spacing spacing = Spacing.singleSpace; 

        static private Config[] configs;

        /// Push the current config on an internal stack.
        void push()
        {
            configs ~= config;
            config = Config();
        }

        /// Pop the config from the internal stack, if present.
        void pop()
        {
            if (!configs.length)
                return;

            config = configs[$-1];
            configs = configs[0 .. $-1];
        }

        @property size_t maxUnitLength()
        {
            import std.algorithm : max;
            return max(
                useNameIfNoPrefix ? max(unitName.length, unitNamePlural.length) : 0,
                1 + (prefixUse == PrefixUse.IEC ? 1 : 0) + symbol.length
            );
        }
        unittest
        {
            Size.config.push();
            scope(exit) Size.config.pop();

            assert(Size.config.maxUnitLength == 2);

            Size.config.prefixUse = PrefixUse.IEC;
            assert(Size.config.maxUnitLength == 3);
        }
    }
    ///
    unittest
    {
        Size.config.push();
        scope(exit) Size.config.pop();
        
        Size.config.symbol = "O";
        Size.config.unitName = "octet";
        Size.config.unitNamePlural = "octets";
        Size.config.prefixUse = PrefixUse.decimal;
        Size.config.useNameIfNoPrefix = true;

        assert("%s".format(Size(1)) == "1 octet");
        assert("%s".format(Size(42)) == "42 octets");
        assert("%s".format(Size(1000)) == "1.00 kO");
        assert("%.2f".format(Size(2_590_000)) == "2.59 MO");
    }
    ///
    unittest
    {
        Size.config.push();
        scope(exit) Size.config.pop();

        Size.config.spacing = Spacing.tabular;
        assert("|%4.1f|".format(Size(42)) ==        "|  42 B |");
        assert("|%4.1f|".format(Size(2_590_000)) == "| 2.5 MB|");

        Size.config.prefixUse = PrefixUse.IEC;
        assert("|%4.1f|".format(Size(42)) ==        "|  42 B  |");
        assert("|%4.1f|".format(Size(2_590_000)) == "| 2.5 MiB|");
    }

    /// The current configuration.
    static Config config;

    /// The size that should be formatted.
    ulong size;

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
        }

        // List of prefixes (the first _ is for no prefix,
        // the second _ if for kilo, which is special cased.
        static immutable string PrefixList = "__MGTPEZY";

        double base = (config.prefixUse == PrefixUse.decimal) ? 1000 : 1024;
        int order = 0;

        double tmp = size;
        while (tmp > (base - 1))
        {
            order++;
            tmp /= base;
        }
        order = min(order, PrefixList.length);

        // Output the numeric value
        if (order > 0)
            sink.formatValue(size / base^^order, fmt);
        else
            sink.formattedWrite("%*d", fmt.width, size);

        static app = appender!(char[]);

        // Output the spacing sequence
        if (config.spacing != Spacing.none)
            app.put(" ");

        // Output the prefix
        if (order > 0)
        {
            if (order == 1)
                app.put(config.prefixUse == PrefixUse.decimal ? "k" : "K");
            else
                app.put(PrefixList[order .. order + 1]);

            if (config.prefixUse == PrefixUse.IEC)
                app.put("i");
        }

        // Output the symbol or the unit name
        if (config.useNameIfNoPrefix && order == 0)
            app.put(size == 1 ? config.unitName : config.unitNamePlural);
        else
            app.put(config.symbol);

        if (config.spacing == Spacing.tabular)
            sink.formattedWrite("%-*s", 1 + config.maxUnitLength, app.data);
        else
            sink(app.data);

        app.clear();
    }
}
///
unittest
{
    assert("%s".format(Size(1)) == "1 B");
    assert("%s".format(Size(42)) == "42 B");
    assert("%s".format(Size(999)) == "999 B");
    assert("%s".format(Size(1000)) == "1000 B");
    assert("%s".format(Size(1023)) == "1023 B");
    assert("%g".format(Size(1024)) == "1 KB");
    assert("%.2f".format(Size(2590000)) == "2.47 MB");
}
