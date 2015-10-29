# sizefmt

A small library to format file sizes.

### Synopsis

```d
unittest
{
    assert("%s".format(Size(0)) == "0 B");
    assert("%s".format(Size(1)) == "1 B");
    assert("%s".format(Size(42)) == "42 B");
    assert("%g".format(Size(1024)) == "1 KB");
    assert("%.2f".format(Size(2_590_000)) == "2.47 MB");
}
```

You can control the formatting by creating a new type with different options:
```d
unittest
{
    enum Config config = {
        symbol: "O",
        unitName: "octet",
        unitNamePlural: "octets",
        prefixUse: PrefixUse.IEC,
        useNameIfNoPrefix: true
    };

	alias MySize = SizeBase!config;
    
    assert("%4.1f".format(MySize(0))         == "   0 octet");
    assert("%4.1f".format(MySize(1))         == "   1 octet");
    assert("%4.1f".format(MySize(42))        == "  42 octets");
    assert("%4.1f".format(MySize(1024))      == " 1.0 KiO");
    assert("%4.1f".format(MySize(2_590_000)) == " 2.5 MiO");
}
```

---
License: BSL 1.0

Copyright 2014-2015, Nicolas Sicard
