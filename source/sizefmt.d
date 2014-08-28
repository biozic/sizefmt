module sizefmt;

import std.format;

enum Prefix
{
    binarySI,
    decimalSI,
    IEC
}

static SIPrefixes = cast(immutable) ["", "k", "M", "G", "T", "P", "E", "Z", "Y"];
static IECPrefixes = cast(immutable) ["", "Ki", "Mi", "Gi", "Ti", "Pi", "Ei", "Zi", "Yi"];

struct SizeBase(Prefix prefix, string symbol = "B", string space = " ")
{
    ulong size;

    void toString(scope void delegate(const(char)[]) sink, FormatSpec!char fmt) const
    {
        import std.algorithm, std.exception;
        enforce("sfFeEgGaA".canFind(fmt.spec), new FormatException(
            "Invalid floating point format specification: " ~ fmt.spec));

        static if (prefix == Prefix.decimalSI)
            double base = 1000;
        else
            double base = 1024;

        static if (prefix == Prefix.IEC)
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
}

alias Size = SizeBase!(Prefix.binarySI);
alias SizeSI = SizeBase!(Prefix.decimalSI);
alias SizeIEC = SizeBase!(Prefix.IEC);

version(unittest)
    import std.string;

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
    assert("%s".format(SizeSI(1)) == "1 B");
    assert("%s".format(SizeSI(42)) == "42 B");
    assert("%s".format(SizeSI(999)) == "999 B");
    assert("%s".format(SizeSI(1000)) == "1 kB");
    assert("%s".format(SizeSI(1023)) == "1.023 kB");
    assert("%g".format(SizeSI(1024)) == "1.024 kB");
    assert("%.2f".format(SizeSI(2590000)) == "2.59 MB");
}

unittest
{
    assert("%s".format(SizeIEC(1)) == "1 B");
    assert("%s".format(SizeIEC(42)) == "42 B");
    assert("%s".format(SizeIEC(999)) == "999 B");
    assert("%s".format(SizeIEC(1000)) == "1000 B");
    assert("%s".format(SizeIEC(1023)) == "1023 B");
    assert("%g".format(SizeIEC(1024)) == "1 KiB");
    assert("%.2f".format(SizeIEC(2590000)) == "2.47 MiB");
}
