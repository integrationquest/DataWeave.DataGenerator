
%dw 2.0
output application/json

import * from dw::core::Arrays
import * from Generation

// var previous = generateCustomers(1000, 8)
// var previous = readUrl("file:///Users/rhoegg/tmp/customers-5k.json")
// var previous = readUrl("classpath://customers-5k.json")
// var inviters = (previous groupBy $.referred)
//     mapObject (people, referredCode) -> {
//         (referredCode): sizeOf(people)
//     }
---
// usCities[0]
// sizeOf(generateCustomers(5000, 400))
sizeOf(customers(300, "TEST"))
// inviters
//sizeOf(readUrl("classpath://customers-5k.json"))
// wow WAY slower than DW CLI