// Written in the D programming language
/++
This small library contains a helper struct template that allows to easily
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
    = 1.024 kilobyte = 1.024 KB.
    +/
    decimal
}

static SIPrefixes = cast(immutable) ["", "k", "M", "G", "T", "P", "E", "Z", "Y"];
static IECPrefixes = cast(immutable) ["", "Ki", "Mi", "Gi", "Ti", "Pi", "Ei", "Zi", "Yi"];

/++
Default size type (using binary prefixes).
+/
alias Size = SizeBase!(PrefixUse.binary, "B", " ");
///
unittest
{
    auto size = Size(500_000_000_000); // size in bytes
    assert("%s".format(size) == "465.661 GB");
    assert("%.1f".format(size) == "465.7 GB");
    assert("%.1f".format(size.iec) == "465.7 GiB");
    assert("%g".format(size.decimal) == "500 GB");
}

/++
Template for a helper struct used to wrap size values of type $(D ulong).
+/
struct SizeBase(PrefixUse prefix, string symbol, string space)
{
    ulong size; /// The size that should be formatted

    /++
    Formats the size according to the format fmt, automatically choosing the prefix
    and performing the unit conversion.

    The size is formatted as a floating point value, so fmt has to be a floating-point-value
    format specification (s, f, F, e, E, g, G, a or A).
    +/
    void toString(scope void delegate(const(char)[]) sink, FormatSpec!char fmt) const
    {
        import std.algorithm, std.exception;
        enforce("sfFeEgGaA".canFind(fmt.spec), new FormatException(
            "Invalid floating point format specification: " ~ fmt.spec));

        static if (prefix == PrefixUse.decimal)
            double base = 1000;
        else
            double base = 1024;

        static if (prefix == PrefixUse.IEC)
            auto prefixes = IECPrefixes;
        else
            auto prefixes = SIPrefixes;

        int order = 0;
        double tmp = size;
        while (tmp > (base - 1))
        {
            order++;
            tmp = tmp / base;
        }
        order = min(order, prefixes.length);

        sink.formatValue(size / base^^order, fmt);
        sink(space);
        sink(prefixes[order]);
        sink(symbol);
    }

    /// Returns the size formatted with the "%s" specification.
    string toString() const
    {
        import std.array;
        auto app = appender!string();
        this.toString(s => app.put(s), FormatSpec!char("%s"));
        return app.data;
    }

    /++
    Returns a copy of this size that will be formatted using  
    traditional _binary prefixes.
    +/
    auto binary() const
    {
        return SizeBase!(PrefixUse.binary, symbol, space)(size);
    }

    /++
    Returns a copy of this size that will be formatted using 
    the IEC prefixes.
    +/
    auto iec() const
    {
        return SizeBase!(PrefixUse.IEC, symbol, space)(size);
    }

    /++
    Returns a copy of this size that will be formatted using 
    _decimal prefixes.
    +/
    auto decimal() const
    {
        return SizeBase!(PrefixUse.decimal, symbol, space)(size);
    }
}

unittest
{
    assert("%s".format(Size(1)) == "1 B");
    assert("%s".format(Size(42)) == "42 B");
    assert("%s".format(Size(999)) == "999 B");
    assert("%s".format(Size(1000)) == "1000 B");
    assert("%s".format(Size(1023)) == "1023 B");
    assert("%g".format(Size(1024)) == "1 kB");
    assert("%.2f".format(Size(2590000)) == "2.47 MB");
}

unittest
{
    assert("%s".format(Size(1).iec) == "1 B");
    assert("%s".format(Size(42).iec) == "42 B");
    assert("%s".format(Size(999).iec) == "999 B");
    assert("%s".format(Size(1000).iec) == "1000 B");
    assert("%s".format(Size(1023).iec) == "1023 B");
    assert("%g".format(Size(1024).iec) == "1 KiB");
    assert("%.2f".format(Size(2590000).iec) == "2.47 MiB");
}

unittest
{
    assert("%s".format(Size(1).decimal) == "1 B");
    assert("%s".format(Size(42).decimal) == "42 B");
    assert("%s".format(Size(999).decimal) == "999 B");
    assert("%s".format(Size(1000).decimal) == "1 kB");
    assert("%s".format(Size(1023).decimal) == "1.023 kB");
    assert("%g".format(Size(1024).decimal) == "1.024 kB");
    assert("%.2f".format(Size(2590000).decimal) == "2.59 MB");
}
