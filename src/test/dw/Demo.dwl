
%dw 2.0
output application/json

import * from dw::core::Arrays
import * from dw::iq::Generation

// var previous = generateCustomers(1000, 8)
// var previous = readUrl("file:///Users/rhoegg/tmp/customers-5k.json")
// var previous = readUrl("classpath://customers-5k.json")
// var inviters = (previous groupBy $.referred)
//     mapObject (people, referredCode) -> {
//         (referredCode): sizeOf(people)
//     }
---
// sizeOf(readUrl("classpath://customers-5k.json"))
// wow WAY slower than DW CLI with -i in VS Code
generateCustomers(2)
// generateCustomers(400)

