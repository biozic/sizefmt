module sizefmt;

import std.format;

enum Binary
{
    yes = true,
    no = false
}

struct Config
{
    Binary binary = Binary.no;
    string bytesSymbol = "B";
    string byteWordSingular = "byte";
    string bytewordPlural = "bytes";
    string space = " ";
    string[] decimalPrefixes = ["k", "M", "G", "T", "P", "E", "Z", "Y"];
    string[] binaryPrefixes = ["Ki", "Mi", "Gi", "Ti", "Pi", "Ei", "Zi", "Yi"];
}

struct SizeBase(alias config)
{
    static assert(is(typeof(config) == Config));

    ulong size;

    void toString(scope void delegate(const(char)[]) sink, FormatSpec!char fmt) const
    {
        import std.algorithm, std.exception;
        enforce("sfFeEgGaA".canFind(fmt.spec), new FormatException(
            "Invalid floating point format specification: " ~ fmt.spec));
          
        auto base = config.binary ? 1024.0 : 1000.0;
        auto prefixes = config.binary ? config.binaryPrefixes : config.decimalPrefixes;
 
        int order = 0;
        double tmp = size;
        while (tmp > (base - 1))
        {
            order++;
            tmp = tmp / base;
        }
        order = min(order, prefixes.length);

        if (order == 0)
        {
            sink.formatValue(cast(double) size, fmt);
            sink(config.space);
            sink(size == 1 ? config.byteWordSingular : config.bytewordPlural);
        }
        else
        {
            sink.formatValue(size / base^^order, fmt);
            sink(config.space);
            sink(prefixes[order - 1]);
            sink(config.bytesSymbol);
        }
    }
}

alias Size = SizeBase!(Config(Binary.no));
alias BinSize = SizeBase!(Config(Binary.yes));

version(unittest)
    import std.string;

unittest
{
    assert("%s".format(Size(1)) == "1 byte");
    assert("%s".format(Size(42)) == "42 bytes");
    assert("%s".format(Size(999)) == "999 bytes");
    assert("%s".format(Size(1000)) == "1 kB");
    assert("%.1f".format(Size(862_558_172_533)) == "862.6 GB");
    assert("%.2f".format(Size(ulong.max)) == "18.45 EB");

    assert("%s".format(BinSize(1024)) == "1 KiB");
    assert("%.1f".format(BinSize(862_558_172_533)) == "803.3 GiB");
}

unittest
{
    enum Config config = {
        bytesSymbol:"o",
        byteWordSingular:"octet",
        bytewordPlural:"octets"
    };
    alias MySize = SizeBase!config;

    assert("%s".format(MySize(42)) == "42 octets");
    assert("%.1f".format(MySize(862_558_172_533)) == "862.6 Go");
}
