module sizefmt;

import std.format;

enum Binary
{
    yes = true,
    no = false
}

struct SizeBase(Binary binary = Binary.no,
                string symbol = "B",
                string space = " ")
{
    ulong size;

    void toString(scope void delegate(const(char)[]) sink, FormatSpec!char fmt) const
    {
        import std.algorithm, std.exception;
        enforce("sfFeEgGaA".canFind(fmt.spec), new FormatException(
            "Invalid floating point format specification: " ~ fmt.spec));
          
        auto base = binary ? 1024.0 : 1000.0;
        static prefixes = binary
            ? ["", "Ki", "Mi", "Gi", "Ti", "Pi", "Ei", "Zi", "Yi"]
            : ["", "k", "M", "G", "T", "P", "E", "Z", "Y"];

        // TODO: Calculate the order. This or a log?
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

alias Size = SizeBase!();
alias BinSize = SizeBase!(Binary.yes);

version(unittest)
    import std.string;

unittest
{
    assert("%s".format(Size(1)) == "1 B");
    assert("%s".format(Size(42)) == "42 B");
    assert("%s".format(Size(999)) == "999 B");
    assert("%s".format(Size(1000)) == "1 kB");
    assert("%.1f".format(Size(862_558_172_533)) == "862.6 GB");
    assert("%.2f".format(Size(ulong.max)) == "18.45 EB");

    assert("%s".format(BinSize(1024)) == "1 KiB");
    assert("%.1f".format(BinSize(862_558_172_533)) == "803.3 GiB");
}

unittest
{
    alias MySize = SizeBase!(Binary.no, "o");
    assert("%s".format(MySize(42)) == "42 o");
    assert("%.1f".format(MySize(862_558_172_533)) == "862.6 Go");
}
