// Written in the D programming language
/++
This small library allows to easily
format file sizes in a human-readable format.

Copyright: Copyright 2014, Nicolas Sicard
Authors: Nicolas Sicard
License: $(LINK www.boost.org/LICENSE_1_0.txt, Boost License 1.0)
Source: $(LINK https://github.com/biozic/sizefmt)
+/
module sizefmt;

import std.format;
version(unittest)
    import std.string;
    
/++
The use of prefix when formatting long size values.
+/
enum PrefixUse
{
    /++
    Sizes will be formatted using the traditional _binary prefixes, e.g. 1024 bytes
    = 1 kilobyte = 1 KB.
    +/
    binary,
    
    /++
    Sizes will be formatted using the _IEC recommandations for binary prefixes
    equivalent of a multiple of 1024, e.g. 1024 bytes = kibibyte = 1 KiB.
    +/
    IEC,
    
    /++
    Sizes will be formatted using _decimal prefixes, e.g. 1024 bytes
    = 1.024 kilobyte = 1.024 kB.
    +/
    decimal
}

/++
Helper struct used to wrap size values of type $(D ulong) and format them as text.
+/
struct Size
{
    /++
    Configuration struct.
    +/
    struct Config
    {
        string unitName = "byte"; /// The name of the size unit (singular).
        string unitNamePlural = "bytes"; /// The name of the size unit (plural).
        string symbol = "B"; /// The symbol of the size unit.
        PrefixUse prefixUse = PrefixUse.binary; /// The type of prefix used along with the symbol.
        bool useNameIfNoPrefix = false; /// Whether to use the name of the symbol if there is no prefix.
        string spacing = " "; /// The spacing between the value and the unit.

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
    }
    ///
    unittest
    {
        Size.config.push();
        
        Size.config.symbol = "O";
        Size.config.unitName = "octet";
        Size.config.unitNamePlural = "octets";
        Size.config.prefixUse = PrefixUse.decimal;
        Size.config.useNameIfNoPrefix = true;
        
        assert("%s".format(Size(1)) == "1 octet");
        assert("%s".format(Size(42)) == "42 octets");
        assert("%s".format(Size(1000)) == "1 kO", "%s".format(Size(1000)));
        assert("%.2f".format(Size(2590000)) == "2.59 MO");
        
        Size.config.pop();
        
        assert("%s".format(Size(1)) == "1 B");
        assert("%s".format(Size(42)) == "42 B");
        assert("%s".format(Size(1000)) == "1000 B");
        assert("%.2f".format(Size(2590000)) == "2.47 MB");
    }

    /// The current configuration.
    static Config config;

    /// The size that should be formatted.
    ulong size;

    /++
    Formats the size according to the format fmt, automatically choosing the prefix
    and performing the unit conversion.

    The size is formatted as a floating point value, so fmt has to be a floating-point-value
    format specification (s, f, F, e, E, g, G, a or A).
    +/
    void toString(scope void delegate(const(char)[]) sink, FormatSpec!char fmt) const
    {
        import std.algorithm;

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
        sink.formatValue(size / base^^order, fmt);

        // Output the spacing sequence
        sink(config.spacing);

        // Output the prefix
        if (order > 0)
        {
            if (order == 1)
            {
                if (config.prefixUse == PrefixUse.decimal)
                    sink("k");
                else
                    sink("K");
            }
            else
                sink(PrefixList[order .. order + 1]);

            if (config.prefixUse == PrefixUse.IEC)
                sink("i");
        }

        // Output the symbol or the unit name
        if (config.useNameIfNoPrefix && order == 0)
            sink(size == 1 ? config.unitName : config.unitNamePlural);
        else
            sink(config.symbol);
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

