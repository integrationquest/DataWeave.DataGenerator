# DataWeave Library for mock data generation 

Provides realistic mock data with help from the [MuleSoft mock data generators](https://anypoint.mulesoft.com/exchange/68ef9520-24e9-4cf2-b2f5-620025690913/data-weave-mock-data-generators-library/minor/1.0/)

## Installation
This library is still pre-release, so you have to clone the repository and install using maven locally

# Generators

* Customer

## Customers

```dataweave
generateCustomers(2)
```

### Output
```json
[
  {
    "id": "953ac19a60d24a3690d4e01803af6c5a",
    "inviteCode": "UNHSQBDCMFQCUX4",
    "name": {
      "first": "Mitzie",
      "last": "Dovbyschuk"
    },
    "address": {
      "street": "4695 Springrose Ave",
      "city": "Charlotte",
      "state": "NC",
      "postalCode": "28253"
    },
    "contact": {
      "phone": "360-122-5029",
      "email": "Mitzie.Dovbyschuk@hotmail.com"
    },
    "signUp": "2024-04-04T15:44:04-05:00",
    "referred": "CALLCENTER"
  },
  {
    "id": "85c90722f8c34067af2a18103e6f53ec",
    "inviteCode": "4B6OFEDC4YER0ZO",
    "name": {
      "first": "Paola",
      "last": "Zandueta"
    },
    "address": {
      "street": "3503 Thoreau Dr",
      "city": "Atlanta",
      "state": "GA",
      "postalCode": "30325"
    },
    "contact": {
      "phone": "622-237-8599",
      "email": "Paola.Zandueta@airforceemail.com"
    },
    "signUp": "2024-04-05T14:11:42-05:00",
    "referred": "UNHSQBDCMFQCUX4"
  }
]
```