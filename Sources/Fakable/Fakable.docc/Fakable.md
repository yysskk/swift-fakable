# ``Fakable``

Generate `fake()` test fixtures for your structs and enums.

## Overview

`Fakable` provides a single macro, ``Fakable()``, that adds a `fake()` factory
method to the type it is attached to. Every parameter has a default derived from
its type, so a test names only the values it actually cares about:

```swift
import Fakable

@Fakable
struct Item {
    let itemId: String
    let name: String?
    let price: Int
}

let item = Item.fake(itemId: "item-1", price: 500)
// name defaults to nil, and the other values to "" and 0
```

The generated method is wrapped in `#if DEBUG`, so it never reaches a release
build.

## Topics

### Essentials

- <doc:GettingStarted>
- ``Fakable()``

### Going further

- <doc:AdvancedUsage>
